// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenResponses",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "OpenResponses",
            targets: ["OpenResponses"]
        ),
        .library(
            name: "OpenResponsesSwiftUI",
            targets: ["OpenResponsesSwiftUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mattt/EventSource", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "OpenResponses",
            dependencies: [
                .product(name: "EventSource", package: "EventSource")
            ]
        ),
        .target(
            name: "OpenResponsesSwiftUI",
            dependencies: [
                "OpenResponses"
            ]
        ),
        .testTarget(
            name: "OpenResponsesCoreTests",
            dependencies: ["OpenResponses"]
        ),
        .testTarget(
            name: "OpenResponsesSwiftUITests",
            dependencies: ["OpenResponsesSwiftUI"]
        )
    ]
)
