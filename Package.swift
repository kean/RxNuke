// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "RxNuke",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "RxNuke", targets: ["RxNuke"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/kean/Nuke.git",
            from: "11.0.0"
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
