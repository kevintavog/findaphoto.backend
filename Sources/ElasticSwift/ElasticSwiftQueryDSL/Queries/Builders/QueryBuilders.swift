//
//  QueryBuilders.swift
//  ElasticSwift
//
//  Created by Prafull Kumar Soni on 6/3/17.
//
//

// import ElasticSwiftCore
import Foundation

/// Class to get instances of various Query Builders.

public final class QueryBuilders {
    private init() {}

    public static func matchAllQuery() -> MatchAllQueryBuilder {
        return MatchAllQueryBuilder()
    }

    public static func matchQuery() -> MatchQueryBuilder {
        return MatchQueryBuilder()
    }

    public static func matchPhraseQuery() -> MatchPhraseQueryBuilder {
        return MatchPhraseQueryBuilder()
    }

    public static func matchPhrasePrefixQuery() -> MatchPhrasePrefixQueryBuilder {
        return MatchPhrasePrefixQueryBuilder()
    }

    public static func multiMatchQuery() -> MultiMatchQueryBuilder {
        return MultiMatchQueryBuilder()
    }

    public static func commonTermsQuery() -> CommonTermsQueryBuilder {
        return CommonTermsQueryBuilder()
    }

    public static func queryStringQuery() -> QueryStringQueryBuilder {
        return QueryStringQueryBuilder()
    }

    public static func simpleQueryStringQuery() -> SimpleQueryStringQueryBuilder {
        return SimpleQueryStringQueryBuilder()
    }

    public static func termQuery() -> TermQueryBuilder {
        return TermQueryBuilder()
    }

    public static func termsQuery() -> TermsQueryBuilder {
        return TermsQueryBuilder()
    }

    public static func rangeQuery() -> RangeQueryBuilder {
        return RangeQueryBuilder()
    }

    public static func existsQuery() -> ExistsQueryBuilder {
        return ExistsQueryBuilder()
    }

    public static func prefixQuery() -> PrefixQueryBuilder {
        return PrefixQueryBuilder()
    }

    public static func wildCardQuery() -> WildCardQueryBuilder {
        return WildCardQueryBuilder()
    }

    public static func regexpQuery() -> RegexpQueryBuilder {
        return RegexpQueryBuilder()
    }

    public static func fuzzyQuery() -> FuzzyQueryBuilder {
        return FuzzyQueryBuilder()
    }

    public static func typeQuery() -> TypeQueryBuilder {
        return TypeQueryBuilder()
    }

    public static func idsQuery() -> IdsQueryBuilder {
        return IdsQueryBuilder()
    }

    public static func boolQuery() -> BoolQueryBuilder {
        return BoolQueryBuilder()
    }

    public static func constantScoreQuery() -> ConstantScoreQueryBuilder {
        return ConstantScoreQueryBuilder()
    }

    public static func disMaxQuery() -> DisMaxQueryBuilder {
        return DisMaxQueryBuilder()
    }

    public static func functionScoreQuery() -> FunctionScoreQueryBuilder {
        return FunctionScoreQueryBuilder()
    }

    public static func boostingQuery() -> BoostingQueryBuilder {
        return BoostingQueryBuilder()
    }

    public static func nestedQuery() -> NestedQueryBuilder {
        return NestedQueryBuilder()
    }

    public static func hasChildQuery() -> HasChildQueryBuilder {
        return HasChildQueryBuilder()
    }

    public static func hasParentQuery() -> HasParentQueryBuilder {
        return HasParentQueryBuilder()
    }

    public static func parentIdQuery() -> ParentIdQueryBuilder {
        return ParentIdQueryBuilder()
    }

    public static func geoShapeQuery() -> GeoShapeQueryBuilder {
        return GeoShapeQueryBuilder()
    }

    public static func geoBoundingBoxQuery() -> GeoBoundingBoxQueryBuilder {
        return GeoBoundingBoxQueryBuilder()
    }

    public static func geoDistanceQuery() -> GeoDistanceQueryBuilder {
        return GeoDistanceQueryBuilder()
    }

    public static func geoPolygonQuery() -> GeoPolygonQueryBuilder {
        return GeoPolygonQueryBuilder()
    }
}
