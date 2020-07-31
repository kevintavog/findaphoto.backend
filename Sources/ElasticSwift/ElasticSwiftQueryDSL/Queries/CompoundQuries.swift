//
//  CompoundQuries.swift
//  ElasticSwift
//
//  Created by Prafull Kumar Soni on 4/14/18.
//

// import ElasticSwiftCodableUtils
// import ElasticSwiftCore
import Foundation

// MARK: - Constant Score Query

public struct ConstantScoreQuery: Query {
    public let queryType: QueryType = QueryTypes.constantScore

    public let query: Query
    public let boost: Decimal?

    public init(_ query: Query, boost: Decimal? = nil) {
        self.query = query
        self.boost = boost
    }

    internal init(withBuilder builder: ConstantScoreQueryBuilder) throws {
        guard builder.query != nil else {
            throw QueryBuilderError.missingRequiredField("query")
        }

        self.init(builder.query!, boost: builder.boost)
    }
}

extension ConstantScoreQuery {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: queryType))
        boost = try nested.decodeIfPresent(Decimal.self, forKey: .boost)
        query = try nested.decodeQuery(forKey: .filter)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        var nested = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: queryType))
        try nested.encode(query, forKey: .filter)
        try nested.encodeIfPresent(boost, forKey: .boost)
    }

    enum CodingKeys: String, CodingKey {
        case boost
        case filter
    }
}

extension ConstantScoreQuery: Equatable {
    public static func == (lhs: ConstantScoreQuery, rhs: ConstantScoreQuery) -> Bool {
        return lhs.queryType.isEqualTo(rhs.queryType)
            && lhs.query.isEqualTo(rhs.query)
            && lhs.boost == rhs.boost
    }
}

// MARK: - Bool Query

public struct BoolQuery: Query {
    public let queryType: QueryType = QueryTypes.bool

    public let mustClauses: [Query]
    public let mustNotClauses: [Query]
    public let shouldClauses: [Query]
    public let filterClauses: [Query]
    public let minimumShouldMatch: Int?
    public let boost: Decimal?

    public init(must: [Query], mustNot: [Query], should: [Query], filter: [Query], minimumShouldMatch: Int? = nil, boost: Decimal? = nil) {
        mustNotClauses = mustNot
        mustClauses = must
        shouldClauses = should
        filterClauses = filter
        self.minimumShouldMatch = minimumShouldMatch
        self.boost = boost
    }

    internal init(withBuilder builder: BoolQueryBuilder) throws {
        guard !builder.filterClauses.isEmpty || !builder.mustClauses.isEmpty || !builder.mustNotClauses.isEmpty || !builder.shouldClauses.isEmpty else {
            throw QueryBuilderError.atleastOneFieldRequired(["filterClauses", "mustClauses", "mustNotClauses", "shouldClauses"])
        }

        self.init(must: builder.mustClauses, mustNot: builder.mustNotClauses, should: builder.shouldClauses, filter: builder.filterClauses, minimumShouldMatch: builder.minimumShouldMatch, boost: builder.boost)
    }
}

extension BoolQuery {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: queryType))
        filterClauses = try nested.decodeQueriesIfPresent(forKey: .filter) ?? []
        mustClauses = try nested.decodeQueriesIfPresent(forKey: .must) ?? []
        mustNotClauses = try nested.decodeQueriesIfPresent(forKey: .mustNot) ?? []
        shouldClauses = try nested.decodeQueriesIfPresent(forKey: .should) ?? []
        boost = try nested.decodeIfPresent(Decimal.self, forKey: .boost)
        minimumShouldMatch = try nested.decodeIntIfPresent(forKey: .minShouldMatch)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        var nested = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: queryType))
        if !filterClauses.isEmpty {
            try nested.encode(filterClauses, forKey: .filter)
        }
        if !mustClauses.isEmpty {
            try nested.encode(mustClauses, forKey: .must)
        }
        if !mustNotClauses.isEmpty {
            try nested.encode(mustNotClauses, forKey: .mustNot)
        }
        if !shouldClauses.isEmpty {
            try nested.encode(shouldClauses, forKey: .should)
        }
        try nested.encodeIfPresent(boost, forKey: .boost)
        try nested.encodeIfPresent(minimumShouldMatch, forKey: .minShouldMatch)
    }

    enum CodingKeys: String, CodingKey {
        case must
        case mustNot = "must_not"
        case should
        case filter
        case minShouldMatch = "minimum_should_match"
        case boost
    }
}

