import Foundation
import FPCore

class CheckMediaExists {
    static let indexingClient = ElasticSearchIndexing(eventLoop)

    static func run(_ files: [FpFile]) {
        do {
            let pathToSignature = try indexingClient.signatures(files)
            for f in files {
                if let signatureDoc = pathToSignature[f.path] {
                    f.signatureMatches = f.signature == signatureDoc.signature
                    f.azureTagsExist = signatureDoc.azureTags != nil
                    f.clarifaiTagsExist = signatureDoc.clarifaiTags != nil
                }
            }
        } catch {
            IndexingFailures.append("Check failed: \(error)")
        }
    }
}
