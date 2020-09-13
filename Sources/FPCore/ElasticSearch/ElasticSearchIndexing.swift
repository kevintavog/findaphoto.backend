import Foundation
import NIO
import NIOHTTP1

import ElasticSwift
// import ElasticSwiftCore
// import ElasticSwiftNetworkingNIO


public class ElasticSearchIndexing {
    public let client: ElasticClient
    let eventLoop: EventLoop

    public init(_ eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        client = ElasticClient(settings: Settings(
            forHost: ElasticSearchClient.ServerUrl,
            adaptorConfig: AsyncHTTPClientAdaptorConfiguration.default,
            serializer: getFpMediaSerializer()))
    }

    // Returns the signatures of the given items
    public func signatures(_ items: [FpFile]) throws -> [String:ElasticSearchSignaturesResponse] {
        let multiItems = items.map { MultiGetRequest.Item(
            index: ElasticSearchClient.MediaIndexName,
            id: $0.path)}

        let request = MultiGetRequest(
            items: multiItems,
            source: "true",
            sourceIncludes: ["signature", "azureTags", "clarifaiTags"])
        let promise = eventLoop.makePromise(of: [String:ElasticSearchSignaturesResponse].self)
        func handler(_ result: Result<MultiGetResponse, Error>) {
            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    var pathToSignature = [String:ElasticSearchSignaturesResponse]()
                    for r in response.responses {
                        if r.response!.found {
                            let dict = r.response!.source!.value as! [String:Any]
                            var azureTags: [String]? = nil
                            var clarifaiTags: [String]? = nil
                            if dict.keys.contains("azureTags") {
                                azureTags = (dict["azureTags"] as? CodableValue)?.value as? [String]
                            }
                            if dict.keys.contains("clarifaiTags") {
                                clarifaiTags = (dict["clarifaiTags"] as? CodableValue)?.value as? [String]
                            }

                            // The `signature` type is CodableView if tags are present and
                            // Any/String otherwise. Yuck
                            var signature = ""
                            if dict.keys.contains("signature") {
                                if let cv = dict["signature"] as? CodableValue {
                                    signature = cv.value as! String
                                } else if let s = dict["signature"] as? String {
                                    signature = s
                                }
                            }
                            pathToSignature[r.response!.id] = ElasticSearchSignaturesResponse(
                                signature,
                                azureTags,
                                clarifaiTags)
                        }
                    }
                    promise.succeed(pathToSignature)
                    break
            }
        }

        client.mget(request, completionHandler: handler)
        return try promise.futureResult.wait()
    }

    public func index(_ index: String, _ id: String, _ document: Data) throws {
        let path = "\(index)/_doc/\(id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"

        let promise = eventLoop.makePromise(of: Int.self)
        try client.execute(
            request: HTTPRequestBuilder()
                .set(method: .PUT)
                .set(path: path)
                .set(headers: ["Content-Type": "application/json; charset=utf-8"])
                .set(body: document)
                .build(), 
            completionHandler: { result in
                switch result {
                    case .failure(let error):
                        promise.fail(error)
                        break
                    case .success(let response):
                        if response.status == .ok || response.status == .created {
                            promise.succeed(0)
                        } else {
                            promise.fail(RangicError.http(response.status, String(data: response.body!, encoding: .utf8)!))
                        }
                        break
                }
        })

        let _ = try promise.futureResult.wait()
    }

    public func index(_ items: [FpMedia]) throws -> BulkResponse {
        let builder = BulkRequestBuilder().set(index: ElasticSearchClient.MediaIndexName)
        for i in items {
            builder.add(request: IndexRequest<FpMedia>(
                index: ElasticSearchClient.MediaIndexName, id: i.path, source: i))
        }

        let request = try builder.build()
        let promise = eventLoop.makePromise(of: BulkResponse.self)

        func handler(_ result: Result<BulkResponse, Error>) {
            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    promise.succeed(response)
                    break
            }
        }

        client.bulk(request, completionHandler: handler)
        return try promise.futureResult.wait()
    }
}
