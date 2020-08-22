import Foundation

import ElasticSwift
// import ElasticSwiftCore
// import ElasticSwiftNetworkingNIO
import Vapor
import SwiftyJSON


public enum RangeCompare {
    case greaterThan, greaterThanEqual, lessThan, lessThanEqual
}

public class ElasticSearchClient {
    static public var ServerUrl = ""
    static public var AliasIndexName = "fp-alias"
    static public var MediaIndexName = "fp-media"
    static public var versionNumber: String = ""
    static internal var defaultSearchFields = ["dayname", "keywords", "locationPlaceName", "monthname", "path", "tags"]

    static public func setIndexPrefix(_ indexPrefix: String) {
        AliasIndexName = indexPrefix + AliasIndexName
        MediaIndexName = indexPrefix + MediaIndexName
        print("NOTE: Overriding index names with prefix: '\(indexPrefix)''")
    }

    static public var version: String {
        return versionNumber
    }

    internal let eventLoop: EventLoop
    internal let client: ElasticClient


    public init(_ eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        let settings = Settings(
            forHost: ElasticSearchClient.ServerUrl,
            adaptorConfig: AsyncHTTPClientAdaptorConfiguration.default,
            serializer: getFpMediaSerializer())
        self.client = ElasticClient(settings: settings)
    }


    private func asString(_ request: ElasticSwift.Request) -> String {
        let result = request.makeBody(DefaultSerializer())
        switch result {
            case .failure(let error):
                return "FAILED: \(error)"
            case .success(let data):
                return String(data: data, encoding: .utf8) ?? "FAILED: converting data"
        }
    }

    public func rangeSearch(
                _ from: Int, _ size: Int, _ field: String, _ compare: RangeCompare,
                _ val: String, _ sortField: String, _ sortAscending: Bool) 
                throws -> EventLoopFuture<FpSearchResponse> {
        let builder = QueryBuilders.rangeQuery()
            .set(field: field)

        switch compare {
            case .greaterThan:
                _ = builder.set(gt: val)
                break
            case .greaterThanEqual:
                _ = builder.set(gte: val)
                break
            case .lessThan:
                _ = builder.set(lt: val)
                break
            case .lessThanEqual:
                _ = builder.set(lte: val)
                break
        }

        let request = try SearchRequestBuilder()
                .set(indices: ElasticSearchClient.MediaIndexName)
                .set(query: builder.build())
                .set(trackTotalHits: true)
                .set(from: from)
                .set(size: size)
                .add(sort: SortBuilders.fieldSort(sortField).set(order: sortAscending ? .asc : .desc).build())
                .build()

        return executeSearch(request)
    }

    public func term(_ from: Int, _ size: Int, _ field: String, _ val: String) throws -> EventLoopFuture<FpSearchResponse> {
        let query = try QueryBuilders.termQuery()
            .set(field: field)
            .set(value: val)
            .build()

        let request = try SearchRequestBuilder()
            .set(indices: ElasticSearchClient.MediaIndexName)
            .set(query: query)
            .set(trackTotalHits: true)
            .set(from: from)
            .set(size: size)
            .build()

        return executeSearch(request)
    }

    public func search(_ from: Int, _ size: Int, _ queryString: String?) throws -> EventLoopFuture<FpSearchResponse> {
        let query: Query = queryString?.isEmpty ?? true == true
            ? try QueryBuilders.matchAllQuery().build()
            : try QueryBuilders.queryStringQuery()
                .set(query: queryString!)
                .set(fields: ElasticSearchClient.defaultSearchFields)
                .build()

        let request = try SearchRequestBuilder()
            .set(indices: ElasticSearchClient.MediaIndexName)
            .set(query: query)
            .set(trackTotalHits: true)
            .set(from: from)
            .set(size: size)
            .add(sort: SortBuilders.fieldSort("date.keyword").set(order: .desc).build())
            .add(sort: SortBuilders.fieldSort("dateTime").set(order: .asc).build())
            .build()

        return executeSearch(request)
    }

