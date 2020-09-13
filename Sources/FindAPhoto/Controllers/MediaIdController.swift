import FPCore
import SwiftyJSON
import Vapor

final class MediaIdController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.get("media", ":id", use: media)
    }


    func media(_ req: Request) throws -> EventLoopFuture<String> {
        let id = req.parameters.get("id")!
        return try ElasticSearchClient(req.eventLoop)
            .term("_id", id, SearchOptions(first: 0, count: 1))
            .flatMap { fpResponse in
                if fpResponse.total == 0 {
                    return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "No matching media found"))
                }
                if fpResponse.total > 1 {
                    return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Too many matchin media found"))
                }
// TODO Need to set response content-type = application/json
                let hit = fpResponse.hits[0]
                do {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
#if !os(Linux)
                    encoder.outputFormatting = .withoutEscapingSlashes
#endif
                    let data = try encoder.encode(hit.media)
                    if let json = try JSON(data: data).rawString() {
                        return req.eventLoop.makeSucceededFuture(json)
                    } else {
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Cannot convert to JSON"))
                    }
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            }.map { apiResponse in
                return apiResponse
            }
    }
}
