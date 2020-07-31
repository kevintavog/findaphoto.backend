//
//  SearchRequest.swift
//  ElasticSwift
//
//  Created by Prafull Kumar Soni on 5/31/17.
//
//

// import ElasticSwiftCodableUtils
// import ElasticSwiftCore
// import ElasticSwiftQueryDSL
import Foundation
import NIOHTTP1

// MARK: - Search Request Builder

public class SearchRequestBuilder: RequestBuilder {
    public typealias RequestType = SearchRequest

    private var _indices: [String]?
    private var _types: [String]?
    private var _searchSource = SearchSource()
    private var _sourceFilter: SourceFilter?
    private var _scroll: Scroll?
    private var _searchType: SearchType?
    private var _preference: String?

    public init() {}

    @discardableResult
    public func set(indices: String...) -> Self {
        _indices = indices
        return self
    }

    @discardableResult
    public func set(indices: [String]) -> Self {
        _indices = indices
        return self
    }

    @discardableResult
    public func set(types: String...) -> Self {
        _types = types
        return self
    }

    @discardableResult
    public func set(types: [String]) -> Self {
        _types = types
        return self
    }

    @discardableResult
    public func set(searchSource: SearchSource) -> Self {
        _searchSource = searchSource
        return self
    }

@discardableResult
public func set(trackTotalHits: Bool) -> Self {
    _searchSource.trackTotalHits = trackTotalHits
    return self
}

    @discardableResult
    public func set(from: Int) -> Self {
        _searchSource.from = from
        return self
    }

    @discardableResult
    public func set(size: Int) -> Self {
        _searchSource.size = size
        return self
    }

    @discardableResult
    public func set(query: Query) -> Self {
        _searchSource.query = query
        return self
    }

    @discardableResult
    public func set(postFilter: Query) -> Self {
        _searchSource.postFilter = postFilter
        return self
    }

    @discardableResult
    public func set(sorts: [Sort]) -> Self {
        _searchSource.sorts = sorts
        return self
    }

    @discardableResult
    public func set(sourceFilter: SourceFilter) -> Self {
        _searchSource.sourceFilter = sourceFilter
        return self
    }

    @discardableResult
    public func set(explain: Bool) -> Self {
        _searchSource.explain = explain
        return self
    }

    @discardableResult
    public func set(minScore: Decimal) -> Self {
        _searchSource.minScore = minScore
        return self
    }

    @discardableResult
    public func set(scroll: Scroll) -> Self {
        _scroll = scroll
        return self
    }

    @discardableResult
    public func set(searchType: SearchType) -> Self {
        _searchType = searchType
        return self
    }

    @discardableResult
    public func set(trackScores: Bool) -> Self {
        _searchSource.trackScores = trackScores
        return self
    }

    @discardableResult
    public func set(indicesBoost: [IndexBoost]) -> Self {
        _searchSource.indicesBoost = indicesBoost
        return self
    }

    @discardableResult
    public func set(preference: String) -> Self {
        _preference = preference
        return self
    }

    @discardableResult
    public func set(version: Bool) -> Self {
        _searchSource.version = version
        return self
    }

    @discardableResult
    public func set(seqNoPrimaryTerm: Bool) -> Self {
        _searchSource.seqNoPrimaryTerm = seqNoPrimaryTerm
        return self
    }

    @discardableResult
    public func set(scriptFields: [ScriptField]) -> Self {
        _searchSource.scriptFields = scriptFields
        return self
    }

    @discardableResult
    public func set(docvalueFields: [DocValueField]) -> Self {
        _searchSource.docvalueFields = docvalueFields
        return self
    }

    @discardableResult
    public func set(rescore: [QueryRescorer]) -> Self {
        _searchSource.rescore = rescore
        return self
    }

    @discardableResult
    public func set(searchAfter: CodableValue) -> Self {
        _searchSource.searchAfter = searchAfter
        return self
    }

    @discardableResult
    public func add(sort: Sort) -> Self {
        if _searchSource.sorts != nil {
            _searchSource.sorts?.append(sort)
        } else {
            _searchSource.sorts = [sort]
        }
        return self
    }

    @discardableResult
    public func add(indexBoost: IndexBoost) -> Self {
        if _searchSource.indicesBoost != nil {
            _searchSource.indicesBoost?.append(indexBoost)
        } else {
            _searchSource.indicesBoost = [indexBoost]
        }
        return self
    }

    @discardableResult
    public func add(scriptField: ScriptField) -> Self {
        if _searchSource.scriptFields != nil {
            _searchSource.scriptFields?.append(scriptField)
        } else {
            _searchSource.scriptFields = [scriptField]
        }
        return self
    }

    @discardableResult
    public func add(docvalueField: DocValueField) -> Self {
        if _searchSource.docvalueFields != nil {
            _searchSource.docvalueFields?.append(docvalueField)
        } else {
            _searchSource.docvalueFields = [docvalueField]
        }
        return self
    }

    @discardableResult
    public func add(rescore: QueryRescorer) -> Self {
        if _searchSource.rescore != nil {
            _searchSource.rescore?.append(rescore)
        } else {
            _searchSource.rescore = [rescore]
        }
        return self
    }

    @discardableResult
    public func set(storedFields: String...) -> Self {
        _searchSource.storedFields = storedFields
        return self
    }

    @discardableResult
    public func set(storedFields: [String]) -> Self {
        _searchSource.storedFields = storedFields
        return self
    }

    @discardableResult
    public func set(highlight: Highlight) -> Self {
        _searchSource.highlight = highlight
        return self
    }

    @discardableResult
    public func add(index: String) -> Self {
        if _indices != nil {
            _indices?.append(index)
        } else {
            _indices = [index]
        }
        return self
    }

    @discardableResult
    public func add(type: String) -> Self {
        if _types != nil {
            _types?.append(type)
        } else {
            _types = [type]
        }
        return self
    }

    public var indices: [String]? {
        return _indices
    }

    public var types: [String]? {
        return _types
    }

    public var searchSource: SearchSource {
        return _searchSource
    }

    public var sourceFilter: SourceFilter? {
        return _sourceFilter
    }

    public var scroll: Scroll? {
        return _scroll
    }

    public var searchType: SearchType? {
        return _searchType
    }

    public var preference: String? {
        return _preference
    }

    public func build() throws -> SearchRequest {
        return try SearchRequest(withBuilder: self)
    }
}

// MARK: - Search Request

public struct SearchRequest: Request {
    public var headers: HTTPHeaders = HTTPHeaders()

    public let indices: [String]?
    public let types: [String]?
    public let searchSource: SearchSource?

    public var scroll: Scroll?
    public var searchType: SearchType?
    public var preference: String?