extension BoolQuery: Equatable {
    public static func == (lhs: BoolQuery, rhs: BoolQuery) -> Bool {
        return lhs.queryType.isEqualTo(rhs.queryType)
            && lhs.minimumShouldMatch == rhs.minimumShouldMatch
            && lhs.boost == rhs.boost
            && lhs.filterClauses.count == rhs.filterClauses.count
            && !zip(lhs.filterClauses, rhs.filterClauses).contains { !$0.isEqualTo($1) }
            && lhs.mustClauses.count == rhs.mustClauses.count
            && !zip(lhs.mustClauses, rhs.mustClauses).contains { !$0.isEqualTo($1) }
            && lhs.mustNotClauses.count == rhs.mustNotClauses.count
            && !zip(lhs.mustNotClauses, rhs.mustNotClauses).contains { !$0.isEqualTo($1) }
            && lhs.shouldClauses.count == rhs.shouldClauses.count
            && !zip(lhs.shouldClauses, rhs.shouldClauses).contains { !$0.isEqualTo($1) }
    }
}

// MARK: - Dis Max Query

public struct DisMaxQuery: Query {
    public let queryType: QueryType = QueryTypes.disMax

    public static let DEFAULT_TIE_BREAKER: Decimal = 0.0

    public let tieBreaker: Decimal
    public let boost: Decimal?
    public let queries: [Query]

    public init(_ queries: [Query], tieBreaker: Decimal = DisMaxQuery.DEFAULT_TIE_BREAKER, boost: Decimal? = nil) {
        self.tieBreaker = tieBreaker
        self.boost = boost
        self.queries = queries
    }

    internal init(withBuilder builder: DisMaxQueryBuilder) throws {
        guard !builder.queries.isEmpty else {
            throw QueryBuilderError.missingRequiredField("query")
        }

        self.init(builder.queries, tieBreaker: builder.tieBreaker ?? DisMaxQuery.DEFAULT_TIE_BREAKER, boost: builder.boost)
    }
}

extension DisMaxQuery {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: queryType))
        tieBreaker = try nested.decodeDecimal(forKey: .tieBreaker)
        queries = try nested.decodeQueries(forKey: .queries)
        boost = try nested.decodeDecimalIfPresent(forKey: .boost)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        var nested = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: queryType))

        try nested.encode(queries, forKey: .queries)
        try nested.encode(tieBreaker, forKey: .tieBreaker)
        try nested.encodeIfPresent(boost, forKey: .boost)
    }

    enum CodingKeys: String, CodingKey {
        case queries
        case boost
        case tieBreaker = "tie_breaker"
    }
}

extension DisMaxQuery: Equatable {
    public static func == (lhs: DisMaxQuery, rhs: DisMaxQuery) -> Bool {
        return lhs.queryType.isEqualTo(rhs.queryType)
            && lhs.tieBreaker == rhs.tieBreaker
            && lhs.boost == rhs.boost
            && lhs.queries.count == rhs.queries.count
            && !zip(lhs.queries, rhs.queries).contains { !$0.isEqualTo($1) }
    }
}

// MARK: - Function Score Query

public struct FunctionScoreQuery: Query {
    public let queryType: QueryType = QueryTypes.functionScore

    public let query: Query
    public let boost: Decimal?
    public let boostMode: BoostMode?
    public let maxBoost: Decimal?
    public let scoreMode: ScoreMode?
    public let minScore: Decimal?
    public let functions: [ScoreFunction]

    public init(query: Query, boost: Decimal? = nil, boostMode: BoostMode? = nil, maxBoost: Decimal? = nil, scoreMode: ScoreMode? = nil, minScore: Decimal? = nil, functions: [ScoreFunction]) {
        self.query = query
        self.boost = boost
        self.boostMode = boostMode
        self.maxBoost = maxBoost
        self.scoreMode = scoreMode
        self.minScore = minScore
        self.functions = functions
    }

    public init(query: Query, boost: Decimal? = nil, boostMode: BoostMode? = nil, maxBoost: Decimal? = nil, scoreMode: ScoreMode? = nil, minScore: Decimal? = nil, functions: ScoreFunction...) {
        self.init(query: query, boost: boost, boostMode: boostMode, maxBoost: maxBoost, scoreMode: scoreMode, minScore: minScore, functions: functions)
    }