    public func nearby(_ latitude: Double, _ longitude: Double, _ radiusKm: Double, _ from: Int, _ size: Int) 
                throws -> EventLoopFuture<FpSearchResponse> {
        
        let point = GeoPoint(lat: Decimal(latitude), lon: Decimal(longitude))
        let query = try QueryBuilders.geoDistanceQuery()
            .set(field: "location")
            .set(point: point)
            .set(distance: "\(radiusKm) km")
            .build()

        let request = try SearchRequestBuilder()
            .set(indices: ElasticSearchClient.MediaIndexName)
            .set(query: query)
            .set(trackTotalHits: true)
            .set(from: from)
            .set(size: size)
            .add(sort: SortBuilders.geoDistance("location", point)
                .set(order: .asc)
                .set(unit: "km")
                .set(mode: .min)
                .build())
            .build()

        return executeSearch(request)
    }

    private func executeSearch(_ request: SearchRequest) -> EventLoopFuture<FpSearchResponse> {
        let promise = eventLoop.makePromise(of: FpSearchResponse.self)
        func handler(_ result: Result<SearchResponse<FpMedia>, Error>) {
            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    promise.succeed(FpSearchResponse(
                        response.hits.hits.map { FpSearchResponse.Hit($0.source!, $0.sort?[0].value ?? "") },
                        response.hits.total.value))
                    break
            }
        }

print("searching with \(asString(request))")
        client.search(request, completionHandler: handler)
        return promise.futureResult
    }

    public func mappings(_ index: String) throws -> EventLoopFuture<[String]> {
        let promise = eventLoop.makePromise(of: [String].self)

        let path = "\(index)/_mappings"
        try client.execute(
            request: HTTPRequestBuilder().set(method: .GET).set(path: path).build(), 
            completionHandler: { result in

            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    if let data = response.body {
                        if response.status != .ok {
                            let bodyText = String(data: data, encoding: .utf8) ?? ""
                            promise.fail(RangicError.http(response.status, bodyText))
                        }

                        do {
                            let json = try JSON(data: data)
                            var fieldNames = [String]()
                            for propJson in json[index]["mappings"]["properties"] {
                                fieldNames.append(propJson.0)
                            }
                            promise.succeed(fieldNames)
                        } catch {
                            promise.fail(error)
                        }
                    } else {
                        promise.fail(RangicError.unexpected("No data returned"))
                    }
                    break
            }
        })

        return promise.futureResult
    }

    public func indices(_ indices: [String]) throws -> EventLoopFuture<[ElasticSearchIndexResponse]> {
        let promise = eventLoop.makePromise(of: [ElasticSearchIndexResponse].self)

        let path = "_cat/indices/\(indices.joined(separator: ","))?format=json"
        try client.execute(
            request: HTTPRequestBuilder().set(method: .GET).set(path: path).build(), 
            completionHandler: { result in

            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    if let data = response.body {
                        if response.status != .ok {
                            let bodyText = String(data: data, encoding: .utf8) ?? ""
                            promise.fail(RangicError.http(response.status, bodyText))
                        }

                        do {
                            let indices = try JSONDecoder().decode([ElasticSearchIndexResponse].self, from: data)
                            promise.succeed(indices)
                        } catch {
                            promise.fail(error)
                        }
                    } else {
                        promise.fail(RangicError.unexpected("No data returned"))
                    }
                    break
            }
        })

        return promise.futureResult
    }

    public func bulkIndex(items: [FpMedia]) throws -> EventLoopFuture<BulkResponse> {
        let builder = BulkRequestBuilder().set(index: ElasticSearchClient.MediaIndexName)
        for i in items {
            builder.add(request: IndexRequest<FpMedia>(
                index: ElasticSearchClient.MediaIndexName, id: i.path, source: i))
        }
        let request = try builder.build()
        let promise = eventLoop.makePromise(of: BulkResponse.self)
        func handler(_ result: Result<BulkResponse, Error>) {
            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    promise.succeed(response)
                    break
            }
        }

        client.bulk(request, completionHandler: handler)
        return promise.futureResult
    }
}
