import Logging
import FPCore

import Async
import Vapor

final class FilesController: RouteCollection {
    private static let logger = Logger(label: "FindAPhoto.FilesController")
    let slideMaxHeightDimension = 1024

    func boot(routes: RoutesBuilder) throws {
        let files = routes.grouped("files")
        files.get("media", ":id", use: media)
        files.get("slides", ":id", use: slides)
        files.get("thumbs", ":id", use: thumbs)
    }


    func media(_ req: Request) throws -> EventLoopFuture<Response> {
        let id = req.parameters.get("id")!
        let pathId = PathUtils.escape(id)
        return try ElasticSearchClient(req.eventLoop)
            .term(0, 1, "_id", pathId)
            .flatMapThrowing { fpResponse in
                if fpResponse.total == 0 {
                    throw Abort(.notFound, reason: "Missing")
                }

                let fullPath = try PathUtils.toFullPath(id
                    .removingPercentEncoding!
                    .replacingOccurrences(of: "/", with: "\\"))
                if !FileManager.default.fileExists(atPath: fullPath) {
                    throw Abort(.notFound, reason: "Missing")
                }
                return req.fileio.streamFile(at: fullPath)
            }
    }

    func slides(_ req: Request) throws -> EventLoopFuture<Response> {
        let id = req.parameters.get("id")!
        let pathId = PathUtils.escape(id)
        return try ElasticSearchClient(req.eventLoop)
            .term(0, 1, "_id", pathId)
            .flatMapThrowing { fpResponse in
                if fpResponse.total == 0 {
                    throw Abort(.notFound, reason: "Missing")
                }

                let fullPath = try PathUtils.toFullPath(id
                    .removingPercentEncoding!
                    .replacingOccurrences(of: "/", with: "\\"))
                if !FileManager.default.fileExists(atPath: fullPath) {
                    throw Abort(.notFound, reason: "Missing")
                }

                // Create a temporary, scaled down image
                let media = fpResponse.hits.first!.media
                let slideFile = NSTemporaryDirectory() + "fp-slide-" + UUID().uuidString + ".jpg"
                defer { 
                    // Hack to delete the temp file without causing the response to be truncated.
                    Async.background {
                        do {
                            sleep(1)
                            try FileManagement.deleteFileIfPresent(slideFile)
                        } catch {
                            FilesController.logger.warning("Failed removing temp file: \(slideFile): \(error)")
                        }
                    }
                }

                if media.isImage {
                    try ImageSizing.resizeSingleImage(fullPath, slideFile, self.slideMaxHeightDimension)
                } else {
                    let frameFile = NSTemporaryDirectory() + "fp-frame-" + UUID().uuidString + ".jpg"
                    defer { 
                        do {
                            try FileManagement.deleteFileIfPresent(frameFile)
                        } catch {
                            FilesController.logger.warning("Failed removing temp file: \(frameFile): \(error)")
                        }
                    }

                    try ImageSizing.sizeVideoFrame(
                        fullPath, 
                        frameFile, 
                        slideFile, 
                        media.durationSeconds, 
                        self.slideMaxHeightDimension)
                }

                return req.fileio.streamFile(at: slideFile)
            }
    }

    func thumbs(_ req: Request) throws -> EventLoopFuture<Response> {
        let id = req.parameters.get("id")!
        let fullPath = PathUtils.toThumbFilePath(id.removingPercentEncoding!)
        if !FileManager.default.fileExists(atPath: fullPath) {
            throw Abort(.notFound, reason: "Missing")
        }

        return req.eventLoop.makeSucceededFuture(req.fileio.streamFile(at: fullPath))
    }
}
