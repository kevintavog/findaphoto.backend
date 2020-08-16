// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "findaphoto",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .executable(name: "FindAPhoto", targets: ["FindAPhoto"]),
        .executable(name: "FPIndexer", targets: ["FPIndexer"]),
    ],
    dependencies: [
        // Async is not Linux compatible; I've made a local copy
        // .package(url: "https://github.com/duemunk/Async", from: "2.1.0"),
        // This package does not yet support ElasticSearch 7.x; I've made a local copy with changes instead
        // .package(url: "https://github.com/pksprojects/ElasticSwift.git", from: "1.0.0-alpha.11"),
        .package(url: "https://github.com/nsomar/Guaka.git", from: "0.4.1"),
        // This package doesn't build on Linux by default, a local copy has changes
        // .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.14.0"),

        // For ElasticSwift
        .package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.2"),
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.14.0")),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", .upToNextMajor(from: "2.6.1")),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", .upToNextMajor(from: "1.3.0")),
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.2.0")),
        .package(url: "https://github.com/adorkable/swift-log-format-and-pipe.git", from: "0.1.1"),
        .package(url: "https://github.com/swift-server/async-http-client.git", .upToNextMajor(from: "1.1.0")),
    ],
    targets: [
        .target(
            name: "FindAPhoto",
            dependencies: ["Async", "Guaka", "FPCore", "SwiftyJSON", 
                .product(name: "Vapor", package: "vapor"),
                .product(name: "LoggingFormatAndPipe", package: "swift-log-format-and-pipe")],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .target(
            name: "FPIndexer",
            dependencies: ["Async", "Guaka", "FPCore", "SwiftyJSON",
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "LoggingFormatAndPipe", package: "swift-log-format-and-pipe")],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .target(
            name: "FPCore",
            dependencies: [
                "ElasticSwift",
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                // .product(name: "ElasticSwiftCore", package: "ElasticSwift"),
                // .product(name: "ElasticSwiftNetworkingNIO", package: "ElasticSwift"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "Vapor", package: "vapor")]),
        .target(
            name: "ElasticSwift",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
            ]),
        .target(
            name: "Async",
            dependencies: []),
        .target(
            name: "SwiftyJSON",
            dependencies: []),

        .testTarget(name: "AppTests", dependencies: [
            .target(name: "FindAPhoto"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
