
public class IndexingFailures {
    static private let rwLock = RWLock()
    static private var backingStore = [String]()

    static public func append(_ val: String) {
        rwLock.write({ backingStore.append(val) })
    }

    static public func count() -> Int {
        var count = 0
        rwLock.read( { count = backingStore.count })
        return count
    }

    static public func all() -> [String] {
        var all = [String]()
        rwLock.read({ all = backingStore })
        return all
    }
}
