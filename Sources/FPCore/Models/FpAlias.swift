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
}

extension FpAlias: Equatable {
    public static func == (lhs: FpAlias, rhs: FpAlias) -> Bool {
        return lhs.path == rhs.path
    }
}