    public init(indices: [String]?, types: [String]?, searchSource: SearchSource?, scroll: Scroll? = nil, searchType: SearchType? = nil, preference: String? = nil) {
        self.indices = indices
        self.types = types
        self.searchSource = searchSource
        self.scroll = scroll
        self.searchType = searchType
        self.preference = preference
    }

    public init(indices: [String]? = nil, types: [String]? = nil, query: Query? = nil, from: Int? = nil, size: Int? = nil, sorts: [Sort]? = nil, sourceFilter: SourceFilter? = nil, explain: Bool? = nil, minScore: Decimal? = nil, scroll: Scroll? = nil, trackScores: Bool? = nil, indicesBoost: [IndexBoost]? = nil, searchType: SearchType? = nil, seqNoPrimaryTerm: Bool? = nil, version: Bool? = nil, preference: String? = nil, scriptFields: [ScriptField]? = nil, storedFields: [String]? = nil, docvalueFields: [DocValueField]? = nil, postFilter: Query? = nil, highlight: Highlight? = nil, rescore: [QueryRescorer]? = nil, searchAfter: CodableValue? = nil) {
        var searchSource = SearchSource()
        searchSource.query = query
        searchSource.postFilter = postFilter
        searchSource.from = from
        searchSource.size = size
        searchSource.sorts = sorts
        searchSource.sourceFilter = sourceFilter
        searchSource.explain = explain
        searchSource.minScore = minScore
        searchSource.trackScores = trackScores
        searchSource.indicesBoost = indicesBoost
        searchSource.docvalueFields = docvalueFields
        searchSource.highlight = highlight
        searchSource.rescore = rescore
        searchSource.searchAfter = searchAfter
        searchSource.seqNoPrimaryTerm = seqNoPrimaryTerm
        searchSource.scriptFields = scriptFields
        searchSource.storedFields = storedFields
        searchSource.version = version
        self.init(indices: indices, types: types, searchSource: searchSource, scroll: scroll, searchType: searchType, preference: preference)
    }

    public init(indices: String..., types: [String]? = nil, query: Query? = nil, from: Int? = nil, size: Int? = nil, sorts: [Sort]? = nil, sourceFilter: SourceFilter? = nil, explain: Bool? = nil, minScore: Decimal? = nil, scroll: Scroll? = nil, trackScores: Bool? = nil, indicesBoost: [IndexBoost]? = nil, searchType: SearchType? = nil, seqNoPrimaryTerm: Bool? = nil, version: Bool? = nil, preference: String? = nil, scriptFields: [ScriptField]? = nil, storedFields: [String]? = nil, docvalueFields: [DocValueField]? = nil, postFilter: Query? = nil, highlight: Highlight? = nil, rescore: [QueryRescorer]? = nil, searchAfter: CodableValue? = nil) {
        self.init(indices: indices, types: types, query: query, from: from, size: size, sorts: sorts, sourceFilter: sourceFilter, explain: explain, minScore: minScore, scroll: scroll, trackScores: trackScores, indicesBoost: indicesBoost, searchType: searchType, seqNoPrimaryTerm: seqNoPrimaryTerm, version: version, preference: preference, scriptFields: scriptFields, storedFields: storedFields, docvalueFields: docvalueFields, postFilter: postFilter, highlight: highlight, rescore: rescore, searchAfter: searchAfter)
    }

    internal init(withBuilder builder: SearchRequestBuilder) throws {
        self.init(indices: builder.indices, types: builder.types, searchSource: builder.searchSource, scroll: builder.scroll, searchType: builder.searchType, preference: builder.preference)
    }

    public var method: HTTPMethod {
        return .POST
    }

    public var endPoint: String {
        var _endPoint = "_search"
        if let types = self.types, !types.isEmpty {
            _endPoint = types.joined(separator: ",") + "/" + _endPoint
        }
        if let indices = self.indices, !indices.isEmpty {
            _endPoint = indices.joined(separator: ",") + "/" + _endPoint
        }
        return _endPoint
    }

    public var queryParams: [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        if let scroll = self.scroll {
            queryItems.append(URLQueryItem(name: QueryParams.scroll, value: scroll.keepAlive))
        }
        if let searchType = self.searchType {
            queryItems.append(URLQueryItem(name: QueryParams.searchType, value: searchType.rawValue))
        }
        if let preference = self.preference {
            queryItems.append(URLQueryItem(name: QueryParams.preference, value: preference))
        }
        return queryItems
    }

    public func makeBody(_ serializer: Serializer) -> Result<Data, MakeBodyError> {
        if let body = searchSource {
            return serializer.encode(body).mapError { error -> MakeBodyError in
                MakeBodyError.wrapped(error)
            }
        }
        return .failure(.noBodyForRequest)
    }
}

extension SearchRequest: Equatable {}

public struct ScriptField {
    public let field: String
    public let script: Script
}

extension ScriptField: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        var nested = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: field))
        try nested.encode(script, forKey: .script)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        guard container.allKeys.count == 1 else {
            throw Swift.DecodingError.typeMismatch(ScriptField.self, .init(codingPath: container.codingPath, debugDescription: "Unable to find field name in key(s) expect: 1 key found: \(container.allKeys.count)."))
        }

        field = container.allKeys.first!.stringValue
        let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: field))
        script = try nested.decode(Script.self, forKey: .script)
    }

    enum CodingKeys: String, CodingKey {
        case script
    }
}

extension ScriptField: Equatable {}

public struct DocValueField: Codable {
    public let field: String
    public let format: String
}

extension DocValueField: Equatable {}

/// Struct representing Index boost
public struct IndexBoost {
    public let index: String
    public let boost: Decimal
}

extension IndexBoost: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encode(boost, forKey: .key(named: index))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dic = try container.decode([String: Decimal].self)
        if dic.isEmpty || dic.count > 1 {
            throw Swift.DecodingError.dataCorruptedError(in: container, debugDescription: "Unexpected data found \(dic)")
        }
        index = dic.first!.key
        boost = dic.first!.value
    }
}

extension IndexBoost: Equatable {}

// MARK: - Scroll

public struct Scroll: Codable {
    public let keepAlive: String

    public init(keepAlive: String) {
        self.keepAlive = keepAlive
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(keepAlive)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        keepAlive = try container.decodeString()
    }

    public static var ONE_MINUTE: Scroll {
        return Scroll(keepAlive: "1m")
    }
}

extension Scroll: Equatable {}

// MARK: - Search Scroll Request Builder

public class SearchScrollRequestBuilder: RequestBuilder {
    public typealias RequestType = SearchScrollRequest

    private var _scrollId: String?
    private var _scroll: Scroll?
    private var _restTotalHitsAsInt: Bool?

    public init() {}

    @discardableResult
    public func set(scrollId: String) -> Self {
        _scrollId = scrollId
        return self
    }

    @discardableResult
    public func set(scroll: Scroll) -> Self {
        _scroll = scroll
        return self
    }

