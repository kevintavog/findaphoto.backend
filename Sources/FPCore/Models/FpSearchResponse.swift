import Foundation

public struct FpSearchResponse {
    public let total: Int
    public let hits: [Hit]
    public let categories: [CategoryResult]

    public init(_ hits: [Hit], _ total: Int, _ categories: [CategoryResult]) {
        self.hits = hits
        self.total = total
        self.categories = categories
    }


    public struct Hit {
        public let media: FpMedia
        public let sort: Any

        public init(_ media: FpMedia, _ sort: Any) {
            self.media = media
            self.sort = sort
        }
    }

    public struct CategoryResult {
        public let field: String
        public let details: [CategoryDetail]

        public init(_ field: String, _ details: [CategoryDetail]) {
            self.field = field
            self.details = details
        }
    }

    public struct CategoryDetail {
        public let field: String?
        public let name: String
        public let count: Int
        public var children: [CategoryDetail]?

        public init(_ name: String, _ count: Int, _ field: String? = nil) {
            self.name = name
            self.count = count
            self.field = field
        }
    }
}

extension FpSearchResponse.CategoryResult: CustomStringConvertible {
    public var description: String {
        return "Category: \(field): \(details)"
    }
}

extension FpSearchResponse.CategoryDetail: CustomStringConvertible {
    public var description: String {
        return "\(name)=\(count) \(field ?? "") - \(children ?? [])"
    }
}
