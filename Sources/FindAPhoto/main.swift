import FPCore
import Logging
import LoggingFormatAndPipe

import Guaka
import Vapor


let aliasOverrideFlag = Flag(
    shortName: "a",
    longName: "alias",
    type: String.self,
    description: "The path to use for the alias.",
    required: false)

let elasticSearchFlag = Flag(
    shortName: "e",
    longName: "elastic",
    type: String.self,
    description: "The URL for ElasticSearch (overrides configuration).",
    required: false)

let indexOverrideFlag = Flag(
    shortName: "i",
    longName: "index",
    type: String.self,
    description: "The prefix for the indices (for development)",
    required: false)


let flags = [aliasOverrideFlag, elasticSearchFlag, indexOverrideFlag]
let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount * 2)
let eventLoop = eventGroup.next()

let timestampFormatter = DateFormatter()
timestampFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
let logger = Logger(label: "FpIndexer") { _ in 
	return LoggingFormatAndPipe.Handler(
		formatter: BasicFormatter([.timestamp, .level, .metadata, .message], timestampFormatter: timestampFormatter),
		pipe: LoggerTextOutputStreamPipe.standardOutput
	)
}

let command = Command(usage: "FindAPhoto", flags: flags) { flags, args in
    StandardPaths.initFor(appName: "FindAPhoto")
    ElasticSearchClient.ServerUrl = FpConfiguration.instance.elasticSearchUrl
    if let elasticUrl = flags.getString(name: "elastic") {
        print("Overriding elastic URL to: \(elasticUrl)")
        ElasticSearchClient.ServerUrl = elasticUrl
    }
    if let indexPrefix = flags.getString(name: "index") {
        ElasticSearchClient.setIndexPrefix(indexPrefix)
        runIndexerPrefix = indexPrefix
    }
    if let aliasOverride = flags.getString(name: "alias") {
        Aliases.aliasOverride = aliasOverride
    }

    do {
        try ElasticSearchInit.run(eventLoop)
        try Aliases.initialize(eventLoop)
        print("ElasticSearch \(ElasticSearchClient.version); \(ElasticSearchClient.ServerUrl)")

        var env = Environment(name: "development", arguments: ["vapor"])
        try LoggingSystem.bootstrap(from: &env)
        let app = Application(env)

        // Oddly, invoking shutdown times out and reports an error (after an API call is made).
        // defer { app.shutdown() }
        try configure(app)
        try app.run()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed server: \(error)")
    }
}

command.execute()
