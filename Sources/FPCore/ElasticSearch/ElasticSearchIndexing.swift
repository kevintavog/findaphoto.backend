import Foundation
import NIO
import NIOHTTP1

import ElasticSwift
// import ElasticSwiftCore
// import ElasticSwiftNetworkingNIO

public class ElasticSearchIndexing {
    let client: ElasticClient
    let eventLoop: EventLoop

    public init(_ eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        client = ElasticClient(settings: Settings(
            forHost: ElasticSearchClient.ServerUrl,
            adaptorConfig: AsyncHTTPClientAdaptorConfiguration.default,
            serializer: getFpMediaSerializer()))
    }

    // Returns the signatures of the given items
    public func signatures(_ items: [FpFile]) throws -> [String:String] {
        let multiItems = items.map { MultiGetRequest.Item(
            index: ElasticSearchClient.MediaIndexName,
            id: $0.path)}

        let request = MultiGetRequest(items: multiItems, source: "true", sourceIncludes: ["signature"])
        let promise = eventLoop.makePromise(of: [String:String].self)
        func handler(_ result: Result<MultiGetResponse, Error>) {
            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    var pathToSignature = [String:String]()
                    for r in response.responses {
                        if r.response!.found {
                            let dict = r.response!.source!.value as! [String:String]
                            pathToSignature[r.response!.id] = dict["signature"]
                        }
                    }
                    promise.succeed(pathToSignature)
                    break
            }
        }

        client.mget(request, completionHandler: handler)
        return try promise.futureResult.wait()
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
