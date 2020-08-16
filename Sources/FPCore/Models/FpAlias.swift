import Foundation

public struct FpAlias: Codable {
    public let dateAdded: Date
    public let dateLastIndexed: Date
    public let path: String
    public let alias: String

    public init(alias: String, path: String) {
        self.dateAdded = Date()
        dateLastIndexed = self.dateAdded
        self.path = path
        self.alias = alias
    }

    public init(pathOverride: String, alias: FpAlias) {
        self.dateAdded = alias.dateAdded
        self.dateLastIndexed = alias.dateLastIndexed
        self.alias = alias.alias
        self.path = pathOverride
    }
}

extension FpAlias: Equatable {
    public static func == (lhs: FpAlias, rhs: FpAlias) -> Bool {
        return lhs.path == rhs.path
    }
}
