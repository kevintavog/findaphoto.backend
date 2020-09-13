import Foundation
import AsyncHTTPClient
import NIO
import FPCore

import SwiftyJSON

/*
Azure computer vision
    20 calls / minute
        1 call every 3 seconds
    5000 calls / month
*/


let azureCreateBody = """
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  }
}
"""

class AzureTagProvider: TagProvider {
    let elasticIndexName = "azure-tag-cache"
    let minConfidence = 0.80
    static let minSecondsBetweenCalls = 3.0    // 20 calls / minute

    static let baseUrl = "https://westus2.api.cognitive.microsoft.com"
    static let basePath = "vision/v3.0/analyze"
    static let params = "visualFeatures=Categories,Tags,Description&details=Landmarks"

    var noMoreRequests = false
    var lastRequestTime = Date().addingTimeInterval(-2 * AzureTagProvider.minSecondsBetweenCalls)

    var outputDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df
    }()
    let esIndexingClient = ElasticSearchIndexing(eventGroup.next())
    let nameClient = HTTPClient(eventLoopGroupProvider: .shared(eventGroup))

    var elasticField: String {
        get { return "azure_tags" }
    }

    func initialize() throws {
        if try !ElasticSearchInit.doesIndexExist(esIndexingClient.client, elasticIndexName) {
            try ElasticSearchInit.createIndex(esIndexingClient.client, elasticIndexName, azureCreateBody)
        }
    }

    func cachedTags(_ id: String) throws -> [String]? {
        if let json = try TagMedia.fromCache(elasticIndexName, id) {
            return tagsFromResponse(json)
        }
        return nil
    }

    func tagFile(_ id: String, _ fileData: Data) throws -> [String] {
        // Buzz off if we've exceeded our quota for the month
        if noMoreRequests {
            throw TagError.exceededRequests
        }

        // Ensure at least `secondsBetweenCalls` since last call
        let timeSinceLast = -1 * lastRequestTime.timeIntervalSinceNow
        if timeSinceLast < AzureTagProvider.minSecondsBetweenCalls {
            let waitTime = AzureTagProvider.minSecondsBetweenCalls - timeSinceLast
            usleep(UInt32(waitTime * 1000000))
        }

print("azure \(Date()): \(id)")
        lastRequestTime = Date()

        let promise = eventLoop.makePromise(of: JSON.self)
        var request = try HTTPClient.Request(
            url: "\(AzureTagProvider.baseUrl)/\(AzureTagProvider.basePath)?\(AzureTagProvider.params)", method: .POST)
        request.headers.add(name: "Content-Type", value: "application/octet-stream")
        request.headers.add(name: "Ocp-Apim-Subscription-Key", value: FpConfiguration.instance.azureSubscriptionKey)
        request.body = .data(fileData)
        nameClient.execute(request: request).whenComplete { result in
            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    var responseData = Data()
                    if var buffer = response.body {
                        if let bytes = buffer.readBytes(length: buffer.readableBytes) {
                            responseData = Data(bytes)
                        }
                    }

                    if response.status == .ok {
                        do {
                            let json = try JSON(data: responseData)
                            promise.succeed(json)
                        } catch {
                            promise.fail(error)
                        }
                    } else {
                        if response.status == .tooManyRequests || response.status == .paymentRequired {
                            self.noMoreRequests = true
                            promise.fail(TagError.exceededRequests)
                        } else {
                            let bodyText = String(data: responseData, encoding: .utf8) ?? ""
                            promise.fail(RangicError.http(response.status, bodyText))
                        }
                    }
                    break
            }
        }

        let json = try promise.futureResult.wait()
        try saveToCache(id, json)
        return tagsFromResponse(json)
    }

    func tagsFromResponse(_ json: JSON) -> [String] {
      return json["tags"].arrayValue
          .filter { $0["confidence"].doubleValue > minConfidence }
          .map { $0["name"].stringValue }
    }

    func saveToCache(_ id: String, _ json: JSON) throws {
        var jsonUpdated = json
        jsonUpdated["date_retrieved"].string = outputDateFormatter.string(from: Date())
        do {
            let body = try jsonUpdated.rawData()
            try esIndexingClient.index(elasticIndexName, id, body)
        } catch {
            logger.error("saveToCache failed: \(error)")
        }
    }
}
