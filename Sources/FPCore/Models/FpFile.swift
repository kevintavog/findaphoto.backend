import Foundation

public class FpFile: CustomStringConvertible {
    public let url: URL
    // The path is the relative path, prefixed by the alias and `/` -> `\`
    public let path: String
    public let length: Int
    public let modifiedDate: Date

    public var signature: String = ""
    public var signatureMatches: Bool = false


    public init(_ url: URL, _ path: String, _ length: Int, _ date: Date) {
        self.url = url
        self.path = path
        self.length = length
        self.modifiedDate = date
    }

    public var description: String {
        return "\(path); \(length) bytes, \(signature) [\(signatureMatches)]"
    }
}
