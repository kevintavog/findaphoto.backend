import Foundation

public class PathUtils {
    static public func normalize(_ path: String) -> String {
        let forcedSlash = !path.hasPrefix("/") ? "/" : ""
        let norm = URL(fileURLWithPath: forcedSlash + path).standardizedFileURL.path
        if forcedSlash.count > 0 {
            return String(norm.dropFirst(1))
        }
        return norm
    }

    static public func toFullPath(_ aliasedPath: String) throws -> String {
        guard let firstSlash = aliasedPath.firstIndex(of: "\\") else {
            throw RangicError.invalidParameter("Can't find alias token: '\(aliasedPath)'")
        }
        let aliasIndex = String(aliasedPath[..<firstSlash])
        guard let aliasPath = Aliases.from(alias: aliasIndex) else {
            throw RangicError.invalidParameter("Can't find alias: \(aliasIndex)")
        }

        return unescape([aliasPath, String(aliasedPath[firstSlash...])].joined(separator: "/"))
    }

    static public func toAliasedPath(_ alias: String, _ path: String) -> String {
        return alias + "\\" + escape(String(normalize(path)))
    }

    static public func escape(_ path: String) -> String {
        return normalize(path).replacingOccurrences(of: "/", with: "\\")
    }

    static public func unescape(_ path: String) -> String {
        return normalize(path.replacingOccurrences(of: "\\", with: "/"))
    }

    static public func toThumbFilePath(_ aliasedPath: String) -> String {
        var thumbPath = unescape([StandardPaths.thumbnailDirectory, aliasedPath].joined(separator: "/"))
        thumbPath = toThumbFilename(thumbPath)
        return normalize(thumbPath)
    }

    static public func toThumbFilename(_ mediaFilename: String) -> String {
        var thumbName = mediaFilename
        if thumbName.uppercased().hasSuffix(".JPEG") {
            thumbName = String(thumbName.dropLast(".JPEG".count))
        }
        if !thumbName.uppercased().hasSuffix(".JPG") {
            thumbName += ".JPG"
        }
        return thumbName
    }

    static public func toThumbFolderPath(_ aliasedPath: String) -> String {
        let thumbPath = toThumbFilePath(aliasedPath)
        if let lastSlash = thumbPath.lastIndex(of: "/") {
            return String(thumbPath[...lastSlash])
        }
        return normalize(thumbPath)
    }
}