    @discardableResult
    public func set(restTotalHitsAsInt: Bool) -> Self {
        _restTotalHitsAsInt = restTotalHitsAsInt
        return self
    }

    public var scrollId: String? {
        return _scrollId
    }

    public var scroll: Scroll? {
        return _scroll
    }

    public var restTotalHitsAsInt: Bool? {
        return _restTotalHitsAsInt
    }

    public func build() throws -> SearchScrollRequest {
        return try SearchScrollRequest(withBuilder: self)
    }
}

// MARK: - Search Scroll Request

public struct SearchScrollRequest: Request {
    public let scrollId: String
    public let scroll: Scroll?

    public var restTotalHitsAsInt: Bool?

    public init(scrollId: String, scroll: Scroll?) {
        self.scrollId = scrollId
        self.scroll = scroll
    }

    internal init(withBuilder builder: SearchScrollRequestBuilder) throws {
        guard builder.scrollId != nil else {
            throw RequestBuilderError.missingRequiredField("scrollId")
        }

        scrollId = builder.scrollId!
        scroll = builder.scroll
        restTotalHitsAsInt = builder.restTotalHitsAsInt
    }

    public var headers: HTTPHeaders {
        return HTTPHeaders()
    }

    public var queryParams: [URLQueryItem] {
        var params = [URLQueryItem]()
        if let totalHitsAsInt = restTotalHitsAsInt {
            params.append(URLQueryItem(name: QueryParams.restTotalHitsAsInt, value: totalHitsAsInt))
        }
        return params
    }

    public var method: HTTPMethod {
        return .POST
    }

    public var endPoint: String {
        return "_search/scroll"
    }

    public func makeBody(_ serializer: Serializer) -> Result<Data, MakeBodyError> {
        let body = Body(scroll: scroll, scrollId: scrollId)
        return serializer.encode(body).mapError { error -> MakeBodyError in
            .wrapped(error)
        }
    }

    private struct Body: Encodable {
        public let scroll: Scroll?
        public let scrollId: String

        enum CodingKeys: String, CodingKey {
            case scroll
            case scrollId = "scroll_id"
        }
    }
}

extension SearchScrollRequest: Equatable {}

// MARK: - Clear Scroll Request Builder

public class ClearScrollRequestBuilder: RequestBuilder {
    public typealias RequestType = ClearScrollRequest

    private var _scrollIds: [String] = []

    public init() {}

    @discardableResult
    public func set(scrollIds: String...) -> Self {
        _scrollIds = scrollIds
        return self
    }

    public var scrollIds: [String] {
        return _scrollIds
    }

    public func build() throws -> ClearScrollRequest {
        return try ClearScrollRequest(withBuilder: self)
    }
}

// MARK: - Clear Scroll Request

public struct ClearScrollRequest: Request {
    public let scrollIds: [String]

    public init(scrollId: String) {
        self.init(scrollIds: [scrollId])
    }

    public init(scrollIds: [String]) {
        self.scrollIds = scrollIds
    }

    internal init(withBuilder builder: ClearScrollRequestBuilder) throws {
        guard !builder.scrollIds.isEmpty else {
            throw RequestBuilderError.atlestOneElementRequired("scrollIds")
        }

        if builder.scrollIds.contains("_all") {
            scrollIds = ["_all"]
        } else {
            scrollIds = builder.scrollIds
        }
    }

    public var headers: HTTPHeaders {
        return HTTPHeaders()
    }

    public var queryParams: [URLQueryItem] {
        return []
    }

    public var method: HTTPMethod {
        return .DELETE
    }

    public var endPoint: String {
        if scrollIds.contains("_all") {
            return "_search/scroll/_all"
        } else {
            return "_search/scroll"
        }
    }

    public func makeBody(_ serializer: Serializer) -> Result<Data, MakeBodyError> {
        if scrollIds.contains("_all") {
            return .failure(.noBodyForRequest)
        } else {
            let body = Body(scrollId: scrollIds)
            return serializer.encode(body).mapError { error -> MakeBodyError in
                MakeBodyError.wrapped(error)
            }
        }
    }

    private struct Body: Codable, Equatable {
        public let scrollId: [String]

        public init(scrollId: [String]) {
            self.scrollId = scrollId
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do {
                let id = try container.decodeString(forKey: .scrollId)
                scrollId = [id]
            } catch Swift.DecodingError.typeMismatch {
                scrollId = try container.decodeArray(forKey: .scrollId)
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if scrollId.count == 1 {
                try container.encode(scrollId.first!, forKey: .scrollId)
            } else {
                try container.encode(scrollId, forKey: .scrollId)
            }
        }

        enum CodingKeys: String, CodingKey {
            case scrollId = "scroll_id"
        }
    }
}

extension ClearScrollRequest: Equatable {}

// MARK: - Search Type

/// Search type represent the manner at which the search operation is executed.
public enum SearchType: String, Codable {
    /// Same as [queryThenFetch](x-source-tag://queryThenFetch), except for an initial scatter phase which goes and computes the distributed
    /// term frequencies for more accurate scoring.
    case dfsQueryThenFetch = "dfs_query_then_fetch"
    /// The query is executed against all shards, but only enough information is returned (not the document content).
    /// The results are then sorted and ranked, and based on it, only the relevant shards are asked for the actual
    /// document content. The return number of hits is exactly as specified in size, since they are the only ones that
    /// are fetched. This is very handy when the index has a lot of shards (not replicas, shard id groups).
    /// - Tag: `queryThenFetch`
    case queryThenFetch = "query_then_fetch"

    /// Only used for pre 5.3 request where this type is still needed
    @available(*, deprecated, message: "Only used for pre 5.3 request where this type is still needed")
    case queryAndFetch = "query_and_fetch"

    /// The default search type [queryThenFetch](x-source-tag://queryThenFetch)
    public static let DEFAULT = SearchType.queryThenFetch
}

// MARK: - Source Filtering

public enum SourceFilter {
    case fetchSource(Bool)
    case filter(String)
    case filters([String])
    case source(includes: [String], excludes: [String])
}

extension SourceFilter: Codable {
    enum CodingKeys: String, CodingKey {
        case includes
        case excludes
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .fetchSource(value):
            var contianer = encoder.singleValueContainer()
            try contianer.encode(value)
        case let .filter(value):
            var contianer = encoder.singleValueContainer()
            try contianer.encode(value)
        case let .filters(values):
            var contianer = encoder.unkeyedContainer()
            try contianer.encode(contentsOf: values)
        case let .source(includes, excludes):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(includes, forKey: .includes)
            try container.encode(excludes, forKey: .excludes)
        }
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            let includes: [String] = try container.decodeArray(forKey: .includes)
            let excludes: [String] = try container.decodeArray(forKey: .excludes)
            self = .source(includes: includes, excludes: excludes)
        } else if var contianer = try? decoder.unkeyedContainer() {
            let values: [String] = try contianer.decodeArray()
            self = .filters(values)
        } else {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decodeString() {
                self = .filter(value)
            } else {
                let value = try container.decodeBool()
                self = .fetchSource(value)
            }
        }
    }
}

