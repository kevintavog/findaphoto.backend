import FPCore
import Async

var runIndexerPrefix = ""

func runIndexerInBackground(reindex: Bool) {
    Async.background {
        runIndexer(reindex: reindex)
    }
}

func runIndexer(reindex: Bool) {
    var arguments: [String] = []
    if reindex {
        arguments.append("--reindex")
    }
    if runIndexerPrefix.count > 0 {
        arguments += ["-i", runIndexerPrefix]
    }
    if Aliases.aliasOverride.count > 0 {
        arguments += ["-a", Aliases.aliasOverride]
    }

    let process = ProcessInvoker.run(StandardPaths.indexerPath, arguments: arguments)
    if process.exitCode != 0 {
        logger.warning("Failed indexing: \(process.exitCode); error: '\(process.error)'")
        return
    }

    print(process.output)
    // Aliases have been updated, reload them
    try? Aliases.reload()
}
