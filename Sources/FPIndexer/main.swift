import Foundation
import FPCore
import Logging

import Async
import Guaka
import LoggingFormatAndPipe
import Vapor

let aliasOverrideFlag = Flag(
    shortName: "a",
    longName: "alias",
    type: String.self,
    description: "The path to use for the alias.",
    required: false)

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
    required: false)

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
    required: false)

let reindexFlag = Flag(
    longName: "reindex",
    value: false,
    description: "Do a full reindex, only generate thumbnails of new or changed items")

let timingsFlag = Flag(
    longName: "timings",
    value: false,
    description: "Show timings")



let flags = [aliasOverrideFlag, concurrentFlag, elasticSearchFlag, indexOverrideFlag, pathFlag, reindexFlag, timingsFlag]
let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let eventLoop = eventGroup.next()

let timestampFormatter = DateFormatter()
timestampFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
let logger = Logger(label: "FpIndexer") { _ in 
	return LoggingFormatAndPipe.Handler(
		formatter: BasicFormatter([.timestamp, .level, .metadata, .message], timestampFormatter: timestampFormatter),
		pipe: LoggerTextOutputStreamPipe.standardOutput
	)
}


let command = Command(usage: "FindAPhoto", flags: flags) { flags, args in
    StandardPaths.initFor(appName: "FPIndexer")

    ElasticSearchClient.ServerUrl = FpConfiguration.instance.elasticSearchUrl
    if let elasticUrl = flags.getString(name: "elastic") {
        print("Overriding elastic URL to: \(elasticUrl)")
        ElasticSearchClient.ServerUrl = elasticUrl
    }
    if let aliasOverride = flags.getString(name: "alias") {
        Aliases.aliasOverride = aliasOverride
    }

    LookupNames.reverseNameLookupUrl = FpConfiguration.instance.reverseNameUrl
    var path = FpConfiguration.instance.indexPath
    if let pathOverride = flags.getString(name: "path") {
        print("Overriding path to: \(pathOverride)")
        path = pathOverride
    }
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
        PrepareMedia.configure(instances: concurrent)
        try ElasticSearchInit.run(eventLoop)
        try Aliases.initialize(eventLoop)
        try TagMedia.initialize()
        let alias = try Aliases.addOrCreateFrom(path: path)

        logger.info("Indexing \(path) (alias: \(alias)) with \(concurrent) tasks")
        logger.info(Logger.Message( stringLiteral: "ElasticSearch \(ElasticSearchClient.version); "
            + "\(ElasticSearchClient.ServerUrl); "
            + "indexes: \(ElasticSearchClient.MediaIndexName), \(ElasticSearchClient.AliasIndexName)"))
        if reindex {
            logger.info(" -  NOTE: re-indexing all media")
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

                // Tags require the item to be in the index; they have a better chance of being there
                // at this point.
                // Add tags to items that are in ElasticSearch & aren't going to be re-indexed, but
                // are missing tags
                TagMedia.enqueue(files.filter { $0.signatureMatches && !($0.azureTagsExist || $0.azureTagsExist) })

                let endTime = Date()
                let allDuration = Int(endTime.timeIntervalSince(startTime))
                let signatureDuration = signatureTime.timeIntervalSince(startTime)
                let checkDuration = checkMediaTime.timeIntervalSince(signatureTime)
                let prepareDuration = prepareMediaTime > checkMediaTime ? prepareMediaTime.timeIntervalSince(checkMediaTime) : 0.0
                let lookupkDuration = lookupNamesTime > prepareMediaTime ? lookupNamesTime.timeIntervalSince(prepareMediaTime) : 0.0

                if showTimings && allDuration > 0 {
                    logger.info(Logger.Message(stringLiteral:" >> item count: \(files.count); "
                        + "all: \(allDuration), sign: \(Int(signatureDuration)), "
                        + "check: \(Int(checkDuration)), prep: \(Int(prepareDuration)), "
                        + "look: \(Int(lookupkDuration))"))
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
        TagMedia.finish()


        logger.info(Logger.Message( stringLiteral: "times: signatures: \(Int(totalSignatureDuration)), "
            + "check existing: \(Int(totalCheckDuration)), prepare: \(Int(totalPrepareDuration)), "
            + "name lookup: \(Int(totalLookupkDuration))"))
        Statistics.stop()
        emitFailures()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed: \(error)")
    }
}

command.execute()
