import Foundation
import FPCore

class IndexMedia {
    static let batchSize = 100

    static var rwLock = RWLock()
    static var pending = [FpMedia]()

    static let indexingClient = ElasticSearchIndexing(eventGroup.next())

    static func run(_ files: [FpMedia]) {
        var countPending = 0
        rwLock.write({
            pending.append(contentsOf: files)
            countPending = pending.count
        })

        if countPending > batchSize {
            var batch = [FpMedia]()
            rwLock.write({
                batch = pending
                pending.removeAll(keepingCapacity: true)
            })
            index(batch)
        }
    }

    static func finish() {
        if pending.count > 0 {
            index(pending)
            pending.removeAll()
        }
    }

    static private func index(_ items: [FpMedia]) {
        Statistics.add(indexed: items.count)
        do {
            let response = try indexingClient.index(items)
            if response.errors {
                for i in response.items {
                    if let failure = i.failure {
                        IndexingFailures.append("FAILED indexing: \(failure.id); type=\(failure.type); "
                            + "cause=\(failure.cause)")
                    }
                }
            }

            TagMedia.enqueue(items)
        } catch {
            IndexingFailures.append("Failed indexing \(error)")
        }
    }
}
