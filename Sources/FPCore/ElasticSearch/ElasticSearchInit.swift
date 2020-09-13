import Foundation
import NIO
import NIOHTTP1

import ElasticSwift
// import ElasticSwiftCore
// import ElasticSwiftNetworkingNIO

public class ElasticSearchInit {
    static var eventLoop: EventLoop? = nil

    static public func run(_ eventLoop: EventLoop) throws {
        ElasticSearchInit.eventLoop = eventLoop
        let client = ElasticClient(settings: Settings(
            forHost: ElasticSearchClient.ServerUrl,
            adaptorConfig: AsyncHTTPClientAdaptorConfiguration.default))

        try elasticVersion(client)

        // Ensure indexes exists - create them if needed
        if try !doesIndexExist(client, ElasticSearchClient.MediaIndexName) {
            try createIndex(client, ElasticSearchClient.MediaIndexName, fpMediaCreateBody)
        }

        if try !doesIndexExist(client, ElasticSearchClient.AliasIndexName) {
            try createIndex(client, ElasticSearchClient.AliasIndexName, fpAliasCreateBody)
        }
    }

    static public func createIndex(_ client: ElasticClient, _ indexName: String, _ body: String) throws {
        print("Creating \(indexName)")

        let promise = eventLoop!.makePromise(of: Bool.self)
        let request = try HTTPRequestBuilder()
            .set(method: .PUT)
            .set(path: indexName)
            .set(headers: HTTPHeaders([("content-type", "application/json")]))
            .set(body: body.data(using: String.Encoding.utf8)!)
            .build()
        client.execute(
            request: request, 
            completionHandler: { result in

            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    if let data = response.body {
                        if response.status != .ok {
                            let bodyText = String(data: data, encoding: .utf8) ?? ""
                            promise.fail(RangicError.http(response.status, bodyText))
                        } else {
                            promise.succeed(true)
                        }
                    } else {
                        promise.fail(RangicError.unexpected("No data returned"))
                    }
                    break
            }
        })

        let _ = try promise.futureResult.wait()
    }

    static public func doesIndexExist(_ client: ElasticClient, _ indexName: String) throws -> Bool {
        let promise = eventLoop!.makePromise(of: Bool.self)
        client.indices.exists(IndexExistsRequest(indexName), completionHandler: { result in
            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    promise.succeed(response.exists)
                    break
            }
        })

        return try promise.futureResult.wait()
    }

    static internal func elasticVersion(_ client: ElasticClient) throws {
        let promise = eventLoop!.makePromise(of: String.self)
        try client.execute(
            request: HTTPRequestBuilder().set(method: .GET).set(path: "/").build(), 
            completionHandler: { result in

            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    if let data = response.body {
                        if response.status != .ok {
                            let bodyText = String(data: data, encoding: .utf8) ?? ""
                            promise.fail(RangicError.http(response.status, bodyText))
                        }

                        do {
                            let root = try JSONDecoder().decode(RootResponse.self, from: data)
                            promise.succeed(root.version.number)
                        } catch {
                            promise.fail(error)
                        }
                    } else {
                        promise.fail(RangicError.unexpected("No data returned"))
                    }
                    break
            }
        })

        ElasticSearchClient.versionNumber = try promise.futureResult.wait()
    }
}
