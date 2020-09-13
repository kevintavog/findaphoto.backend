import Foundation
import NIO
import NIOHTTP1
import FPCore

import Async
import ElasticSwift
import SwiftyJSON

enum TagError: Error {
    case exceededRequests
}

struct TagFileInfo {
    let id: String
    let fullPath: URL
    let azureTagsExist: Bool
    let clarifaiTagsExist: Bool

    init(_ id: String, _ fullPath: URL, _ azureTagsExist: Bool, _ clarifaiTagsExist: Bool) {
        self.id = id
        self.fullPath = fullPath
        self.azureTagsExist = azureTagsExist
        self.clarifaiTagsExist = clarifaiTagsExist
    }
}

protocol TagProvider {
    var elasticField: String { get }
    func cachedTags(_ id: String) throws -> [String]?
    func tagFile(_ id: String, _ fileData: Data) throws -> [String]
}

class TagMedia {
    static var rwLock = RWLock()
    static var pending: [TagFileInfo] = []
    static var activelyTagging = false
    static var azureProvider = AzureTagProvider()
    static var clarifaiProvider = ClarifaiTagProvider()
    static let esClient = ElasticSearchClient(eventGroup.next())
    static let esIndexClient = ElasticSearchIndexing(eventGroup.next())
    static let maxImageHeight = 1436
    static let maxFileSizeBytes: UInt64 = 3 * 1024 * 1024


    static func initialize() throws {
        try azureProvider.initialize()
        try clarifaiProvider.initialize()
        Async.background { dequeue() }
    }

    static func enqueue(_ items: [FpFile]) {
        if items.isEmpty {
            return
        }

        Statistics.add(missingTags: items.count)
        rwLock.write({
            pending.append(contentsOf: items.map { TagFileInfo($0.path, $0.url, $0.azureTagsExist, $0.clarifaiTagsExist) })
        })
    }

    static func enqueue(_ items: [FpMedia]) {
        if items.isEmpty {
            return
        }

        Statistics.add(missingTags: items.count)
        rwLock.write({
            do {
                try pending.append(contentsOf: items.map {
                    // Update tags when the file has changed
                    try TagFileInfo($0.path, URL(fileURLWithPath: PathUtils.toFullPath($0.path)), true, true)})
            } catch {
                logger.error("Failed enqueuing media items: \(error)")
            }
        })
    }

    static func finish() {
        var countLeft = 0
        var active = false
        repeat {
            rwLock.read({
                countLeft = pending.count
                active = activelyTagging
            })
            usleep(100 * 1000)
        } while countLeft > 0 || active
    }

    static func dequeue() {
        repeat {
            var possibleItem: TagFileInfo? = nil
            rwLock.write({
                if pending.count > 0 {
                    possibleItem = pending.removeFirst()
                }
            })
            if let item = possibleItem {
                rwLock.write({ activelyTagging = true })
                do {
                    try processItem(item)
                } catch TagError.exceededRequests {
logger.warning("Exceeded requests on \(item.id)")
                } catch {
                    IndexingFailures.append("Failed tagging \(item.id): \(error)")
                }
                rwLock.write({ activelyTagging = false })
            } else {
                usleep(100 * 1000)
            }
        } while true
    }

    static func processItem(_ item: TagFileInfo) throws {
        var azureTags: [String]? = nil
        var clarifaiTags: [String]? = nil
        do {
            azureTags = try getTags(azureProvider, item)
        } catch {
            logger.warning("AzureTagProvider failed: \(error)")
        }

        do {
            clarifaiTags = try getTags(clarifaiProvider, item)
        } catch {
            logger.warning("ClarifaiTagProvider failed: \(error)")
        }

        updateIndex(item, azureTags, clarifaiTags)
    }

