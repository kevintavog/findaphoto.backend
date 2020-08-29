import FPCore
import Vapor

struct SearchQueryParams: Codable {
    let first: Int?
    let count: Int?
    let properties: String?
    let query: String?
    let q: String?      // backward compatibility
    let categories: String?
}


final class SearchController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.get("search", use: search)
    }


    func search(_ req: Request) throws -> EventLoopFuture<APISearchResponse> {
        let qp = try req.query.decode(SearchQueryParams.self)
        let options = try CommonSearchOptions.parse(qp.first, qp.count, qp.properties, qp.categories)

        return try ElasticSearchClient(req.eventLoop)
            .search(qp.query ?? qp.q, options)
            .flatMap { fpResponse in
                var apiResponse = APISearchResponse()
                apiResponse.totalMatches = fpResponse.total
                apiResponse.resultCount = fpResponse.hits.count
                do {
                    apiResponse.categories = CagegoryMapping.toAPI(fpResponse.categories)
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
