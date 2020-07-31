import Vapor

public func configure(_ app: Application) throws {

// #if !os(Linux)
//     ContentConfiguration.global.use(encoder: JSONEncoder.custom(dates: .iso8601, format: .withoutEscapingSlashes), for: .json)
// #else
//     ContentConfiguration.global.use(encoder: JSONEncoder.custom(dates: .iso8601), for: .json)
// #endif

    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )

    // Clear any existing middleware.
    app.middleware = .init()
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    app.http.server.configuration.port = 5000
    app.http.server.configuration.hostname = "0.0.0.0"
    try routes(app)
}