    static func getTags(_ provider: TagProvider, _ item: TagFileInfo) throws -> [String]? {
        if let cachedTags = try? provider.cachedTags(item.id) {
            Statistics.add(cachedTags: 1)
            return cachedTags
        }

        // Generate smaller version of image and also strip out metadata
        let tagFile = NSTemporaryDirectory() + "fp-tag-" + UUID().uuidString + ".jpg"
        var imageHeight = maxImageHeight
        let isVideo = item.fullPath.pathExtension.caseInsensitiveCompare("mp4") == .orderedSame
        if isVideo {
            let tempFile = NSTemporaryDirectory() + "fp-tag-temp-" + UUID().uuidString + ".jpg"
            defer {
                try? FileManagement.deleteFileIfPresent(tempFile)
            }
            try ImageSizing.sizeVideoFrame(item.fullPath.path, tempFile, tagFile, 1.1, imageHeight)
        } else {
            repeat {
                try ImageSizing.resizeSingleImage(item.fullPath.path, tagFile, imageHeight)
                imageHeight -= 512
            } while try fileSize(tagFile) > maxFileSizeBytes
        }

        defer {
            do {
                try FileManagement.deleteFileIfPresent(tagFile)
            } catch {
                logger.warning("Failed deleting tag file: \(tagFile)")
            }
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: tagFile))

        // For video, consider generating frames: no more than every N seconds, no more than M per video
            // Cleanup temp files at end
        let tags = try provider.tagFile(item.id, data)
        Statistics.add(providerTags: 1)
        return tags
    }

    static func updateIndex(_ item: TagFileInfo, _ azureTags: [String]?, _ clarifaiTags: [String]?) {
// print("Tags for \(item.id): \(String(describing:azureTags)); \(String(describing:clarifaiTags))")

        if azureTags == nil && clarifaiTags == nil {
            return
        }

        do {
            let promise = eventLoop.makePromise(of: FpMedia.self)
            let _ = try esClient.term("_id", item.id, SearchOptions(first: 0, count: 1, logSearch: false))
                .map { fpResponse in
                    if fpResponse.total == 0 {
                        promise.fail(RangicError.notFound("No matching media found"))
                    } else {
                        promise.succeed(fpResponse.hits[0].media)
                    }
                }

            var media = try promise.futureResult.wait()

            if !item.azureTagsExist, let at = azureTags {
                media.azureTags = at
                media.tags = at
            }
            if !item.clarifaiTagsExist, let cf = clarifaiTags {
                media.clarifaiTags = cf
            }
            let _ = try esIndexClient.index([media])
        } catch {
            logger.error("Failed updating \(item.id): \(error)")
        }
    }

    static func fileSize(_ filepath: String) throws -> UInt64 {
        let attrs = try FileManager.default.attributesOfItem(atPath: filepath)
        return attrs[.size] as! UInt64
    }

    static func fromCache(_ index: String, _ id: String) throws -> JSON? {
        let promise = eventLoop.makePromise(of: JSON?.self)

        let escapedId = id.replacingOccurrences(of: "\\", with: "\\\\")
        let query = 
"""
{
  "from": 0,
  "size": 1,
  "query": {
    "term": {
      "_id": {
        "value": "\(escapedId)"
      }
    }
  }
}
"""

        try esClient.client.execute(
            request: HTTPRequestBuilder()
                .set(method: .POST)
                .set(path: "\(index)/_search")
                .set(headers: ["Content-Type": "application/json; charset=utf-8"])
                .set(body: query.data(using: .utf8)!)
                .build(),
            completionHandler: { result in
                switch result {
                    case .failure(let error):
                        promise.fail(error)
                        break
                    case .success(let response):
                        var json: JSON? = nil
                        if response.status == .ok {
                            json = try? JSON(data: response.body!)
                            if json != nil {
                                promise.succeed(json)
                            }
                        }
                        if json == nil {
                            promise.fail(RangicError.http(response.status, String(data: response.body!, encoding: .utf8)!))
                        }
                        break
                }
        })

        if let json = try promise.futureResult.wait() {
            let total = json["hits"]["total"]["value"].intValue
            if total >= 1 {
                return json["hits"]["hits"][0]["_source"]
            }            
        }

        return nil
    }
}
