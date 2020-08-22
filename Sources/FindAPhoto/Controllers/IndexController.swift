import FPCore
import Vapor

struct ReindexQueryParams: Codable {
    let force: Bool?
}

struct ReindexResponse: Content {
}

struct InfoQueryParams: Codable {
    let properties: String?
}

final class IndexController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        let index = api.grouped("index")
        index.get("info", use: info)
        index.post("reindex", use: reindex)
    }


    func info(_ req: Request) throws -> EventLoopFuture<IndexInfoResponse> {
        var info = IndexInfoResponse()

        let client = ElasticSearchClient(req.eventLoop)
        var futures = [EventLoopFuture<IndexInfoResponse>]()

        let qp = try req.query.decode(InfoQueryParams.self)
        for prop in (qp.properties ?? "build").split(separator: ",") {
            switch prop.lowercased() {
                case "dependencyinfo":
                    try futures.append(client
                        .indices([ElasticSearchClient.MediaIndexName, ElasticSearchClient.AliasIndexName])
                        .map { indices in
                            var di = IndexInfoResponse.DependencyInfo()
                            di.elasticSearch.version = ElasticSearchClient.versionNumber
                            for index in indices {
                                di.elasticSearch.indices.append(
                                    IndexInfoResponse.DependencyInfo.ElasticSearch.IndexInfo(index.index, index.health))
                            }
                            info.dependencyInfo = di
                            return info
                        })
                    break
                case "fields":
                    try futures.append(client
                        .mappings(ElasticSearchClient.MediaIndexName)
                        .map { response in
                            info.fields = response.sorted()
                            return info
                        })
                    break
                case "imagecount":
                    try futures.append(client
                        .search(0, 1, "mimeType.keyword:image*")
                        .map { response in
                            info.imageCount = response.total
                            return info
                        })
                    break
                case "paths":
                    var paths = [IndexInfoResponse.PathInfo]()
                    for alias in Aliases.allAliases {
                        paths.append(IndexInfoResponse.PathInfo(alias.path, alias.dateLastIndexed))
                    }
                    info.paths = paths
                    break
                case "build":
                    info.buildTimestamp = buildTimestamp
                    break
                case "videocount":
                    try futures.append(client
                        .search(0, 1, "mimeType.keyword:video*")
                        .map { response in
                            info.videoCount = response.total
                            return info
                        })
                    break
                case "warningcount":
                    try futures.append(client
                        .search(0, 1, "warnings:*")
                        .map { response in
                            info.warningCount = response.total
                            return info
                        })
                    break
                default:
                    throw Abort(.badRequest, reason: "Unknown property: '\(prop)'")
            }
        }

        let promise = req.eventLoop.makePromise(of: IndexInfoResponse.self)
        if futures.count > 0 {
            EventLoopFuture.whenAllComplete(futures, on: eventLoop)
                .whenSuccess { result in
                    promise.succeed(info)
                }
        } else {
            promise.succeed(info)
        }

        return promise.futureResult
    }

    func reindex(_ req: Request) throws -> ReindexResponse {
        let qp = try req.query.decode(ReindexQueryParams.self)
        runIndexerInBackground(reindex: qp.force ?? false)
        throw Abort(.noContent)
    }
}
