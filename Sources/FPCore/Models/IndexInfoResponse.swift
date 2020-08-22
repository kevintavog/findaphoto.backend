import Foundation
import Vapor

public struct IndexInfoResponse: Content {
    public var buildTimestamp: String?
    public var imageCount: Int?
    public var videoCount: Int?
    public var warningCount: Int?

    public var dependencyInfo: DependencyInfo?
    public var paths: [PathInfo]?

    public var fields: [String]?

    public struct DependencyInfo: Codable {
        public var elasticSearch: ElasticSearch = ElasticSearch()
        public init() { }

        public struct ElasticSearch: Codable {
            public var version: String = ""
            public var indices: [IndexInfo] = []

            public struct IndexInfo: Codable {
                public var index: String
                public var status: String
                public init(_ index: String, _ status: String) {
                    self.index = index
                    self.status = status
                }
            }
        }
    }

    public struct PathInfo: Codable {
        public var path: String
        public var lastIndexed: Date
        public init(_ path: String, _ date: Date) {
            self.path = path
            self.lastIndexed = date
        }
    }

    public init() {
    }
}
