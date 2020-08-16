import Foundation

public struct ProcessResult {
    public let output: String
    public let error: String
    public let exitCode: Int32
    public let terminationReason: Process.TerminationReason

    fileprivate init(_ output: String, _ error: String, _ exitCode: Int32, _ terminationReason: Process.TerminationReason) {
        self.output = output
        self.error = error
        self.exitCode = exitCode
        self.terminationReason = terminationReason
    }
}

public class ProcessInvoker {
    private let process = Process()
    private let outputDataAvailable: ((_ data: Data) -> Void)?

    private var outputData = Data()
    private var errorData = Data()
    public private(set) var runError: Error? = nil

    private init(_ block: ((_ data: Data) -> Void)?) {
        self.outputDataAvailable = block
    }

    // Runs the command, waits for it to exit and returns the results
    static public func run(_ path: String, arguments: [String]) -> ProcessResult {
        let p = start(path, arguments: arguments, nil)
        if let err = p.runError {
            return ProcessResult("", "\(err)", -1, Process.TerminationReason.uncaughtSignal)
        }

        return p.waitForExit()
    }

    // Runs the command, returning without waiting for the command to exit
    // Check `runError` to ensure this `start` method succeeded
    // Call `waitForExit` to wait for the process to exit
    static public func start(_ path: String, arguments: [String], _ block: ((_ data: Data) -> Void)?) -> ProcessInvoker {
        let pi = ProcessInvoker(block)
        pi.start(path, arguments)
        return pi
    }

    private func start(_ path: String, _ arguments: [String]) {
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments

        let outputPipe = Pipe()
        let stdoutHandler: (FileHandle) -> Void = { handler in
            let data = handler.availableData
            if data.isEmpty {
                return
            }
            if let outputCallback = self.outputDataAvailable {
                outputCallback(data)
            } else {
                self.outputData.append(data)
            }
        }

        let errorPipe = Pipe()
        let stderrHandler: (FileHandle) -> Void = { handler in
            let data = handler.availableData
            if data.count == 0 {
                return
            }
            self.errorData.append(handler.availableData)
        }

        process.standardInput = Pipe()
        process.standardOutput = outputPipe
        outputPipe.fileHandleForReading.readabilityHandler = stdoutHandler
        process.standardError = errorPipe
        errorPipe.fileHandleForReading.readabilityHandler = stderrHandler

        do {
            try process.run()
        } catch {
            runError = error
        }
    }

    public func writeToStdin(_ input: String) {
        let filehandle = (process.standardInput as! Pipe).fileHandleForWriting
        filehandle.write(input.data(using: .utf8)!)
        try? filehandle.synchronize()
    }

    public func waitForExit() -> ProcessResult {
        process.waitUntilExit()
        let output = String(data: outputData, encoding: String.Encoding.utf8) ?? ""
        let error = String(data: errorData, encoding: String.Encoding.utf8) ?? ""
        try? (process.standardOutput as! Pipe).fileHandleForReading.close()
        try? (process.standardError as! Pipe).fileHandleForReading.close()

        if let err = runError {
            return ProcessResult(output + "\n" + error, "\(err)", -1, Process.TerminationReason.uncaughtSignal)
        }
        return ProcessResult(output, error, process.terminationStatus, process.terminationReason)
    }
}