extension SourceFilter: Equatable {}

// MARK: - Highlighting

public class HighlightBuilder {
    private var _fields: [Highlight.Field]?
    private var _globalOptions: Highlight.FieldOptions?

    @discardableResult
    public func set(fields: [Highlight.Field]) -> Self {
        _fields = fields
        return self
    }

    @discardableResult
    public func set(globalOptions: Highlight.FieldOptions) -> Self {
        _globalOptions = globalOptions
        return self
    }

    @discardableResult
    public func add(field: Highlight.Field) -> Self {
        if _fields != nil {
            _fields?.append(field)
        } else {
            _fields = [field]
        }
        return self
    }

    public var fields: [Highlight.Field]? {
        return _fields
    }

    public var globalOptions: Highlight.FieldOptions? {
        return _globalOptions
    }

    public func build() throws -> Highlight {
        return try Highlight(withBuilder: self)
    }
}

public class FieldOptionsBuilder {
    private var _fragmentSize: Int?
    private var _numberOfFragments: Int?
    private var _fragmentOffset: Int?
    private var _encoder: Highlight.EncoderType?
    private var _preTags: [String]?
    private var _postTags: [String]?
    private var _scoreOrdered: Bool?
    private var _requireFieldMatch: Bool?
    private var _highlighterType: Highlight.HighlighterType?
    private var _forceSource: Bool?
    private var _fragmenter: String?
    private var _boundaryScannerType: Highlight.BoundaryScannerType?
    private var _boundaryMaxScan: Int?
    private var _boundaryChars: [Character]?
    private var _boundaryScannerLocale: String?
    private var _highlightQuery: Query?
    private var _noMatchSize: Int?
    private var _matchedFields: [String]?
    private var _phraseLimit: Int?
    private var _tagScheme: String?
    private var _termVector: String?
    private var _indexOptions: String?

    public init() {}

    @discardableResult
    public func set(fragmentSize: Int) -> Self {
        _fragmentSize = fragmentSize
        return self
    }

    @discardableResult
    public func set(numberOfFragments: Int) -> Self {
        _numberOfFragments = numberOfFragments
        return self
    }

    @discardableResult
    public func set(fragmentOffset: Int) -> Self {
        _fragmentOffset = fragmentOffset
        return self
    }

    @discardableResult
    public func set(encoder: Highlight.EncoderType) -> Self {
        _encoder = encoder
        return self
    }

    @discardableResult
    public func set(preTags: [String]) -> Self {
        _preTags = preTags
        return self
    }

    @discardableResult
    public func set(postTags: [String]) -> Self {
        _postTags = postTags
        return self
    }

    @discardableResult
    public func set(scoreOrdered: Bool) -> Self {
        _scoreOrdered = scoreOrdered
        return self
    }

    @discardableResult
    public func set(requireFieldMatch: Bool) -> Self {
        _requireFieldMatch = requireFieldMatch
        return self
    }

    @discardableResult
    public func set(highlighterType: Highlight.HighlighterType) -> Self {
        _highlighterType = highlighterType
        return self
    }

    @discardableResult
    public func set(forceSource: Bool) -> Self {
        _forceSource = forceSource
        return self
    }

    @discardableResult
    public func set(fragmenter: String) -> Self {
        _fragmenter = fragmenter
        return self
    }

    @discardableResult
    public func set(boundaryScannerType: Highlight.BoundaryScannerType) -> Self {
        _boundaryScannerType = boundaryScannerType
        return self
    }

    @discardableResult
    public func set(boundaryMaxScan: Int) -> Self {
        _boundaryMaxScan = boundaryMaxScan
        return self
    }

    @discardableResult
    public func set(boundaryChars: [Character]) -> Self {
        _boundaryChars = boundaryChars
        return self
    }

    @discardableResult
    public func set(boundaryScannerLocale: String) -> Self {
        _boundaryScannerLocale = boundaryScannerLocale
        return self
    }

    @discardableResult
    public func set(highlightQuery: Query) -> Self {
        _highlightQuery = highlightQuery
        return self
    }

    @discardableResult
    public func set(noMatchSize: Int) -> Self {
        _noMatchSize = noMatchSize
        return self
    }

    @discardableResult
    public func set(matchedFields: [String]) -> Self {
        _matchedFields = matchedFields
        return self
    }

    @discardableResult
    public func set(phraseLimit: Int) -> Self {
        _phraseLimit = phraseLimit
        return self
    }

    @discardableResult
    public func set(tagScheme: String) -> Self {
        _tagScheme = tagScheme
        return self
    }

    @discardableResult
    public func set(termVector: String) -> Self {
        _termVector = termVector
        return self
    }

    @discardableResult
    public func set(indexOptions: String) -> Self {
        _indexOptions = indexOptions
        return self
    }

    public var fragmentSize: Int? {
        return _fragmentSize
    }

    public var numberOfFragments: Int? {
        return _numberOfFragments
    }

    public var fragmentOffset: Int? {
        return _fragmentOffset
    }

    public var encoder: Highlight.EncoderType? {
        return _encoder
    }

    public var preTags: [String]? {
        return _preTags
    }

    public var postTags: [String]? {
        return _postTags
    }

    public var scoreOrdered: Bool? {
        return _scoreOrdered
    }

    public var requireFieldMatch: Bool? {
        return _requireFieldMatch
    }

    public var highlighterType: Highlight.HighlighterType? {
        return _highlighterType
    }

    public var forceSource: Bool? {
        return _forceSource
    }

    public var fragmenter: String? {
        return _fragmenter
    }

    public var boundaryScannerType: Highlight.BoundaryScannerType? {
        return _boundaryScannerType
    }

    public var boundaryMaxScan: Int? {
        return _boundaryMaxScan
    }

    public var boundaryChars: [Character]? {
        return _boundaryChars
    }

    public var boundaryScannerLocale: String? {
        return _boundaryScannerLocale
    }

    public var highlightQuery: Query? {
        return _highlightQuery
    }

    public var noMatchSize: Int? {
        return _noMatchSize
    }

    public var matchedFields: [String]? {
        return _matchedFields
    }

    public var phraseLimit: Int? {
        return _phraseLimit
    }

    public var tagScheme: String? {
        return _tagScheme
    }

    public var termVector: String? {
        return _termVector
    }

    public var indexOptions: String? {
        return _indexOptions
    }

    public func build() -> Highlight.FieldOptions {
        return Highlight.FieldOptions(withBuilder: self)
    }
}

public struct Highlight {
    public let fields: [Field]
    public let globalOptions: FieldOptions

