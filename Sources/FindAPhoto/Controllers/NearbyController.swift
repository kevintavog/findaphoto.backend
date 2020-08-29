import FPCore
import Vapor

struct NearbyQueryParams: Codable {
    let lat: Double
    let lon: Double
    let maxKilometers: Double?
    let first: Int?
    let count: Int?
    let properties: String?
    let categories: String?
}


final class NearbyController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.get("nearby", use: nearby)
    }


    func nearby(_ req: Request) throws -> EventLoopFuture<APISearchResponse> {
        let qp = try req.query.decode(NearbyQueryParams.self)
        let options = try CommonSearchOptions.parse(qp.first, qp.count, qp.properties, qp.categories)

        let radiusKm = qp.maxKilometers ?? 100.0
        if radiusKm < 1 || radiusKm > 20000 {
            throw RangicError.invalidParameter("'maxKilometers' must be between  1 and 20,000, inclusive")
        }

        return try ElasticSearchClient(req.eventLoop)
            .nearby(qp.lat, qp.lon, radiusKm, options)
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
