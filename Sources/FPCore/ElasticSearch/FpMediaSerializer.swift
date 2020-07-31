import Foundation

import ElasticSwift

public func getFpMediaSerializer() -> Serializer {
    let serializer = DefaultSerializer()
    serializer.encoder.dateEncodingStrategy = .iso8601
// #if !os(Linux)
//     serializer.encoder.outputFormatting = .withoutEscapingSlashes
// #endif
    serializer.decoder.dateDecodingStrategy = .iso8601
    return serializer
}