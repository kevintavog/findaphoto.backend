import Foundation
import NIOConcurrencyHelpers

import FPCore

public class Statistics {
    static let EmitIndexedCount = 500
    static var startTime = Date()
    static var folders = 0
    static var files = 0
    static var exifInvocations = 0
    static var indexed = 0
    static var thumbnails = 0
    static var lastFolder = ""
    static var lock = Lock()
    static var lastEmitIndexedCount = 0

    static func start() {
        startTime = Date()
    }

    static func stop() {
        emit("")
    }

    private static func emit(_ message: String) {
        lock.withLock {
            let durationSeconds = Int(Date().timeIntervalSince(startTime))
            print("\(message)\(durationSeconds) seconds, \(folders) folders, \(files) files. With "
                + "\(exifInvocations) exiftool invocations, \(indexed) items indexed and "
                + "\(thumbnails) thumbnails generated. \(IndexingFailures.count()) errors")
        }
    }

    static func completedFolder(_ folder: String) {
        lock.withLock {
            Statistics.lastFolder = folder
        }
    }

    static func add(folders: Int) {
        lock.withLock {
            Statistics.folders += folders
        }
    }

    static func add(files: Int) {
        lock.withLock {
            Statistics.files += files
        }
    }

    static func add(exifInvocations: Int) {
        lock.withLock {
            Statistics.exifInvocations += exifInvocations
        }
    }

    static func add(indexed: Int) {
        lock.withLock {
            Statistics.indexed += indexed
        }

        var emitProgress = false
        if (Statistics.indexed - lastEmitIndexedCount) > EmitIndexedCount {
            lock.withLock {
                emitProgress = (Statistics.indexed - lastEmitIndexedCount) > EmitIndexedCount
                if emitProgress {
                    lastEmitIndexedCount = (Statistics.indexed / EmitIndexedCount) * EmitIndexedCount
                }
            }
        }

        if emitProgress {
            emit("\(lastFolder): ")
        }
    }

    static func add(thumbnails: Int) {
        lock.withLock {
            Statistics.thumbnails += thumbnails
        }
    }
}
