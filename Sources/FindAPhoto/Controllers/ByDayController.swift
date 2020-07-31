import FPCore
import Logging
import Vapor

struct ByDayQueryParams: Codable {
    let month: Int
    let day: Int
    let first: Int?
    let count: Int?
    let properties: String?
}


final class ByDayController: RouteCollection {
    private static let logger = Logger(label: "findAPhoto.ByDayController")

    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.get("by-day", use: byday)
    }


    func byday(_ req: Request) throws -> EventLoopFuture<APISearchResponse> {
        let qp = try req.query.decode(ByDayQueryParams.self)
        let options = try CommonSearchOptions(qp.first, qp.count, qp.properties)

        let dayOfYear = DayOfYear.from(month: qp.month, day: qp.day)
        let previousCompare = dayOfYear == 1 ? RangeCompare.greaterThan : RangeCompare.lessThan
        let previousFuture = try ElasticSearchClient(req.eventLoop)
            .rangeSearch(0, 1, "dayOfYear", previousCompare, "\(dayOfYear)", "dayOfYear", false)

        let nextCompare = dayOfYear == 365 ? RangeCompare.lessThan : RangeCompare.greaterThan
        let nextFuture = try ElasticSearchClient(req.eventLoop)
            .rangeSearch(0, 1, "dayOfYear", nextCompare, "\(dayOfYear)", "dayOfYear", true)

        return try ElasticSearchClient(req.eventLoop)
            .search(options.first, options.count, "dayOfYear:\(dayOfYear)")
            .flatMap { fpResponse in
                // let promise = eventLoop.makePromise(of: APISearchResponse.self)
                var apiResponse = APISearchResponse()
                apiResponse.totalMatches = fpResponse.total
                apiResponse.resultCount = fpResponse.hits.count
                do {
                    apiResponse.groups = try GroupMapping.asGroups(fpResponse.hits, .date, options.properties)
                    return self.populatePrevAndNext(apiResponse, previousFuture, nextFuture)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            }.map { apiResponse in
                return apiResponse
            }
    }

    func populatePrevAndNext(_ apiResponse: APISearchResponse, 
                                _ prevFuture: EventLoopFuture<FpSearchResponse>, 
                                _ nextFuture: EventLoopFuture<FpSearchResponse>)
                                -> EventLoopFuture<APISearchResponse> {
        var response = apiResponse
        return prevFuture.flatMap { prevResponse in
            if let first = prevResponse.hits.first {
                let (month, day) = DayOfYear.toMonthDay(date: first.media.dateTime)
                response.previousAvailableDay = APISearchResponse.AvailableDay(month: month, day: day)
            }

            return nextFuture.flatMap { nextResponse in
                if let first = nextResponse.hits.first {
                    let (month, day) = DayOfYear.toMonthDay(date: first.media.dateTime)
                    response.nextAvailableDay = APISearchResponse.AvailableDay(month: month, day: day)
                }
                return eventLoop.makeSucceededFuture(response)
            }
        }
    }
}