    public init(fields: [Field], globalOptions: FieldOptions = FieldOptions()) {
        self.fields = fields
        self.globalOptions = globalOptions
    }

    internal init(withBuilder builder: HighlightBuilder) throws {
        guard builder.fields != nil, !builder.fields!.isEmpty else {
            throw RequestBuilderError.atlestOneElementRequired("fields")
        }

        self.init(fields: builder.fields!, globalOptions: builder.globalOptions ?? FieldOptions())
    }
}

extension Highlight: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fields, forKey: .fields)
        try container.encodeIfPresent(globalOptions.boundaryChars?.map { String($0) }, forKey: .boundaryChars)
        try container.encodeIfPresent(globalOptions.boundaryMaxScan, forKey: .boundaryMaxScan)
        try container.encodeIfPresent(globalOptions.boundaryScannerType, forKey: .boundaryScannerType)
        try container.encodeIfPresent(globalOptions.boundaryScannerLocale, forKey: .boundaryScannerLocale)
        try container.encodeIfPresent(globalOptions.encoder, forKey: .encoder)
        try container.encodeIfPresent(globalOptions.forceSource, forKey: .forceSource)
        try container.encodeIfPresent(globalOptions.fragmenter, forKey: .fragmenter)
        try container.encodeIfPresent(globalOptions.fragmentOffset, forKey: .fragmentOffset)
        try container.encodeIfPresent(globalOptions.fragmentSize, forKey: .fragmentSize)
        try container.encodeIfPresent(globalOptions.highlightQuery, forKey: .highlightQuery)
        try container.encodeIfPresent(globalOptions.matchedFields, forKey: .matchedFields)
        try container.encodeIfPresent(globalOptions.numberOfFragments, forKey: .numberOfFragments)
        try container.encodeIfPresent((globalOptions.scoreOrdered ?? false) ? Highlight.FieldOptions.SCORE_ORDERER_VALUE : nil, forKey: .order)
        try container.encodeIfPresent(globalOptions.phraseLimit, forKey: .phraseLimit)
        try container.encodeIfPresent(globalOptions.preTags, forKey: .preTags)
        try container.encodeIfPresent(globalOptions.postTags, forKey: .postTags)
        try container.encodeIfPresent(globalOptions.requireFieldMatch, forKey: .requireFieldMatch)
        try container.encodeIfPresent(globalOptions.tagScheme, forKey: .tagsSchema)
        try container.encodeIfPresent(globalOptions.highlighterType, forKey: .type)
        try container.encodeIfPresent(globalOptions.termVector, forKey: .termVector)
        try container.encodeIfPresent(globalOptions.indexOptions, forKey: .indexOptions)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fields = try container.decodeArray(forKey: .fields)
        var options = FieldOptions()
        let chars: [String]? = try container.decodeArrayIfPresent(forKey: .boundaryChars)
        if let chars = chars {
            var charArr = [Character]()
            for char in chars {
                charArr.append(contentsOf: [Character](char))
            }
            options.boundaryChars = charArr
        } else {
            options.boundaryChars = nil
        }
        options.boundaryMaxScan = try container.decodeIntIfPresent(forKey: .boundaryMaxScan)
        options.boundaryScannerType = try container.decodeIfPresent(Highlight.BoundaryScannerType.self, forKey: .boundaryScannerType)
        options.boundaryScannerLocale = try container.decodeStringIfPresent(forKey: .boundaryScannerLocale)
        options.encoder = try container.decodeIfPresent(Highlight.EncoderType.self, forKey: .encoder)
        options.forceSource = try container.decodeBoolIfPresent(forKey: .forceSource)
        options.fragmenter = try container.decodeStringIfPresent(forKey: .fragmenter)
        options.fragmentOffset = try container.decodeIntIfPresent(forKey: .fragmentOffset)
        options.fragmentSize = try container.decodeIntIfPresent(forKey: .fragmentSize)
        options.highlightQuery = try container.decodeQueryIfPresent(forKey: .highlightQuery)
        options.matchedFields = try container.decodeArray(forKey: .matchedFields)
        options.noMatchSize = try container.decodeIntIfPresent(forKey: .noMatchSize)
        options.numberOfFragments = try container.decodeIntIfPresent(forKey: .numberOfFragments)
        let order = try container.decodeStringIfPresent(forKey: .order)
        if let order = order {
            switch order {
            case Highlight.FieldOptions.SCORE_ORDERER_VALUE:
                options.scoreOrdered = true
            default:
                options.scoreOrdered = false
            }
        } else {
            options.scoreOrdered = nil
        }
        options.phraseLimit = try container.decodeIntIfPresent(forKey: .phraseLimit)
        options.preTags = try container.decodeArray(forKey: .preTags)
        options.postTags = try container.decodeArray(forKey: .postTags)
        options.requireFieldMatch = try container.decodeBoolIfPresent(forKey: .requireFieldMatch)
        options.tagScheme = try container.decodeStringIfPresent(forKey: .tagsSchema)
        options.highlighterType = try container.decodeIfPresent(Highlight.HighlighterType.self, forKey: .type)
        options.termVector = try container.decodeStringIfPresent(forKey: .termVector)
        options.indexOptions = try container.decodeStringIfPresent(forKey: .indexOptions)
        globalOptions = options
    }

    enum CodingKeys: String, CodingKey {
        case fields
        case boundaryChars = "boundary_chars"
        case boundaryMaxScan = "boundary_max_scan"
        case boundaryScannerType = "boundary_scanner"
        case boundaryScannerLocale = "boundary_scanner_locale"
        case encoder
        case forceSource = "force_source"
        case fragmenter
        case fragmentOffset = "fragment_offset"
        case fragmentSize = "fragment_size"
        case highlightQuery = "highlight_query"
        case matchedFields = "matched_fields"
        case noMatchSize = "no_match_size"
        case numberOfFragments = "number_of_fragments"
        case order
        case phraseLimit = "phrase_limit"
        case preTags = "pre_tags"
        case postTags = "post_tags"
        case requireFieldMatch = "require_field_match"
        case tagsSchema = "tags_schema"
        case type
        case termVector = "term_vector"
        case indexOptions = "index_options"
    }
}

extension Highlight: Equatable {}

extension Highlight {
    public struct Field {
        public let name: String
        public let options: FieldOptions

        public init(_ name: String, options: FieldOptions = FieldOptions()) {
            self.name = name
            self.options = options
        }
    }

    public struct FieldOptions {
        fileprivate static let SCORE_ORDERER_VALUE = "score"

