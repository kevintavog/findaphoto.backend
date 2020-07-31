import Foundation

public class ProcessInvoker {
    public let output: String
    public let error: String
    public let exitCode: Int32

    static public func run(_ path: String, arguments: [String]) -> ProcessInvoker {
        let result = ProcessInvoker.invoke(path, arguments: arguments)
        let process = ProcessInvoker(output: result.output, error: result.error, exitCode: result.exitCode)
        return process
    }

    private init(output: String, error: String, exitCode: Int32) {
        self.output = output
        self.error = error
        self.exitCode = exitCode
    }

    static private func invoke(_ path: String, arguments: [String]) ->
                (output: String, error: String, exitCode: Int32, exitReason: Process.TerminationReason) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = arguments

        var outputData = Data()
        let outputPipe = Pipe()
        var errorData = Data()
        let errorPipe = Pipe()

        let stdoutHandler: (FileHandle) -> Void = { handler in
            let data = handler.availableData
            if data.isEmpty {
                return
            }
            outputData.append(data)
        }

        let stderrHandler: (FileHandle) -> Void = { handler in
            let data = handler.availableData
            if data.count == 0 {
                return
            }
            errorData.append(handler.availableData)
        }

        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.readabilityHandler = stdoutHandler

        task.standardError = errorPipe
        errorPipe.fileHandleForReading.readabilityHandler = stderrHandler

        // This executable may depend on another executable in the same folder - 
        // make sure the path includes the executable folder
        // task.environment = ["PATH": path.deletingLastPathComponent]

// let startTime = Date()
        var runError: Error? = nil
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            runError = error
        }
// print("PI: \(path) \(arguments.joined(separator: " ")) -> \(Int(Date().timeIntervalSince(startTime)))")

        let output = String(data: outputData, encoding: String.Encoding.utf8) ?? ""
        let error = String(data: errorData, encoding: String.Encoding.utf8) ?? ""
        if let err = runError {
            return (output + "\n" + error, "\(err)", -1, Process.TerminationReason.uncaughtSignal)
        }
        return (output, error, task.terminationStatus, task.terminationReason)
    }
}
