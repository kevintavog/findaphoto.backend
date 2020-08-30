import FPCore
import Vapor

struct FieldValuesParams: Content {
    let fields: String?
    let max: Int?

    let q: String?
    let month: Int?
    let day: Int?
}

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
        index.get("fieldvalues", use: fieldValues)
        index.post("reindex", use: reindex)
    }


    func info(_ req: Request) throws -> EventLoopFuture<IndexInfoResponse> {
        var info = IndexInfoResponse()

        let client = ElasticSearchClient(req.eventLoop)
        var futures = [EventLoopFuture<IndexInfoResponse>]()
        let searchOptions = SearchOptions(
            first: 0,
            count: 1,
            properties: [],
            categories: FpCategoryOptions())

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
                        .search("mimeType.keyword:image*", searchOptions)
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
                        .search("mimeType.keyword:video*", searchOptions)
                        .map { response in
                            info.videoCount = response.total
                            return info
                        })
                    break
                case "warningcount":
                    try futures.append(client
                        .search("warnings:*", searchOptions)
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

    func fieldValues(_ req: Request) throws -> EventLoopFuture<FieldValuesResponse> {
        let qp = try req.query.decode(FieldValuesParams.self)
        let fields = (qp.fields ?? "").split(separator: ",")
        if fields.count < 1 {
            throw Abort(.badRequest, reason: "'fields' query parameter missing")
        }

        var options = SearchOptions(first: 0, count: 0, properties: [],categories: FpCategoryOptions())
        options.fieldValues.maxCount = qp.max ?? 20
        options.fieldValues.fields = fields.map { String($0) }
        var query = qp.q ?? ""
        if let month = qp.month, let day = qp.day {
            let dayOfYear = DayOfYear.from(month: month, day: day)
            query = "dayOfYear:\(dayOfYear)"
        }

        return try ElasticSearchClient(req.eventLoop)
            .search(query, options)
            .flatMap { fpResponse in
                return req.eventLoop.makeSucceededFuture(FieldValuesResponse(
                    FieldValueMapping.toAPI(fpResponse.fieldValues)
                ))
            }.map { fvResponse in
                return fvResponse
            }
    }

    func reindex(_ req: Request) throws -> ReindexResponse {
        let qp = try req.query.decode(ReindexQueryParams.self)
        runIndexerInBackground(reindex: qp.force ?? false)
        throw Abort(.noContent)
    }
}