        public var fragmentSize: Int?
        public var numberOfFragments: Int?
        public var fragmentOffset: Int?
        public var encoder: EncoderType?
        public var preTags: [String]?
        public var postTags: [String]?
        public var scoreOrdered: Bool?
        public var requireFieldMatch: Bool?
        public var highlighterType: HighlighterType?
        public var forceSource: Bool?
        public var fragmenter: String?
        public var boundaryScannerType: BoundaryScannerType?
        public var boundaryMaxScan: Int?
        public var boundaryChars: [Character]?
        public var boundaryScannerLocale: String?
        public var highlightQuery: Query?
        public var noMatchSize: Int?
        public var matchedFields: [String]?
        public var phraseLimit: Int?
        public var tagScheme: String?
        public var termVector: String?
        public var indexOptions: String?

        public init() {}

        internal init(withBuilder builder: FieldOptionsBuilder) {
            fragmentSize = builder.fragmentSize
            numberOfFragments = builder.numberOfFragments
            fragmentOffset = builder.fragmentOffset
            encoder = builder.encoder
            preTags = builder.preTags
            postTags = builder.postTags
            scoreOrdered = builder.scoreOrdered
            requireFieldMatch = builder.requireFieldMatch
            highlighterType = builder.highlighterType
            forceSource = builder.forceSource
            fragmenter = builder.fragmenter
            boundaryScannerType = builder.boundaryScannerType
            boundaryMaxScan = builder.boundaryMaxScan
            boundaryChars = builder.boundaryChars
            boundaryScannerLocale = builder.boundaryScannerLocale
            highlightQuery = builder.highlightQuery
            noMatchSize = builder.noMatchSize
            matchedFields = builder.matchedFields
            phraseLimit = builder.phraseLimit
            tagScheme = builder.tagScheme
            termVector = builder.termVector
            indexOptions = builder.indexOptions
        }
    }

    public enum BoundaryScannerType: String, Codable {
        case chars
        case word
        case sentence
    }

    public enum EncoderType: String, Codable {
        case `default`
        case html
    }

    public enum HighlighterType: String, Codable {
        case unified
        case plain
        case fvh
    }
}

extension Highlight.Field: Codable {
    public func encode(to encoder: Swift.Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encodeIfPresent(options, forKey: .key(named: name))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        guard container.allKeys.count == 1 else {
            throw Swift.DecodingError.typeMismatch(Highlight.Field.self, .init(codingPath: container.codingPath, debugDescription: "Unable to find field name in key(s) expect: 1 key found: \(container.allKeys.count)."))
        }

        let field = container.allKeys.first!.stringValue

        options = try container.decode(Highlight.FieldOptions.self, forKey: .key(named: field))
        name = field
    }
}

extension Highlight.Field: Equatable {}

extension Highlight.FieldOptions: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(boundaryChars?.map { String($0) }, forKey: .boundaryChars)
        try container.encodeIfPresent(boundaryMaxScan, forKey: .boundaryMaxScan)
        try container.encodeIfPresent(boundaryScannerType, forKey: .boundaryScannerType)
        try container.encodeIfPresent(boundaryScannerLocale, forKey: .boundaryScannerLocale)
        try container.encodeIfPresent(self.encoder, forKey: .encoder)
        try container.encodeIfPresent(forceSource, forKey: .forceSource)
        try container.encodeIfPresent(fragmenter, forKey: .fragmenter)
        try container.encodeIfPresent(fragmentOffset, forKey: .fragmentOffset)
        try container.encodeIfPresent(fragmentSize, forKey: .fragmentSize)
        try container.encodeIfPresent(highlightQuery, forKey: .highlightQuery)
        try container.encodeIfPresent(matchedFields, forKey: .matchedFields)
        try container.encodeIfPresent(numberOfFragments, forKey: .numberOfFragments)
        try container.encodeIfPresent((scoreOrdered ?? false) ? Highlight.FieldOptions.SCORE_ORDERER_VALUE : nil, forKey: .order)
        try container.encodeIfPresent(phraseLimit, forKey: .phraseLimit)
        try container.encodeIfPresent(preTags, forKey: .preTags)
        try container.encodeIfPresent(postTags, forKey: .postTags)
        try container.encodeIfPresent(requireFieldMatch, forKey: .requireFieldMatch)
        try container.encodeIfPresent(tagScheme, forKey: .tagsSchema)
        try container.encodeIfPresent(highlighterType, forKey: .type)
        try container.encodeIfPresent(termVector, forKey: .termVector)
        try container.encodeIfPresent(indexOptions, forKey: .indexOptions)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let chars: [String]? = try container.decodeArrayIfPresent(forKey: .boundaryChars)
        if let chars = chars {
            var charArr = [Character]()
            for char in chars {
                charArr.append(contentsOf: [Character](char))
            }
            boundaryChars = charArr
        } else {
            boundaryChars = nil
        }
        boundaryMaxScan = try container.decodeIntIfPresent(forKey: .boundaryMaxScan)
        boundaryScannerType = try container.decodeIfPresent(Highlight.BoundaryScannerType.self, forKey: .boundaryScannerType)
        boundaryScannerLocale = try container.decodeStringIfPresent(forKey: .boundaryScannerLocale)
        encoder = try container.decodeIfPresent(Highlight.EncoderType.self, forKey: .encoder)
        forceSource = try container.decodeBoolIfPresent(forKey: .forceSource)
        fragmenter = try container.decodeStringIfPresent(forKey: .fragmenter)
        fragmentOffset = try container.decodeIntIfPresent(forKey: .fragmentOffset)
        fragmentSize = try container.decodeIntIfPresent(forKey: .fragmentSize)
        highlightQuery = try container.decodeQueryIfPresent(forKey: .highlightQuery)
        matchedFields = try container.decodeArray(forKey: .matchedFields)
        noMatchSize = try container.decodeIntIfPresent(forKey: .noMatchSize)
        numberOfFragments = try container.decodeIntIfPresent(forKey: .numberOfFragments)
        let order = try container.decodeStringIfPresent(forKey: .order)
        if let order = order {
            switch order {
            case Highlight.FieldOptions.SCORE_ORDERER_VALUE:
                scoreOrdered = true
            default:
                scoreOrdered = false
            }
        } else {
            scoreOrdered = nil
        }
        phraseLimit = try container.decodeIntIfPresent(forKey: .phraseLimit)
        preTags = try container.decodeArray(forKey: .preTags)
        postTags = try container.decodeArray(forKey: .postTags)
        requireFieldMatch = try container.decodeBoolIfPresent(forKey: .requireFieldMatch)
        tagScheme = try container.decodeStringIfPresent(forKey: .tagsSchema)
        highlighterType = try container.decodeIfPresent(Highlight.HighlighterType.self, forKey: .type)
        termVector = try container.decodeStringIfPresent(forKey: .termVector)
        indexOptions = try container.decodeStringIfPresent(forKey: .indexOptions)
    }

    enum CodingKeys: String, CodingKey {
        case boundaryChars = "boundary_chars"
        case boundaryMaxScan = "boundary_max_scan"
        case boundaryScannerType = "boundary_scanner"
        case boundaryScannerLocale = "boundary_scanner_locale"
        case encoder
        case forceSource = "force_source"
        case fragmenter
        case fragmentOffset = "fragment_offset"
        case fragmentSize = "fragment_size"
        case highlightQuery = "highlight_query"
        case matchedFields = "matched_fields"
        case noMatchSize = "no_match_size"
        case numberOfFragments = "number_of_fragments"
        case order
        case phraseLimit = "phrase_limit"
        case preTags = "pre_tags"
        case postTags = "post_tags"
        case requireFieldMatch = "require_field_match"
        case tagsSchema = "tags_schema"
        case type
        case termVector = "term_vector"
        case indexOptions = "index_options"
    }
}

