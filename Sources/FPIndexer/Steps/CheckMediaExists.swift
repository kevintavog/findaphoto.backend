import Foundation
import FPCore

class CheckMediaExists {
    static let indexingClient = ElasticSearchIndexing(eventLoop)


    static func run(_ files: [FpFile]) {
        do {
            let pathToSignature = try indexingClient.signatures(files)
            for f in files {
                if let remoteSignature = pathToSignature[f.path] {
                    f.signatureMatches = f.signature == remoteSignature
                }
            }
        } catch {
            IndexingFailures.append("Check failed: \(error)")
        }
    }
}
