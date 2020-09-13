import Foundation
import AsyncHTTPClient
import NIO
import FPCore

import SwiftyJSON

/*
Clarifai computer vision
    10 calls / second
    1000 calls / month
*/


let clarifaiCreateBody = """
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  }
}
"""

struct ClarifaiImagePredictRequest: Codable {
	let inputs: [InputRequest]

    init(_ inputs: [InputRequest]) {
        self.inputs = inputs
    }

    struct InputRequest: Codable {
        let data: Data

        init(_ base64: String) {
            self.data = Data(Data.Image(base64))
        }

        struct Data: Codable {
            let image: Image

            init(_ image: Image) {
                self.image = image
            }

            struct Image: Codable {
                let base64: String
                init(_ base64: String) {
                    self.base64 = base64
                }
            }
        }
    }
}

class ClarifaiTagProvider: TagProvider {
    let elasticIndexName = "clarifai-tag-cache"
    let minConfidence = 0.80
    static let minSecondsBetweenCalls = 0.2    // 5 calls / second (lower than the max)

    static let baseUrl = "https://api.clarifai.com"
    static let basePath = "v2/models/aaa03c23b3724a16a56b629203edc62c/outputs"

    var noMoreRequests = false
    var lastRequestTime = Date().addingTimeInterval(-2 * ClarifaiTagProvider.minSecondsBetweenCalls)

    var outputDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df
    }()
    let esIndexingClient = ElasticSearchIndexing(eventGroup.next())
    let nameClient = HTTPClient(eventLoopGroupProvider: .shared(eventGroup))

    var elasticField: String {
        get { return "clarifai_tags" }
    }


    func initialize() throws {
        if try !ElasticSearchInit.doesIndexExist(esIndexingClient.client, elasticIndexName) {
            try ElasticSearchInit.createIndex(esIndexingClient.client, elasticIndexName, clarifaiCreateBody)
        }
    }

    // // A temporary method to match new ids to old ids (need to update ElasticSearch clarifia_cache with new ids)
    // func transformId(_ id: String) -> String {
    //     // "/mnt/mediafiles/2020/2020-04-19 Walk/IMG_8119.jpeg" --> "1\\2020\\IMG_8119.jpeg"
    //     // "/mnt/mediafiles/2020/2020-04-19 Walk/IMG_8119.jpeg" --> "1\\2020\\IMG_8119.jpeg"
    //     let tokens = id.split(separator: "/")
    //     let newId = "1/\(tokens[2])"
    // }

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
        if timeSinceLast < ClarifaiTagProvider.minSecondsBetweenCalls {
            let waitTime = ClarifaiTagProvider.minSecondsBetweenCalls - timeSinceLast
            usleep(UInt32(waitTime * 1000000))
        }

print("clarifai \(Date()): \(id)")
        lastRequestTime = Date()

        let promise = eventLoop.makePromise(of: JSON.self)
        var request = try HTTPClient.Request(
            url: "\(ClarifaiTagProvider.baseUrl)/\(ClarifaiTagProvider.basePath)", method: .POST)
        request.headers.add(name: "Content-Type", value: "application/octet-stream")
        request.headers.add(name: "Authorization", value: "Key " + FpConfiguration.instance.clarifaiApiKey)

        let predict = ClarifaiImagePredictRequest(
            [ClarifaiImagePredictRequest.InputRequest(fileData.base64EncodedString())])

        request.body = try .data(JSONEncoder().encode(predict))
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
      return json["outputs"][0]["data"]["concepts"].arrayValue
          .filter { $0["value"].doubleValue > minConfidence }
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
