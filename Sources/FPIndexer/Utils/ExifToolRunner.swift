import Foundation
import FPCore
import SwiftyJSON

public enum ExifToolError : Error {
    case failed(error: String)
}

// Run without waiting for it to exit
//  1. `-stay_open 1 -@ -`
//  2. Provide access to stdin & stdout
//
// Execute a comamand
//  1. `-a -j -g <path> -execute`
//  2. May need to flush buffer
//  3. \n after each argument (one argument per line)
//  4. Can optionally tie together with id: `-exeucteNNN`, with the response parroting `NNN` as `readyNNN`
//
//  When shutting down
//  1. `-stay_open 0`


public class ExifToolRunner {
    private let readyLength = "{ready}".count + 2
    private var invoker: ProcessInvoker? = nil
    private var currentOutput = Data()
    private let semaphore = DispatchSemaphore(value: 0)

    public func at(_ path: String) -> [String:JSON] {
        currentOutput = Data()

        if invoker == nil {
            invoker = ProcessInvoker.start(
                StandardPaths.exifToolPath,
                arguments: ["-stay_open", "1", "-@", "-"],
                { data in
                    self.currentOutput += data

                    let trimmedOutput = (String(data: data.suffix(self.readyLength), encoding: String.Encoding.utf8) ?? "")
                        .trimmingCharacters(in: .whitespaces)
                        .trimmingCharacters(in: .newlines)

                    if trimmedOutput.hasSuffix("{ready}") {
                        self.semaphore.signal()
                    }
                })
        }

        let args = ["-a", "-j", "-g", path, "-execute"]
        let input = args.joined(separator: "\n") + "\n"
        invoker!.writeToStdin(input)
        semaphore.wait()

        do {
            // Get rid of extra newlines, as the JSON parser doesn't care for them
            // And get rid of the trailing "{ready}"
            let strOutput = (String(data: currentOutput.dropLast(readyLength), encoding: .utf8) ?? "")
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: .newlines)
            if let data = strOutput.data(using: .utf8, allowLossyConversion: false) {
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
        } catch {
            IndexingFailures.append("ExifTool \(error) at \(path)")
        }
        return [String:JSON]()
    }

    public func close() {
        if let i = invoker {
            invoker = nil
            let args = ["-stay_open", "0"]
            i.writeToStdin(args.joined(separator: "\n") + "\n")
            let _ = i.waitForExit()
        }
    }
}
