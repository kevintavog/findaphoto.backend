import Foundation
import ElasticSwift

import Vapor

public class Aliases {
    static public var aliasOverride = ""

    static var client: ElasticClient? = nil
    static let MaxAliasCount: Int = 100
    static var eventLoop: EventLoop? = nil
    static var allAliases = [FpAlias]()

    static public func initialize(_ eventLoop: EventLoop) throws {
        Aliases.eventLoop = eventLoop
        client = ElasticClient(settings: Settings(
            forHost: ElasticSearchClient.ServerUrl,
            adaptorConfig: AsyncHTTPClientAdaptorConfiguration.default,
            serializer: getFpMediaSerializer()))

        try load()
    }

    static public func reload() throws {
        print("Reloading aliases")
        try load()
    }

    static public func addOrCreateFrom(path: String) throws -> String {
        let normalized = PathUtils.normalize(path)
        if let alias = from(path: normalized) {
            return alias
        }

        try addNewAlias(normalized)
        if let alias = from(path: normalized) {
            return alias
        }
        throw RangicError.unexpected("Failed finding just added alias for '\(normalized)'")
    }

    static public func from(path: String) -> String? {
        let normalized = PathUtils.normalize(path)
        for a in allAliases {
            if a.path.caseInsensitiveCompare(normalized) == .orderedSame {
                return a.alias
            }
        }
        return nil
    }

    static public func from(alias: String) -> String? {
        for a in allAliases {
            if a.alias.caseInsensitiveCompare(alias) == .orderedSame {
                return a.path
            }
        }
        return nil
    }

    static private func addNewAlias(_ path: String) throws {
        let newAliasNumber = allAliases.count + 1
        let fpAlias = FpAlias(alias: "\(newAliasNumber)", path: path)
        print("Adding alias '\(fpAlias.alias)' for '\(fpAlias.path)'")

        let request = try IndexRequestBuilder<FpAlias>()
            .set(index: ElasticSearchClient.AliasIndexName)
            .set(id: fpAlias.alias)
            .set(source: fpAlias)
            .set(refresh: .true)
            .build()

        let promise = eventLoop!.makePromise(of: IndexResponse.self)
        func handler(_ result: Result<IndexResponse, Error>) {
            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    promise.succeed(response)
                    break
            }

        }
        client!.index(request, completionHandler: handler)
        let _ = try promise.futureResult.wait()
        try load()
    }

    static private func load() throws {
        let request = try SearchRequestBuilder()
            .set(indices: ElasticSearchClient.AliasIndexName)
            .set(query: QueryBuilders.matchAllQuery().build())
            .set(size: MaxAliasCount)
            .build()

        let promise = eventLoop!.makePromise(of: [FpAlias].self)
        func handler(_ result: Result<SearchResponse<FpAlias>, Error>) {
            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    promise.succeed(response.hits.hits.map { $0.source! })
                    break
            }
        }

        client!.search(request, completionHandler: handler)
        allAliases = try promise.futureResult.wait()
        if aliasOverride.count > 0 {
            allAliases = allAliases.map {
                print("NOTE: Overriding the alias path from \($0.path) to \(aliasOverride)")
                return FpAlias(pathOverride: aliasOverride, alias: $0)
            }
        }
    }
}
