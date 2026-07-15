// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoneyMark",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MoneyMark",
            targets: ["MoneyMark"]
        )
    ],
    targets: [
        .target(
            name: "MoneyMark",
            path: "MoneyMark",
            exclude: ["Resources/Info.plist"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MoneyMarkTests",
            dependencies: ["MoneyMark"],
            path: "MoneyMarkTests"
        )
    ]
)
