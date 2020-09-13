import Foundation

struct ElasticErrorResponse: Codable, CustomStringConvertible {
    public let status: Int
    public let error: Error

    struct Error: Codable {
        public let root_cause: [RootCause]?
        public let type: String
        public let reason: String
    }

    struct RootCause: Codable {
        public let type: String
        public let reason: String
        public let index: String
    }

    public var description: String {
        return "\(status) - \(error.type): \(error.reason)"
    }

    public var type: String {
        if let rc = error.root_cause {
            if rc.count > 0 {
                return rc[0].type
            }
        }
        return error.type
    }

    public var reason: String {
        if let rc = error.root_cause {
            if rc.count > 0 {
                return rc[0].reason
            }
        }
        return error.reason
    }
}

public struct ElasticSearchIndexResponse: Codable {
    public let index: String
    public let health: String
}


public enum ElasticSearchResultType: String, Codable {
    case created = "created"
    case updated = "updated"
    case deleted = "deleted"
    case notFound = "not_found"
    case noop = "noop"
}

struct ElasticSearchGetResponse<T: Codable>: Codable {
    let found: Bool
    let _id: String
    let _source: T
}

struct ElasticSearchSearchResponse<T: Codable>: Codable {
    let took: Int
    let hits: Hits<T>

    struct Hits<T: Codable>: Codable {
        let total: Total
        let hits: [Hits<T>]

        struct Total: Codable {
            let value: Int
            let relation: String
        }

        struct Hits<T: Codable>: Codable {
            let _id: String
            let _source: T
        }
    }
}

public struct ElasticSearchSignaturesResponse: Codable {
    public let signature: String
    public let azureTags: [String]?
    public let clarifaiTags: [String]?

    init(_ signature: String, _ azureTags: [String]?, _ clarifaiTags: [String]?) {
        self.signature = signature
        self.azureTags = azureTags
        self.clarifaiTags = clarifaiTags
    }
}

public struct ElasticSearchBulkResponse: Codable {
    public let errors: Bool
    public let items: [BulkItemsResponse]

    public struct BulkItemsResponse: Codable {
        public let index: BulkIndexResponse
    }

    public struct BulkIndexResponse: Codable {
        public let result: String?
        public let status: Int
        public let error: BulkIndexResponseError?
        public let _shards: BulkIndexResponseShards?

        public struct BulkIndexResponseShards: Codable {
            public let total: Int
            public let successful: Int
            public let failed: Int
        }

        public struct BulkIndexResponseError: Codable {
            public let type: String
            public let reason: String
            public let caused_by: BulkdIndexResponseErrorCause
        }

        public struct BulkdIndexResponseErrorCause: Codable {
            public let type: String
            public let reason: String?
        }
    }
}

struct RootResponse: Codable {
    let version: Version

    struct Version: Codable {
        let number: String
    }
}

// public struct SearchResponse {
//     public let matches: [AggregateRecord]
//     public let totalMatches: Int

//     public init(matches: [AggregateRecord], totalMatches: Int) {
//         self.matches = matches
//         self.totalMatches = totalMatches
//     }
// }
