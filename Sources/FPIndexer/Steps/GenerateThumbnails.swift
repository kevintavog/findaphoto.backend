import Foundation
import FPCore

class GenerateThumbnails {
    static let maxThumbnailHeight = 200

    static func initialize() throws {
        try FileManager.default.createDirectory(
            atPath: StandardPaths.thumbnailDirectory, withIntermediateDirectories: true)
    }

    static func run(_ folder: URL, _ media: [FpMedia]) {
        do {
            let thumbPath = PathUtils.toThumbFolderPath(media[0].path)
            try FileManager.default.createDirectory(atPath: thumbPath, withIntermediateDirectories: true)
            let existingFiles = try FileManager.default.contentsOfDirectory(atPath: thumbPath).map { $0.uppercased() }

            let images = media.filter { $0.isImage }
            let videos = media.filter { $0.isVideo }
            let missingImages = try images
                .filter { return !existingFiles.contains(PathUtils.toThumbFilename($0.filename).uppercased()) }
                .map { try PathUtils.toFullPath($0.path)}

            if missingImages.count > 0 {
                try ImageSizing.resizeImages(missingImages, thumbPath, maxThumbnailHeight)
            }


            let missingVideos = videos
                .filter { return !existingFiles.contains(PathUtils.toThumbFilename($0.filename).uppercased()) }
            for vm in missingVideos {
                let tempFile = NSTemporaryDirectory() + "fp-" + UUID().uuidString + ".JPG"
                defer { 
                    do {
                        try FileManagement.deleteFileIfPresent(tempFile)
                    } catch {
                        IndexingFailures.append("Failed removing temp file: \(tempFile): \(error)")
                    }
                }

                try ImageSizing.sizeVideoFrame(
                    PathUtils.toFullPath(vm.path),
                    tempFile,
                    PathUtils.toThumbFilePath(vm.path),
                    vm.durationSeconds,
                    maxThumbnailHeight)
            }

            Statistics.add(thumbnails: missingImages.count + missingVideos.count)

        } catch {
            IndexingFailures.append("Thumbnail generation: \(error); \(folder.path)")
        }
    }
}