    internal init(withBuilder builder: FunctionScoreQueryBuilder) throws {
        guard builder.query != nil else {
            throw QueryBuilderError.missingRequiredField("query")
        }

        guard !builder.functions.isEmpty else {
            throw QueryBuilderError.atlestOneElementRequired("functions")
        }

        self.init(query: builder.query!, boost: builder.boost, boostMode: builder.boostMode, maxBoost: builder.maxBoost, scoreMode: builder.scoreMode, minScore: builder.minScore, functions: builder.functions)
    }
}

extension FunctionScoreQuery {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: queryType))
        query = try nested.decodeQuery(forKey: .query)
        functions = try nested.decodeScoreFunctionsIfPresent(forKey: .functions) ?? []
        boost = try nested.decodeDecimalIfPresent(forKey: .boost)
        scoreMode = try nested.decodeIfPresent(ScoreMode.self, forKey: .scoreMode)
        boostMode = try nested.decodeIfPresent(BoostMode.self, forKey: .boostMode)
        maxBoost = try nested.decodeDecimalIfPresent(forKey: .maxBoost)
        minScore = try nested.decodeDecimalIfPresent(forKey: .minScore)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        var nested = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: queryType))
        try nested.encode(query, forKey: .query)
        try nested.encodeIfPresent(scoreMode, forKey: .scoreMode)
        try nested.encodeIfPresent(boostMode, forKey: .boostMode)
        try nested.encodeIfPresent(boost, forKey: .boost)
        try nested.encodeIfPresent(maxBoost, forKey: .maxBoost)
        try nested.encodeIfPresent(minScore, forKey: .minScore)
        if !functions.isEmpty {
            try nested.encode(functions, forKey: .functions)
        }
    }

    enum CodingKeys: String, CodingKey {
        case query
        case boost
        case boostMode = "boost_mode"
        case maxBoost = "max_boost"
        case scoreMode = "score_mode"
        case minScore = "min_score"
        case functions
    }
}

extension FunctionScoreQuery: Equatable {
    public static func == (lhs: FunctionScoreQuery, rhs: FunctionScoreQuery) -> Bool {
        return lhs.queryType.isEqualTo(rhs.queryType)
            && lhs.boost == rhs.boost
            && lhs.boostMode == rhs.boostMode
            && lhs.maxBoost == rhs.maxBoost
            && lhs.minScore == rhs.minScore
            && lhs.query.isEqualTo(rhs.query)
            && lhs.scoreMode == rhs.scoreMode
            && lhs.functions.count == rhs.functions.count
            && !zip(lhs.functions, rhs.functions).contains { !$0.isEqualTo($1) }
    }
}

// MARK: - Boosting Query

public struct BoostingQuery: Query {
    public let queryType: QueryType = QueryTypes.boosting

    public let negative: Query
    public let positive: Query
    public let negativeBoost: Decimal?

    public init(positive: Query, negative: Query, negativeBoost: Decimal? = nil) {
        self.positive = positive
        self.negative = negative
        self.negativeBoost = negativeBoost
    }

    internal init(withBuilder builder: BoostingQueryBuilder) throws {
        guard builder.positive != nil else {
            throw QueryBuilderError.missingRequiredField("positive")
        }

        guard builder.negative != nil else {
            throw QueryBuilderError.missingRequiredField("negative")
        }

        self.init(positive: builder.positive!, negative: builder.negative!, negativeBoost: builder.negativeBoost)
    }
}

extension BoostingQuery {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: queryType))
        negative = try nested.decodeQuery(forKey: .negative)
        positive = try nested.decodeQuery(forKey: .positive)
        negativeBoost = try nested.decodeDecimalIfPresent(forKey: .negativeBoost)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        var nested = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: queryType))

        try nested.encode(positive, forKey: .positive)
        try nested.encode(negative, forKey: .negative)
        try nested.encodeIfPresent(negativeBoost, forKey: .negativeBoost)
    }

    enum CodingKeys: String, CodingKey {
        case positive
        case negative
        case negativeBoost = "negative_boost"
    }
}

extension BoostingQuery: Equatable {
    public static func == (lhs: BoostingQuery, rhs: BoostingQuery) -> Bool {
        return lhs.queryType.isEqualTo(rhs.queryType)
            && lhs.negative.isEqualTo(rhs.negative)
            && lhs.positive.isEqualTo(rhs.positive)
            && lhs.negativeBoost == rhs.negativeBoost
    }
}
