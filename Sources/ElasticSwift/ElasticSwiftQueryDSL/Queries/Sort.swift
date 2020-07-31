//
//  Sort.swift
//  ElasticSwift
//
//  Created by Prafull Kumar Soni on 6/4/17.
//
//

// import ElasticSwiftCore
import Foundation
import Logging

public final class SortBuilders {
    public static func scoreSort() -> ScoreSortBuilder {
        return ScoreSortBuilder()
    }

    public static func fieldSort(_ field: String) -> FieldSortBuilder {
        return FieldSortBuilder(field)
    }

    public static func geoDistance(_ field: String, _ point: GeoPoint) -> GeoDistanceSortBuilder {
        return GeoDistanceSortBuilder(field, point)
    }
}

public class GeoDistanceSortBuilder: SortBuilder {
    var field: String?
    var point: GeoPoint?
    var sortOrder: SortOrder?
    var mode: SortMode?
    var unit: String?

    public init(_ field: String, _ point: GeoPoint) {
        self.field = field
        self.point = point
    }

    public func set(unit: String) -> GeoDistanceSortBuilder {
        self.unit = unit
        return self
    }

    public func set(order: SortOrder) -> GeoDistanceSortBuilder {
        sortOrder = order
        return self
    }

    public func set(mode: SortMode) -> GeoDistanceSortBuilder {
        self.mode = mode
        return self
    }

    public func build() -> Sort {
        return Sort(withBuilder: self)
    }
}

public class ScoreSortBuilder: SortBuilder {
    private static let _SCORE = "_score"

    var sortOrder: SortOrder?
    var field = ScoreSortBuilder._SCORE

    init() {}

    public func set(order: SortOrder) -> ScoreSortBuilder {
        sortOrder = order
        return self
    }

    public func build() -> Sort {
        return Sort(withBuilder: self)
    }
}

public class FieldSortBuilder: SortBuilder {
    var field: String?
    var sortOrder: SortOrder?
    var mode: SortMode?

    public init(_ field: String) {
        self.field = field
    }

    public func set(order: SortOrder) -> FieldSortBuilder {
        sortOrder = order
        return self
    }

    public func set(mode: SortMode) -> FieldSortBuilder {
        self.mode = mode
        return self
    }

    public func build() -> Sort {
        return Sort(withBuilder: self)
    }
}

protocol SortBuilder {
    func build() -> Sort
}

public struct Sort {
    private static let logger = Logger(label: "org.pksprojects.ElasticSwfit.ElasticClient")

    public let field: String
    public let sortOrder: SortOrder
    public let mode: SortMode?
    public let point: GeoPoint?
    public let unit: String?

    init(withBuilder builder: ScoreSortBuilder) {
        field = builder.field
        sortOrder = builder.sortOrder ?? .desc
        mode = nil
        point = nil
        unit = nil
    }

    init(withBuilder builder: FieldSortBuilder) {
        field = builder.field!
        mode = builder.mode
        sortOrder = builder.sortOrder ?? .desc
        point = nil
        unit = nil
    }

    init(withBuilder builder: GeoDistanceSortBuilder) {
        field = builder.field!
        mode = builder.mode
        sortOrder = builder.sortOrder ?? .desc
        point = builder.point!
        unit = builder.unit
    }
}

extension Sort: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        guard container.allKeys.count == 1 else {
            throw Swift.DecodingError.typeMismatch(Sort.self, .init(codingPath: container.codingPath, debugDescription: "Unable to find field name in key(s) expect: 1 key found: \(container.allKeys.count)."))
        }

        field = container.allKeys.first!.stringValue
        if let fieldContainer = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: field)) {
            sortOrder = try fieldContainer.decode(SortOrder.self, forKey: .order)
            mode = try fieldContainer.decodeIfPresent(SortMode.self, forKey: .mode)
        } else {
            sortOrder = try container.decode(SortOrder.self, forKey: .key(named: field))
            mode = nil
        }

point = nil
unit = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)

        guard mode != nil else {
            try container.encode(sortOrder, forKey: .key(named: field))
            return
        }

        if point != nil {
            var geoDistance = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: "_geo_distance"))
// Ugh. I can't work out how to encode the field name, hardcoding to my value...
try geoDistance.encode(point, forKey: .location)
            try geoDistance.encode(sortOrder, forKey: .order)
            try geoDistance.encode(mode, forKey: .mode)
            try geoDistance.encode(unit, forKey: .unit)
        } else {
            var nested = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .key(named: field))
            try nested.encode(sortOrder, forKey: .order)
            try nested.encode(mode, forKey: .mode)
            try nested.encode(unit, forKey: .unit)
        }
    }

    enum CodingKeys: String, CodingKey {
        case order
        case mode
        case unit
        case location
    }
}

extension Sort: Equatable {
    public static func == (lhs: Sort, rhs: Sort) -> Bool {
        return lhs.field == rhs.field
            && lhs.sortOrder == rhs.sortOrder
            && lhs.mode == rhs.mode
            && lhs.unit == rhs.unit
            && lhs.point == rhs.point
    }
}

public enum SortOrder: String, Codable {
    case asc
    case desc
}

public enum SortMode: String, Codable {
    case max
    case min
    case avg
    case sum
    case median
}
