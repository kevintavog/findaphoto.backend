import Foundation

public class FileManagement {
    static public func deleteFileIfPresent(_ path: String) throws {
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)  
        }
    }
}