extension Highlight.FieldOptions: Equatable {
    public static func == (lhs: Highlight.FieldOptions, rhs: Highlight.FieldOptions) -> Bool {
        return lhs.boundaryChars == rhs.boundaryChars
            && lhs.boundaryMaxScan == rhs.boundaryMaxScan
            && lhs.boundaryScannerType == rhs.boundaryScannerType
            && lhs.boundaryScannerLocale == rhs.boundaryScannerLocale
            && lhs.encoder == rhs.encoder
            && lhs.forceSource == rhs.forceSource
            && lhs.fragmenter == rhs.fragmenter
            && lhs.fragmentOffset == rhs.fragmentOffset
            && lhs.fragmentSize == rhs.fragmentSize
            && lhs.matchedFields == rhs.matchedFields
            && lhs.noMatchSize == rhs.noMatchSize
            && lhs.numberOfFragments == rhs.numberOfFragments
            && lhs.scoreOrdered == rhs.scoreOrdered
            && lhs.phraseLimit == rhs.phraseLimit
            && lhs.preTags == rhs.preTags
            && lhs.requireFieldMatch == rhs.requireFieldMatch
            && lhs.tagScheme == rhs.tagScheme
            && lhs.highlighterType == rhs.highlighterType
            && isEqualQueries(lhs.highlightQuery, rhs.highlightQuery)
    }
}

// MARK: - Rescoring

/// `SearchRequest` rescorer based on a query.
public struct QueryRescorer {
    public let windowSize: Int?
    public let query: RescoreQuery

    public init(query: RescoreQuery, windowSize: Int? = nil) {
        self.query = query
        self.windowSize = windowSize
    }
}

extension QueryRescorer: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(windowSize, forKey: .windowSize)
        try container.encode(query, forKey: .query)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        windowSize = try container.decodeIntIfPresent(forKey: .windowSize)
        query = try container.decode(RescoreQuery.self, forKey: .query)
    }

    enum CodingKeys: String, CodingKey {
        case windowSize = "window_size"
        case query
    }
}

extension QueryRescorer: Equatable {}

// MARK: - Collapsing

public struct Collapse {
    public let field: String
    public let innerHits: [InnerHit]?
    public let maxConcurrentGroupRequests: Int?
}

extension Collapse: Codable {
    enum CodingKeys: String, CodingKey {
        case field
        case innerHits = "inner_hits"
        case maxConcurrentGroupRequests = "max_concurrent_group_searches"
    }
}

extension Collapse: Equatable {}

// MARK: - Inner Hits

public struct InnerHit {
    public var name: String?
    public var ignoreUnmapped: Bool?
    public var from: Int?
    public var size: Int?
    public var explain: Bool?
    public var version: Bool?
    public var trackScores: Bool?
    public var sort: [Sort]?
    public var query: Query?
    public var sourceFilter: SourceFilter?
    public var scriptFields: [ScriptField]?
    public var storedFields: [String]?
    public var docvalueFields: [DocValueField]?
    public var highlight: Highlight?
    public var collapse: Collapse?

    public init() {}
}

extension InnerHit: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeStringIfPresent(forKey: .name)
        ignoreUnmapped = try container.decodeBoolIfPresent(forKey: .ignoreUnmapped)
        from = try container.decodeIntIfPresent(forKey: .from)
        size = try container.decodeIntIfPresent(forKey: .size)
        explain = try container.decodeBoolIfPresent(forKey: .explain)
        version = try container.decodeBoolIfPresent(forKey: .version)
        trackScores = try container.decodeBoolIfPresent(forKey: .trackScores)
        sort = try container.decodeIfPresent([Sort].self, forKey: .sort)
        query = try container.decodeQueryIfPresent(forKey: .query)
        sourceFilter = try container.decodeIfPresent(SourceFilter.self, forKey: .sourceFilter)
        docvalueFields = try container.decodeIfPresent([DocValueField].self, forKey: .docvalueFields)
        highlight = try container.decodeIfPresent(Highlight.self, forKey: .highlight)
        collapse = try container.decodeIfPresent(Collapse.self, forKey: .collapse)
        if container.contains(.scriptFields) {
            do {
                let scriptedField = try container.decode(ScriptField.self, forKey: .scriptFields)
                scriptFields = [scriptedField]
            } catch {
                let nested = try container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .scriptFields)
                var fields = [ScriptField]()
                for key in nested.allKeys {
                    let scriptContainer = try nested.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: key)
                    let script = try scriptContainer.decode(Script.self, forKey: .key(named: ScriptField.CodingKeys.script.stringValue))
                    fields.append(ScriptField(field: key.stringValue, script: script))
                }
                scriptFields = fields
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(ignoreUnmapped, forKey: .ignoreUnmapped)
        try container.encodeIfPresent(from, forKey: .from)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encodeIfPresent(explain, forKey: .explain)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(trackScores, forKey: .trackScores)
        try container.encodeIfPresent(sort, forKey: .sort)
        try container.encodeIfPresent(query, forKey: .query)
        try container.encodeIfPresent(sourceFilter, forKey: .sourceFilter)
        try container.encodeIfPresent(storedFields, forKey: .storedFields)
        try container.encodeIfPresent(docvalueFields, forKey: .docvalueFields)
        try container.encodeIfPresent(highlight, forKey: .highlight)
        try container.encodeIfPresent(collapse, forKey: .collapse)

        if let scriptFields = self.scriptFields, !scriptFields.isEmpty {
            if scriptFields.count == 1 {
                try container.encode(scriptFields[0], forKey: .scriptFields)
            } else {
                var nested = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .scriptFields)
                for scriptField in scriptFields {
                    var scriptContainer = nested.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .key(named: scriptField.field))
                    try scriptContainer.encode(scriptField.script, forKey: .key(named: ScriptField.CodingKeys.script.stringValue))
                }
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case name
        case ignoreUnmapped = "ignore_unmapped"
        case from
        case size
        case explain
        case version
        case trackScores = "track_scores"
        case sort
        case query
        case sourceFilter = "_source"
        case scriptFields = "script_fields"
        case storedFields = "stored_fields"
        case docvalueFields = "docvalue_fields"
        case highlight
        case collapse
    }
}

