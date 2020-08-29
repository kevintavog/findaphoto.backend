import Foundation

public final class AggregationBuilders {
    public static func term(_ field: String) -> TermsAggregationDetailBuilder {
        return TermsAggregationDetailBuilder(field)
    }
}

public class DetailsAggregationBuilder {
    var aggregations: [String:Aggregation]?

    @discardableResult
    public func add(name: String, aggregation: Aggregation) -> Self {
        if self.aggregations == nil {
            self.aggregations = [String:Aggregation]()
        }
        self.aggregations?[name] = aggregation
        return self
    }

}

public class TermsAggregationDetailBuilder: DetailsAggregationBuilder, AggregationBuilder {
    let field: String
    var size: Int?

    public init(_ field: String) {
        self.field = field
    }

    @discardableResult
    public func set(size: Int) -> Self {
        self.size = size
        return self
    }

    public func build() -> Aggregation {
        return Aggregation(withBuilder: self)
    }
}

protocol AggregationBuilder {
    func build() -> Aggregation
}

public struct AggregationDetail {
    public let type: String
    public let field: String
    public let size: Int?

    init(withBuilder builder: TermsAggregationDetailBuilder) {
        type = "terms"
        field = builder.field
        size = builder.size
    }
}

extension AggregationDetail: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard container.allKeys.count == 1 else {
            throw Swift.DecodingError.typeMismatch(AggregationDetail.self, .init(codingPath: container.codingPath, debugDescription: "Unable to find field name in key(s) expect: 1 key found: \(container.allKeys.count)."))
        }

        type = container.allKeys.first!.stringValue
        field = try container.decode(String.self, forKey: .field)
        size = try container.decode(Int.self, forKey: .size)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(field, forKey: .field)
        try container.encodeIfPresent(size, forKey: .size)
    }

    enum CodingKeys: String, CodingKey {
        case field
        case size
    }
}

extension AggregationDetail: Equatable {
    public static func == (lhs: AggregationDetail, rhs: AggregationDetail) -> Bool {
        return lhs.field == rhs.field
            && lhs.size == rhs.size
    }
}

// MARK: Aggregation

public struct Aggregation {
    public let detail: AggregationDetail
    public let aggregations: [String:Aggregation]?

    init(withBuilder builder: TermsAggregationDetailBuilder) {
        detail = AggregationDetail(withBuilder: builder)
        aggregations = builder.aggregations
    }
}

extension Aggregation: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        guard container.allKeys.count == 1 else {
            throw Swift.DecodingError.typeMismatch(AggregationDetail.self, .init(codingPath: container.codingPath, debugDescription: "Unable to find field name in key(s) expect: 1 key found: \(container.allKeys.count)."))
        }

        let type = container.allKeys.first!.stringValue
        detail = try container.decode(AggregationDetail.self, forKey: .key(named: type))
        aggregations = try container.decode([String:Aggregation].self, forKey: .key(named: "aggs"))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)

        try container.encode(detail, forKey: .key(named: detail.type))
        try container.encodeIfPresent(aggregations, forKey: .key(named: "aggs"))
    }
}

extension Aggregation: Equatable {
    public static func == (lhs: Aggregation, rhs: Aggregation) -> Bool {
        return lhs.detail == rhs.detail
            && lhs.aggregations == rhs.aggregations
    }
}
