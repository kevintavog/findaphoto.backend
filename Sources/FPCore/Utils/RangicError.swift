import Foundation
import Vapor

public enum RangicError: Error {
    case invalidParameter(_ message: String)
    case unexpected(_ message: String)
    case notFound(_ message: String)
    case notSupported(_ message: String)
    case http(_ status: HTTPResponseStatus, _ message: String)
    case elasticSearch(_ status: Int, _ type: String, _ reason: String)
}

