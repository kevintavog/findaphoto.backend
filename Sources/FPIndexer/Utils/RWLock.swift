import Foundation

final class RWLock {
    private var lock: pthread_rwlock_t

    // MARK: Lifecycle
    deinit {
        pthread_rwlock_destroy(&lock)
    }

    public init() {
        lock = pthread_rwlock_t()
        pthread_rwlock_init(&lock, nil)
    }

    private func unlock() {
        pthread_rwlock_unlock(&lock)
    }

    private func writeLock() {
        pthread_rwlock_wrlock(&lock)
    }

    private func readLock() {
        pthread_rwlock_rdlock(&lock)
    }

    public func read(_ closure: () -> Void) {
        readLock()
        closure()
        unlock()
    }

    public func write(_ closure: () -> Void) {
        writeLock()
        closure()
        unlock()
    }
}
