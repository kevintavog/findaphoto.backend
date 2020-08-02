import Foundation
import FPCore

import Async
import Guaka
import Vapor

let concurrentFlag = Flag(
    longName: "concurrent",
    type: Int.self,
    description: "The number of concurrent tasks",
    required: false)

let elasticSearchFlag = Flag(
    shortName: "e",
    longName: "elastic",
    type: String.self,
    description: "The URL for ElasticSearch.",
    required: true)

let indexOverrideFlag = Flag(
    shortName: "i",
    longName: "index",
    type: String.self,
    description: "The prefix for the indices (for development)",
    required: false)

let pathFlag = Flag(
    shortName: "p",
    longName: "path",
    type: String.self,
    description: "The path to scan for photos & videos",
    required: true)

let reindexFlag = Flag(
    longName: "reindex",
    value: false,
    description: "Do a full reindex, only generate thumbnails of new or changed items")

let reverseNameFlag = Flag(
    shortName: "r",
    longName: "reverse",
    type: String.self,
    description: "The URL for ReverseNameLookup.",
    required: true)

let timingsFlag = Flag(
    longName: "timings",
    value: false,
    description: "Show timings")



let flags = [concurrentFlag, elasticSearchFlag, indexOverrideFlag, pathFlag, reindexFlag, reverseNameFlag, timingsFlag]
let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let eventLoop = eventGroup.next()


let command = Command(usage: "FindAPhoto", flags: flags) { flags, args in
    ElasticSearchClient.ServerUrl = flags.getString(name: "elastic")!
    LookupNames.reverseNameLookupUrl = flags.getString(name: "reverse")!
    let path = flags.getString(name: "path")!
    let pathURL = URL(fileURLWithPath: path)
    let concurrent = flags.getInt(name: "concurrent") ?? 2
    let reindex = flags.getBool(name: "reindex") ?? false
    let showTimings = flags.getBool(name: "timings") ?? false
    if let indexPrefix = flags.getString(name: "index") {        
        ElasticSearchClient.setIndexPrefix(indexPrefix)
    }

    var outstandingRequests = 0
    let rwLock = RWLock()

    var totalSignatureDuration = 0.0
    var totalCheckDuration = 0.0
    var totalPrepareDuration = 0.0
    var totalLookupkDuration = 0.0


    do {
        StandardPaths.initFor(appName: "FPIndexer")

        PrepareMedia.configure(instances: concurrent)
        try ElasticSearchInit.run(eventLoop)
        try Aliases.initialize(eventLoop)
        let alias = try Aliases.addOrCreateFrom(path: path)

        print("Indexing \(path) (alias: \(alias)) with \(concurrent) tasks")
        print("ElasticSearch \(ElasticSearchClient.version); \(ElasticSearchClient.ServerUrl); "
            + "indexes: \(ElasticSearchClient.MediaIndexName), \(ElasticSearchClient.AliasIndexName)")
        if reindex {
            print(" -  NOTE: re-indexing all media")
        }

        try GenerateThumbnails.initialize()


        let semaphore = DispatchSemaphore(value: concurrent)

        Statistics.start()
        // Enumerate media directory (work with all files in a folder as a group)
        try EnumerateMedia.at(pathURL, alias, { (folder: URL, files: [FpFile]) in
            rwLock.write( { outstandingRequests += 1 })
            semaphore.wait()

            Async.background {
                let startTime = Date()
                var prepareMediaTime = startTime
                var lookupNamesTime = startTime

                Signature.calculate(files)
                let signatureTime = Date()
                CheckMediaExists.run(files)
                let checkMediaTime = Date()


                let newOrChanged = files.filter { $0.signatureMatches == false }
                let toIndex = reindex ? files : newOrChanged

                if toIndex.count > 0 {
                    var media = PrepareMedia.run(folder, toIndex)
                    prepareMediaTime = Date()

                    if media.count > 0 {
                        media = LookupNames.run(media)
                        lookupNamesTime = Date()

                        IndexMedia.run(media)
                        GenerateThumbnails.run(folder, media)
                    }

                    let relativePath = "\(pathURL.lastPathComponent)/\(folder.path.dropFirst(path.count))"
                    Statistics.completedFolder(relativePath)
                }

                let endTime = Date()
                let allDuration = Int(endTime.timeIntervalSince(startTime))
                let signatureDuration = signatureTime.timeIntervalSince(startTime)
                let checkDuration = checkMediaTime.timeIntervalSince(signatureTime)
                let prepareDuration = prepareMediaTime.timeIntervalSince(checkMediaTime)
                let lookupkDuration = lookupNamesTime.timeIntervalSince(prepareMediaTime)

                if showTimings && allDuration > 0 {
                    print(" >> item count: \(files.count); all: \(allDuration), sign: \(Int(signatureDuration)), "
                        + "check: \(Int(checkDuration)), prep: \(Int(prepareDuration)), "
                        + "look: \(Int(lookupkDuration))")
                }

                rwLock.write( { 
                    outstandingRequests -= 1
                    totalSignatureDuration += signatureDuration
                    totalCheckDuration += checkDuration
                    totalPrepareDuration += prepareDuration
                    totalLookupkDuration += lookupkDuration
                })
                semaphore.signal()
            }
        })

        var waitCount = 0
        repeat {
            rwLock.read( { waitCount = outstandingRequests })
            if waitCount > 0 {
                sleep(1)
            }
        } while waitCount > 0

        IndexMedia.finish()
        PrepareMedia.cleanup()


        print("signatures: \(Int(totalSignatureDuration)), "
            + "check existing: \(Int(totalCheckDuration)), prepare: \(Int(totalPrepareDuration)), "
            + "name lookup: \(Int(totalLookupkDuration))")
        Statistics.stop()
        emitFailures()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed: \(error)")
    }
}

command.execute()
