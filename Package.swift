// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "pgb",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.1"),
        .package(url: "https://github.com/soto-project/soto-s3-file-transfer.git", from: "2.2.0")
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
