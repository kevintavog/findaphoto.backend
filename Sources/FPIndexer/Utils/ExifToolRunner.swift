import FPCore
import SwiftyJSON

public enum ExifToolError : Error {
    case failed(error: String)
}

public class ExifToolRunner {
    static public func at(_ path: String) -> [String:JSON] {
        do {
            let out = try runExifTool(["-a", "-j", "-g", path])
            if let data = out.data(using: .utf8, allowLossyConversion: false) {
                let exifItems = try JSON(data: data)
                var namesToExif = [String:JSON]()
                for c in exifItems.arrayValue {
                    if let filename = c["File"]["FileName"].string {
                        namesToExif[filename] = c
                    } else {
                        IndexingFailures.append("ExifTool failed getting filename at \(path)")
                    }
                }
                return namesToExif
            } else {
                IndexingFailures.append("ExifTool failed converting string to data at \(path)")
            }
            return [String:JSON]()
        } catch {
            IndexingFailures.append("ExifTool \(error) at \(path)")
            return [String:JSON]()
        }
    }

    static private func runExifTool(_ arguments: [String]) throws -> String {
        let process = ProcessInvoker.run(StandardPaths.exifToolPath, arguments: arguments)
        if process.exitCode == 0 {
            return process.output
        }

        throw ExifToolError.failed(error: "exiftool failed: \(process.exitCode); error: '\(process.error)'")
    }
}
