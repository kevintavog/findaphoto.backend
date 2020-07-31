import FPCore
import Vapor

struct SearchQueryParams: Codable {
    let first: Int?
    let count: Int?
    let properties: String?
    let query: String?
    let q: String?      // backward compatibility
}


final class SearchController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.get("search", use: search)
    }


    func search(_ req: Request) throws -> EventLoopFuture<APISearchResponse> {
        let qp = try req.query.decode(SearchQueryParams.self)
        let options = try CommonSearchOptions(qp.first, qp.count, qp.properties)

        return try ElasticSearchClient(req.eventLoop)
            .search(options.first, options.count, qp.query ?? qp.q)
            .flatMap { fpResponse in
                var apiResponse = APISearchResponse()
                apiResponse.totalMatches = fpResponse.total
                apiResponse.resultCount = fpResponse.hits.count
                do {
                    apiResponse.groups = try GroupMapping.asGroups(fpResponse.hits, .date, options.properties)
                    return req.eventLoop.makeSucceededFuture(apiResponse)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            }.map { apiResponse in
                return apiResponse
            }
    }
}
