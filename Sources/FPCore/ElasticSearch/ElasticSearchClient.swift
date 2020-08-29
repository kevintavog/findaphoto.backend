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
        let queryBuilder = QueryBuilders.rangeQuery()
            .set(field: field)

        switch compare {
            case .greaterThan:
                _ = queryBuilder.set(gt: val)
                break
            case .greaterThanEqual:
                _ = queryBuilder.set(gte: val)
                break
            case .lessThan:
                _ = queryBuilder.set(lt: val)
                break
            case .lessThanEqual:
                _ = queryBuilder.set(lte: val)
                break
        }

        let builder = try SearchRequestBuilder()
                .set(indices: ElasticSearchClient.MediaIndexName)
                .set(query: queryBuilder.build())
                .set(trackTotalHits: true)
                .set(from: from)
                .set(size: size)
                .add(sort: SortBuilders.fieldSort(sortField).set(order: sortAscending ? .asc : .desc).build())

        return try executeSearch(builder, FpCategoryOptions())
    }

    public func term(_ from: Int, _ size: Int, _ field: String, _ val: String) throws -> EventLoopFuture<FpSearchResponse> {
        let query = try QueryBuilders.termQuery()
            .set(field: field)
            .set(value: val)
            .build()

        let builder = SearchRequestBuilder()
            .set(indices: ElasticSearchClient.MediaIndexName)
            .set(query: query)
            .set(trackTotalHits: true)
            .set(from: from)
            .set(size: size)

        return try executeSearch(builder, FpCategoryOptions())
    }

    public func search(_ queryString: String?, _ options: SearchOptions) 
                throws -> EventLoopFuture<FpSearchResponse> {
        let query: Query = queryString?.isEmpty ?? true == true
            ? try QueryBuilders.matchAllQuery().build()
            : try QueryBuilders.queryStringQuery()
                .set(query: queryString!)
                .set(fields: ElasticSearchClient.defaultSearchFields)
                .build()

        let builder = SearchRequestBuilder()
            .set(indices: ElasticSearchClient.MediaIndexName)
            .set(query: query)
            .set(trackTotalHits: true)
            .set(from: options.first)
            .set(size: options.count)
            .add(sort: SortBuilders.fieldSort("date.keyword").set(order: .desc).build())
            .add(sort: SortBuilders.fieldSort("dateTime").set(order: .asc).build())

        return try executeSearch(builder, options.categories)
    }

    public func nearby(_ latitude: Double, _ longitude: Double, 
                        _ radiusKm: Double, _ options: SearchOptions) 
                throws -> EventLoopFuture<FpSearchResponse> {
        
        let point = GeoPoint(lat: Decimal(latitude), lon: Decimal(longitude))
        let query = try QueryBuilders.geoDistanceQuery()
            .set(field: "location")
            .set(point: point)
            .set(distance: "\(radiusKm) km")
            .build()

        let builder = SearchRequestBuilder()
            .set(indices: ElasticSearchClient.MediaIndexName)
            .set(query: query)
            .set(trackTotalHits: true)
            .set(from: options.first)
            .set(size: options.count)
            .add(sort: SortBuilders.geoDistance("location", point)
                .set(order: .asc)
                .set(unit: "km")
                .set(mode: .min)
                .build())

        return try executeSearch(builder, options.categories)
    }

    private func executeSearch(_ builder: SearchRequestBuilder, _ categoryOptions: FpCategoryOptions) 
            throws -> EventLoopFuture<FpSearchResponse> {
        let promise = eventLoop.makePromise(of: FpSearchResponse.self)
        func handler(_ result: Result<SearchResponse<FpMedia>, Error>) {
            switch result {
                case .failure(let error):
                    promise.fail(error)
                    break
                case .success(let response):
                    promise.succeed(FpSearchResponse(
                        response.hits.hits.map { FpSearchResponse.Hit($0.source!, $0.sort?[0].value ?? "") },
                        response.hits.total.value,
                        processAggregations(response.aggregations)))
                    break
            }
        }

        addAggregations(builder, categoryOptions)
        let request = try builder.build()
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

    private func processAggregations(_ aggregations: [String:AggregationResponse]?) -> [FpSearchResponse.CategoryResult] {
        var results = [FpSearchResponse.CategoryResult]()

        if let aggs = aggregations {
            for (key, item) in aggs {
                let details = processBucketAggregations(item.buckets)
                if details.count > 0 {
                    results.append(FpSearchResponse.CategoryResult(key, details))
                }
            }
        }

        return results
    }

    private func processBucketAggregations(_ buckets : [AggregationBucketResponse]) -> [FpSearchResponse.CategoryDetail] {
        var details = [FpSearchResponse.CategoryDetail]()
        for b in buckets {
            if b.count == 0 {
                continue
            }

            var children = [FpSearchResponse.CategoryDetail]()
            if let subAggs = b.aggregations {
                for (_, subValue) in subAggs {
                    children += processBucketAggregations(subValue.buckets)
                }
            }

            var bucketDetail = FpSearchResponse.CategoryDetail(b.key, b.count)
            if children.count > 0 {
                bucketDetail.children = children
            }
            details.append(bucketDetail)
        }
        return details
    }

    private func addAggregations(_ builder: SearchRequestBuilder, _ categoryOptions: FpCategoryOptions) {
        if categoryOptions.keywordCount > 0 {
            builder.add(
                name: "keywords",
                aggregation: AggregationBuilders
                    .term("keywords.keyword")
                    .set(size: categoryOptions.keywordCount)
                    .build())
        }

        if categoryOptions.tagCount > 0 {
            builder.add(
                name: "tags",
                aggregation: AggregationBuilders
                    .term("tags.keyword")
                    .set(size: categoryOptions.tagCount)
                    .build())
        }

        if categoryOptions.placenameCount > 0 {
            builder.add(name: "countryName", aggregation: AggregationBuilders
                .term("locationCountryName.keyword")
                .add(name: "state", aggregation: AggregationBuilders
                    .term("locationStateName.keyword")
                    .add(name: "city", aggregation: AggregationBuilders
                        .term("locationCityName.keyword")
                        .add(name: "site", aggregation: AggregationBuilders
                            .term("locationSiteName.keyword")
                            .build())
                        .build())
                    .build())
                .build())
        }

        if categoryOptions.dateCount > 0 {
            builder.add(name: "dateYear", aggregation: AggregationBuilders
                .term("dateYear.keyword")
                .add(name: "dateMonth", aggregation: AggregationBuilders
                    .term("dateMonth.keyword")
                    .add(name: "dateDaty", aggregation: AggregationBuilders
                        .term("dateDay.keyword")
                        .build())
                    .build())
                .build())
        }
    }
}