extension InnerHit: Equatable {
    public static func == (lhs: InnerHit, rhs: InnerHit) -> Bool {
        return lhs.name == rhs.name
            && lhs.ignoreUnmapped == rhs.ignoreUnmapped
            && lhs.from == rhs.from
            && lhs.size == rhs.size
            && lhs.explain == rhs.explain
            && lhs.version == rhs.version
            && lhs.trackScores == rhs.trackScores
            && lhs.sort == rhs.sort
            && lhs.sourceFilter == rhs.sourceFilter
            && lhs.scriptFields == rhs.scriptFields
            && lhs.docvalueFields == rhs.docvalueFields
            && lhs.highlight == rhs.highlight
    }
}

// MARK: - Search Source

public struct SearchSource {
public var trackTotalHits: Bool?
    public var query: Query?
    public var sorts: [Sort]?
    public var size: Int?
    public var from: Int?
    public var sourceFilter: SourceFilter?
    public var explain: Bool?
    public var minScore: Decimal?
    public var trackScores: Bool?
    public var indicesBoost: [IndexBoost]?
    public var seqNoPrimaryTerm: Bool?
    public var version: Bool?
    public var scriptFields: [ScriptField]?
    public var storedFields: [String]?
    public var docvalueFields: [DocValueField]?
    public var postFilter: Query?
    public var highlight: Highlight?
    public var rescore: [QueryRescorer]?
    public var searchAfter: CodableValue?
}

extension SearchSource: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
trackTotalHits = try container.decodeBoolIfPresent(forKey: .trackTotalHits)
        query = try container.decodeQueryIfPresent(forKey: .query)
        sorts = try container.decodeArrayIfPresent(forKey: .sorts)
        size = try container.decodeIntIfPresent(forKey: .size)
        from = try container.decodeIntIfPresent(forKey: .from)
        sourceFilter = try container.decodeIfPresent(SourceFilter.self, forKey: .sourceFilter)
        explain = try container.decodeBoolIfPresent(forKey: .explain)
        minScore = try container.decodeDecimalIfPresent(forKey: .minScore)
        trackScores = try container.decodeBoolIfPresent(forKey: .trackScores)
        indicesBoost = try container.decodeArrayIfPresent(forKey: .indicesBoost)
        seqNoPrimaryTerm = try container.decodeBoolIfPresent(forKey: .seqNoPrimaryTerm)
        version = try container.decodeBoolIfPresent(forKey: .version)
        storedFields = try container.decodeArrayIfPresent(forKey: .storedFields)
        docvalueFields = try container.decodeArrayIfPresent(forKey: .docvalueFields)
        postFilter = try container.decodeQueryIfPresent(forKey: .postFilter)
        highlight = try container.decodeIfPresent(Highlight.self, forKey: .highlight)
        searchAfter = try container.decodeIfPresent(CodableValue.self, forKey: .searchAfter)

        do {
            scriptFields = try container.decodeArrayIfPresent(forKey: .scriptFields)
        } catch {
            let scriptField = try container.decode(ScriptField.self, forKey: .scriptFields)
            scriptFields = [scriptField]
        }

        do {
            rescore = try container.decodeArrayIfPresent(forKey: .rescore)
        } catch {
            let rescorer = try container.decode(QueryRescorer.self, forKey: .rescore)
            rescore = [rescorer]
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
try container.encodeIfPresent(trackTotalHits, forKey: .trackTotalHits)
        try container.encodeIfPresent(query, forKey: .query)
        try container.encodeIfPresent(sorts, forKey: .sorts)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encodeIfPresent(from, forKey: .from)
        try container.encodeIfPresent(sourceFilter, forKey: .sourceFilter)
        try container.encodeIfPresent(explain, forKey: .explain)
        try container.encodeIfPresent(minScore, forKey: .minScore)
        try container.encodeIfPresent(trackScores, forKey: .trackScores)
        try container.encodeIfPresent(indicesBoost, forKey: .indicesBoost)
        try container.encodeIfPresent(seqNoPrimaryTerm, forKey: .seqNoPrimaryTerm)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(storedFields, forKey: .storedFields)
        try container.encodeIfPresent(docvalueFields, forKey: .docvalueFields)
        try container.encodeIfPresent(postFilter, forKey: .postFilter)
        try container.encodeIfPresent(highlight, forKey: .highlight)
        if let scriptFields = self.scriptFields, !scriptFields.isEmpty {
            if scriptFields.count == 1 {
                try container.encode(scriptFields[0], forKey: .scriptFields)
            } else {
                var nested = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .scriptFields)
                for scriptField in scriptFields {
                    var scriptContainer = nested.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .key(named: scriptField.field))
                    try scriptContainer.encode(scriptField.script, forKey: .key(named: "script"))
                }
            }
        }
        if let rescore = self.rescore, !rescore.isEmpty {
            if rescore.count == 1 {
                try container.encode(rescore[0], forKey: .rescore)
            } else {
                try container.encode(rescore, forKey: .rescore)
            }
        }
        try container.encodeIfPresent(searchAfter, forKey: .searchAfter)
    }

    enum CodingKeys: String, CodingKey {
case trackTotalHits = "track_total_hits"
        case query
        case sorts = "sort"
        case size
        case from
        case sourceFilter = "_source"
        case explain
        case minScore = "min_score"
        case trackScores = "track_scores"
        case indicesBoost = "indices_boost"
        case seqNoPrimaryTerm = "seq_no_primary_term"
        case version
        case scriptFields = "script_fields"
        case storedFields = "stored_fields"
        case docvalueFields = "docvalue_fields"
        case postFilter = "post_filter"
        case highlight
        case rescore
        case searchAfter = "search_after"
    }
}

extension SearchSource: Equatable {
    public static func == (lhs: SearchSource, rhs: SearchSource) -> Bool {
        return lhs.sorts == rhs.sorts
&& lhs.trackTotalHits == rhs.trackTotalHits
            && lhs.size == rhs.size
            && lhs.from == rhs.from
            && lhs.sourceFilter == rhs.sourceFilter
            && lhs.explain == rhs.explain
            && lhs.minScore == rhs.minScore
            && lhs.trackScores == rhs.trackScores
            && lhs.indicesBoost == rhs.indicesBoost
            && lhs.seqNoPrimaryTerm == rhs.seqNoPrimaryTerm
            && lhs.version == rhs.version
            && lhs.scriptFields == rhs.scriptFields
            && lhs.storedFields == rhs.storedFields
            && lhs.docvalueFields == rhs.docvalueFields
            && lhs.highlight == rhs.highlight
            && lhs.rescore == rhs.rescore
            && lhs.searchAfter == rhs.searchAfter
            && isEqualQueries(lhs.query, rhs.query)
            && isEqualQueries(lhs.postFilter, rhs.postFilter)
    }
}
