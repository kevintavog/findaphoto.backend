import FPCore
import Vapor

final class IndexController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        let index = api.grouped("index")
        index.get("info", use: info)
    }


    func info(_ req: Request) throws -> EventLoopFuture<IndexInfoResponse> {
        return try ElasticSearchClient(req.eventLoop)
            .indexInfo()
            .map { i in
                return i
            }
    }
}
