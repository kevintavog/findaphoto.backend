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
    public let client: ElasticClient


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

        let builder = SearchRequestBuilder()
            .set(indices: ElasticSearchClient.MediaIndexName)
            .set(trackTotalHits: true)
            .set(from: from)
            .set(size: size)
            .add(sort: SortBuilders.fieldSort(sortField).set(order: sortAscending ? .asc : .desc).build())

        return try executeSearch(builder, queryBuilder.build(), SearchOptions(first: from, count: size))
    }

    public func term(_ field: String, _ val: String, _ options: SearchOptions) throws -> EventLoopFuture<FpSearchResponse> {
        let query = try QueryBuilders.termQuery()
            .set(field: field)
            .set(value: val)
            .build()

        let builder = SearchRequestBuilder()
            .set(indices: ElasticSearchClient.MediaIndexName)
            .set(trackTotalHits: true)
            .set(from: options.first)
            .set(size: options.count)

        return try executeSearch(builder, query, options)
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
            .set(trackTotalHits: true)
            .set(from: options.first)
            .set(size: options.count)
            .add(sort: SortBuilders.fieldSort("date.keyword").set(order: .desc).build())
            .add(sort: SortBuilders.fieldSort("dateTime").set(order: .asc).build())

        return try executeSearch(builder, query, options)
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
            .set(trackTotalHits: true)
            .set(from: options.first)
            .set(size: options.count)
            .add(sort: SortBuilders.geoDistance("location", point)
                .set(order: .asc)
                .set(unit: "km")
                .set(mode: .min)
                .build())

        return try executeSearch(builder, query, options)
    }

    private func executeSearch(_ builder: SearchRequestBuilder, _ query: Query, _ options: SearchOptions)
                                throws -> EventLoopFuture<FpSearchResponse> {
        try drilldown(builder, query, options)
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
                        processCategories(response.aggregations),
                        processFieldValues(options.fieldValues, response.aggregations)))
                    break
            }
        }

        addCategories(builder, options.categories)
        addFieldValues(builder, options.fieldValues)
        let request = try builder.build()

        if options.logSearch {
            print("searching with \(asString(request))")
        }

        client.search(request, completionHandler: handler)
        return promise.futureResult
    }

    private func drilldown(_ builder: SearchRequestBuilder, _ query: Query, _ options: SearchOptions) throws {
        if options.drilldown.count > 0 {
            let queryBuilder = QueryBuilders.boolQuery().must(query: query)
            var locationQueryList: [Query] = []
            var dateQueryList: [Query] = []
            for (key, values) in options.drilldown {
                var field = key

                let keyGroup = key.split(separator: "~")
                let isHierarchical = keyGroup.count > 1
                if isHierarchical {
                    field = String(keyGroup[0])
                }

        		if isLocationField(field) {
                    if isHierarchical {
                        for vs in values {
                            let groups = vs.split(separator: "~")
                            let valueQueryBuilder = QueryBuilders.boolQuery()
                            for (idx, _) in groups.enumerated() {
                                try valueQueryBuilder.must(query: QueryBuilders.termQuery()
                                    .set(field: getLocationFieldName(String(keyGroup[idx])))
                                    .set(value: String(groups[idx]))
                                    .build())
                            }
                            try locationQueryList.append(valueQueryBuilder.build())
                        }
                    } else {
                        for v in values {
                            try locationQueryList.append(
                                QueryBuilders.termQuery()
                                    .set(field: getLocationFieldName(field))
                                    .set(value: v)
                                    .build())
                        }
                    }
                } else if isDateField(field) {
                    if isHierarchical {
                        for vs in values {
                            let groups = vs.split(separator: "~")
                            let valueQueryBuilder = QueryBuilders.boolQuery()
                            for (idx, _) in groups.enumerated() {
                                try valueQueryBuilder.must(query: QueryBuilders.termQuery()
                                    .set(field: getDateFieldName(String(keyGroup[idx])))
                                    .set(value: String(groups[idx]))
                                    .build())
                            }
                            try dateQueryList.append(valueQueryBuilder.build())
                        }
                    } else {
                        for v in values {
                            try dateQueryList.append(
                                QueryBuilders.termQuery()
                                    .set(field: getDateFieldName(field))
                                    .set(value: v)
                                    .build())
                        }

                    }
                } else {
                    let fieldQueryBuilder = QueryBuilders.boolQuery()
                    for fieldValue in values {
                        try fieldQueryBuilder.should(query: QueryBuilders
                            .termQuery()
                            .set(field: toIndexFieldName(field))
                            .set(value: fieldValue)
                            .build())
                    }
                    try queryBuilder.must(query: fieldQueryBuilder.build())
                }
            }

            if !locationQueryList.isEmpty {
                let locationQueryBuilder = QueryBuilders.boolQuery()
                for q in locationQueryList {
                    locationQueryBuilder.should(query: q)
                }
                try queryBuilder.must(query: locationQueryBuilder.build())
            }

            if !dateQueryList.isEmpty {
                let dateQueryBuilder = QueryBuilders.boolQuery()
                for q in dateQueryList {
                    dateQueryBuilder.should(query: q)
                }
                try queryBuilder.must(query: dateQueryBuilder.build())
            }

            try builder.set(query: queryBuilder.build())
        } else {
            builder.set(query: query)
        }
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

    private func processCategories(_ aggregations: [String:AggregationResponse]?) -> [FpSearchResponse.CategoryResult] {
        var results = [FpSearchResponse.CategoryResult]()

        if let aggs = aggregations {
            for (key, item) in aggs {
                if ["keywords", "tags", "countryName", "dateYear"].contains(key) {
                    let details = processBucketCategories(item.buckets)
                    if details.count > 0 {
                        results.append(FpSearchResponse.CategoryResult(key, details))
                    }
                }
            }
        }

        return results
    }

    private func processBucketCategories(_ buckets : [AggregationBucketResponse]) -> [FpSearchResponse.CategoryDetail] {
        var details = [FpSearchResponse.CategoryDetail]()
        for b in buckets {
            if b.count == 0 {
                continue
            }

            var children = [FpSearchResponse.CategoryDetail]()
            var subField = ""
            if let subAggs = b.aggregations {
                for (subKey, subValue) in subAggs {
                    if subField.isEmpty {
                        subField = subKey
                    }
                    children += processBucketCategories(subValue.buckets)
                }
            }

            var bucketDetail = FpSearchResponse.CategoryDetail(b.key, b.count, subField)
            if children.count > 0 {
                bucketDetail.children = children
            }
            details.append(bucketDetail)
        }
        return details
    }

    private func addCategories(_ builder: SearchRequestBuilder, _ categoryOptions: FpCategoryOptions) {
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
                .add(name: "stateName", aggregation: AggregationBuilders
                    .term("locationStateName.keyword")
                    .add(name: "cityName", aggregation: AggregationBuilders
                        .term("locationCityName.keyword")
                        .add(name: "siteName", aggregation: AggregationBuilders
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
                    .add(name: "dateDay", aggregation: AggregationBuilders
                        .term("dateDay.keyword")
                        .build())
                    .build())
                .build())
        }
    }

    private func processFieldValues(_ fieldValues: SearchOptions.FieldValues,
                                    _ aggregations: [String:AggregationResponse]?) 
                                    -> [FpSearchResponse.FieldAndValues] {
        var results = [FpSearchResponse.FieldAndValues]()
        if let aggs = aggregations {
            for (key, item) in aggs {
                if fieldValues.fields.contains(key) {
                    var values = [FpSearchResponse.FieldAndValues.ValueAndCount]()
                    for b in item.buckets {
                        values.append(FpSearchResponse.FieldAndValues.ValueAndCount(b.key, b.count))
                    }

                    if values.count > 0 {
                        results.append(FpSearchResponse.FieldAndValues(key, values))
                    }
                }
            }
        }
        return results
    }

    private func addFieldValues(_ builder: SearchRequestBuilder, _ fieldValues: SearchOptions.FieldValues) {
        for field in fieldValues.fields {
            let name = toIndexFieldName(field)
            builder.add(
                name: field, 
                aggregation: AggregationBuilders.term(name).set(size: fieldValues.maxCount).build())
        }
    }

    private func isLocationField(_ name: String) -> Bool {
        return ["countryname", "statename", "cityname", "sitename"].contains(name.lowercased())
    }

    private func isDateField(_ name: String) -> Bool {
        return ["dateyear", "datemonth", "dateday"].contains(name.lowercased())
    }

    private func getLocationFieldName(_ name: String) -> String {
        switch name {
            case "countryName": return "locationCountryName.keyword"
            case "stateName": return "locationStateName.keyword"
            case "cityName": return "locationCityName.keyword"
            case "siteName": return "locationSiteName.keyword"
            default: return ""
        }
    }

    private func getDateFieldName(_ name: String) -> String {
        switch name {
            case "dateYear": return "dateYear.keyword"
            case "dateMonth": return "dateMonth.keyword"
            case "dateDay": return "dateDay.keyword"
            default: return ""
        }

    }
}
