// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RxNuke",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11),
        .tvOS(.v11),
        .watchOS(.v4)
    ],
    products: [
        .library(name: "RxNuke", targets: ["RxNuke"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/kean/Nuke.git",
            from: "10.0.0"
        ),
        .package(
            url: "https://github.com/ReactiveX/RxSwift.git",
            .upToNextMajor(from: "6.0.0")
        )
    ],
    targets: [
        .target(name: "RxNuke", dependencies: ["Nuke", "RxSwift"], path: "Source")
    ]
)
