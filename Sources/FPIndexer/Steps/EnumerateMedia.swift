import Foundation
import FPCore

class EnumerateMedia {
    static let supportedFileExtensions: Set<String> = [
        "JPEG",
        "JPG",
        "M4V",
        "MP4",
        "PNG",
    ]


    static func at(_ path: URL, _ alias: String, _ available: (_ folder: URL, _ files: [FpFile]) -> Void) throws {
        if !FileManager.default.fileExists(atPath: path.path) {
            throw RangicError.notFound("No such folder: \(path.path)")
        }
        at(path, path, alias, available)
    }

    static private func at(_ base: URL, _ path: URL, _ alias: String, _ available: (_ folder: URL, _ files: [FpFile]) -> Void) {
        let allKeys = [URLResourceKey.contentModificationDateKey, URLResourceKey.fileSizeKey, 
                URLResourceKey.isDirectoryKey, URLResourceKey.isRegularFileKey]

        do {
            let all = try FileManager.default.contentsOfDirectory(
                at: path,
                includingPropertiesForKeys: allKeys,
                options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)

            var dirs = [URL]()
            var files = [FpFile]()
            for f in all {
                let values = try f.resourceValues(forKeys: Set(allKeys))
                if values.isDirectory ?? false {
                    dirs.append(f)
                } else if values.isRegularFile ?? false {
                    if supportedFileExtensions.contains(f.pathExtension.uppercased()) {
                        let relative = PathUtils.toAliasedPath(alias, String(f.path.dropFirst(base.path.count + 1)))
                        files.append(FpFile(f, relative, values.fileSize!, values.contentModificationDate!))
                    }
                }
            }

            if files.count > 0 {
                Statistics.add(files: files.count)
                available(path, files)
            }

            for child in dirs.sorted(by:{ $0.path < $1.path }) {
                Statistics.add(folders: 1)
                at(base, child, alias, available)
            }
        } catch {
            IndexingFailures.append("Enumerator failed at \(path): \(error)")
        }
    }
}
