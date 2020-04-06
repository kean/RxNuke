// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "RxNuke",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(name: "RxNuke", targets: ["RxNuke"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/kean/Nuke.git",
            from: "8.0.0"
        ),
        .package(
            url: "https://github.com/ReactiveX/RxSwift.git",
            from: "5.1.0"
        )
    ],
    targets: [
        .target(name: "RxNuke", dependencies: ["Nuke", "RxSwift"], path: "Source")
    ]
)
