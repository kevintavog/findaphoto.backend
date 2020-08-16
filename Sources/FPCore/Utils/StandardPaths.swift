import Foundation

public class StandardPaths {
    static public private(set) var homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path

    // var LogDirectory string
    static public private(set) var configDirectory = ""
    static public private(set) var configFilename = "rangic.findaphotoService"
    static public private(set) var thumbnailDirectory = ""
    static public private(set) var exifToolPath = ""
    static public private(set) var vipsThumbnailPath = ""
    static public private(set) var ffmpegPath = ""

    // var ExecutingDirectory string
    // var IndexerPath string
    // var MediaClassifierPath string

    static public func initFor(appName: String) {
#if !os(Linux)
        configDirectory = [homeDirectory, "Library", "Preferences"].joined(separator: "/")
        thumbnailDirectory = [homeDirectory, "Library", "Application Support", "Rangic", "FindAPhoto", "thumbnails"].joined(separator: "/")

        exifToolPath = "/usr/local/bin/exiftool"
        ffmpegPath = "/usr/local/bin/ffmpeg"
        vipsThumbnailPath = "/usr/local/bin/vipsthumbnail"
#elseif os(Linux)
        configDirectory = [homeDirectory, ".findaphoto"].joined(separator: "/")
        thumbnailDirectory = [homeDirectory, ".findaphoto", "thumbnails"].joined(separator: "/")

        exifToolPath = "/usr/bin/exiftool"
        ffmpegPath = "/usr/bin/ffmpeg"
        vipsThumbnailPath = "/usr/bin/vipsthumbnail"
#endif
    }
}
