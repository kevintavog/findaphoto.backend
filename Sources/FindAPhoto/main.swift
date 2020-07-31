import FPCore
import Guaka
import Vapor


let elasticSearchFlag = Flag(
    shortName: "e",
    longName: "elastic",
    type: String.self,
    description: "The URL for ElasticSearch.",
    required: true)

let flags = [elasticSearchFlag]
let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount * 2)
let eventLoop = eventGroup.next()

let command = Command(usage: "FindAPhoto", flags: flags) { flags, args in
    ElasticSearchClient.ServerUrl = flags.getString(name: "elastic")!

    do {
        StandardPaths.initFor(appName: "FindAPhoto")
        try ElasticSearchInit.run(eventLoop)
        try Aliases.initialize(eventLoop)
        print("ElasticSearch \(ElasticSearchClient.version); \(ElasticSearchClient.ServerUrl)")

        var env = try Environment.detect()
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
