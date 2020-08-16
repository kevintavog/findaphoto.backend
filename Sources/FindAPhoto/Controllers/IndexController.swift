import FPCore
import Vapor

struct ReindexQueryParams: Codable {
    let force: Bool?
}

struct ReindexResponse: Content {
}

final class IndexController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        let index = api.grouped("index")
        index.get("info", use: info)
        index.post("reindex", use: reindex)
    }


    func info(_ req: Request) throws -> EventLoopFuture<IndexInfoResponse> {
        return try ElasticSearchClient(req.eventLoop)
            .indexInfo()
            .map { i in
                return i
            }
    }

    func reindex(_ req: Request) throws -> ReindexResponse {
        let qp = try req.query.decode(ReindexQueryParams.self)
        runIndexerInBackground(reindex: qp.force ?? false)
        throw Abort(.noContent)
    }
}
