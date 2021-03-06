// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tenderswift",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        // .library(
        //     name: "Tenderswift",
        //     targets: ["Tenderswift"]
        // )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.6.1"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
        .package(url: "https://github.com/AlanQuatermain/swift-nio-protobuf.git", .upToNextMinor(from: "0.1.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Tenderswift",
            dependencies: [
                "NIO",
                "TendermintCore",
                "NIOProtobuf"
            ]
        ),
        .target(
            name: "TendermintCore",
            dependencies: [
              "SwiftProtobuf"
            ]
        ),
        .testTarget(
            name: "TenderswiftTests",
            dependencies: ["Tenderswift"]),
    ]
)
