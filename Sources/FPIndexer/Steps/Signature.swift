import Foundation
import Crypto

import FPCore

class Signature {
    static private let bytesForSignature = 10 * 1024

    static func calculate(_ files: [FpFile]) {
        for f in files {
            if let filehandle = FileHandle(forReadingAtPath: f.url.path) {
                var hasher = SHA256()
                hasher.update(data: filehandle.readData(ofLength: bytesForSignature))
                filehandle.seek(toFileOffset: UInt64(f.length - bytesForSignature))
                hasher.update(data: filehandle.readData(ofLength: bytesForSignature))
                let digest = hasher.finalize()
                f.signature = digest.map { String(format: "%02hhx", $0) }.joined()
            } else {
                IndexingFailures.append("Can't read \(f.url.path)")
            }
        }
    }
}
