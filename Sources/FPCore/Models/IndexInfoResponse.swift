import Foundation
import Vapor

public struct IndexInfoResponse: Content {
    public var versionNumber: String?
    public var duplicateCount: Int?
    public var imageCount: Int?
    public var videoCount: Int?
    public var warningCount: Int?

    public var dependencyInfo: DependencyInfo?
    public var paths: [PathInfo]?

    public struct DependencyInfo: Codable {
        public var elasticSearch: ElasticSearch

        public struct ElasticSearch: Codable {
            public var httpStatusCode: Int
            public var index: String
            public var indexStatus: String
            public var version: String
        }
    }

    public struct PathInfo: Codable {
        public var path: String
        public var lastIndexed: Date
    }

    public init() {
    }
}
