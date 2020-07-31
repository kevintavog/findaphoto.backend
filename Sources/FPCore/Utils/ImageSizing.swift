import Foundation
import Logging

public class ImageSizing {
    private static let logger = Logger(label: "FpCore.ImageSizing")


    static public func resizeImages(_ imagePaths: [String], _ outputFolder: String, _ maxHeight: Int) throws {
        try vipsThumbnail([
            "-d",
            "--size=x\(maxHeight)",
            "-o",
            "\(outputFolder)%s.JPG[Q=98,optimize_coding,strip]",
            ] + imagePaths)
    }

    static public func resizeSingleImage(_ imagePath: String, _ outputFile: String, _ maxHeight: Int) throws {
        try vipsThumbnail([
            "-d",
            "--size=x\(maxHeight)",
            "-o",
            "\(outputFile)[Q=98,optimize_coding,strip]",
            imagePath
            ])
    }

    static public func sizeVideoFrame(_ videoPath: String, _ tempFile: String, _ outputFile: String, 
                                        _ durationSeconds: Double?, _ maxHeight: Int) throws {
        try ffmpegThumbnail([
            "-nostdin",
            "-loglevel",
            "fatal",
            "-i",
            videoPath,
            "-ss",
            durationSeconds ?? 0 > 1.0 ? "00:00:01.0" : "00:00:00.0",
            "-vframes",
            "1",
            tempFile,
        ])

        try resizeSingleImage(tempFile, outputFile, maxHeight)
    }

    static private func vipsThumbnail(_ arguments: [String]) throws {
        let process = ProcessInvoker.run(StandardPaths.vipsThumbnailPath, arguments: arguments)
        if process.exitCode != 0 {
            throw RangicError.unexpected("vipsThumbnail failed: \(process.exitCode); error: '\(process.error)'")
        }
    }

    static private func ffmpegThumbnail(_ arguments: [String]) throws {
        let process = ProcessInvoker.run(StandardPaths.ffmpegPath, arguments: arguments)
        if process.exitCode != 0 {
            throw RangicError.unexpected("ffmpeg failed: \(process.exitCode); error: '\(process.error)'")
        }
    }

}