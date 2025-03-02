// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "pgb",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/soto-project/soto-s3-file-transfer.git", from: "2.1.0")
    ],
    targets: [
        .executableTarget(
            name: "pgb",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SotoS3FileTransfer", package: "soto-s3-file-transfer")
            ]
        )
    ]
)
