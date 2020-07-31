import Vapor

public struct FpAliasSearchResponse: Content, Codable, Equatable {
    public let hits: [FpAlias]

    public init(_ hits: [FpAlias]) {
        self.hits = hits
    }
}
