// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "cal-read",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "cal-read",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            // Embeds Info.plist so macOS can prompt for Calendar access when
            // cal-read runs outside a terminal app. See the comment there.
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Info.plist",
                ]),
            ]
        ),
    ]
)
