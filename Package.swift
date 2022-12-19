// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RagiSmoothList",
    platforms: [.macOS(.v10_15), .iOS(.v14)],
    products: [
        .library(name: "RagiSmoothList", targets: ["RagiSmoothList"])
    ],
    targets: [
        .target(
            name: "RagiSmoothList",
            path: "Sources"
        )
    ],
    swiftLanguageVersions: [.v5]
)
