// © 2025 Tomasz Sądej
// SPDX-License-Identifier: MIT

import Foundation
import ArgumentParser
import Logging

let logger = { Logger(label: "PGB") }()

@main
struct App: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pgb",
        abstract: "Postgres Backup Tool",
        version: "2025.3.10"
    )

    enum StorageType: String, ExpressibleByArgument {
        case s3, local
    }

    @Option(name: .long, help: .init("full path to pg_dump executable", valueName: "path"))
    var pgDumpPath: String = "/usr/bin/pg_dump"
    
    @Option(name: .shortAndLong, help: .init("storage location for backup file [s3, local]", valueName: "string"))
    var storage: StorageType = .s3
    
    @Option(name: .shortAndLong, help: .init("destination directory for backup file", valueName: "path"))
    var directory: String = ".backups/db/"

    @Option(name: .shortAndLong, help: .init("number of backups to retain [set 0 to keep all]", valueName: "int"))
    var keep: Int = 2

    @Flag(name: .long, help: "do not exclude public schema from backup")
    var keepPublicSchema: Bool = false

    @Flag(name: .long, help: "force HTTP/1 for S3 connections")
    var s3Http1: Bool = false

    @Option(name: .shortAndLong, help: .init(".env file", valueName: "path"))
    var env: String? = nil

    private var environment: Environment

    init () {
        environment = Environment()
    }

    private func upload(_ file: URL) async throws {
        switch storage {
        case .s3:
            let s3 = S3(
                endpoint: try environment.get("PGB_S3_ENDPOINT", require: true)!,
                region: try environment.get("PGB_S3_REGION", require: true)!,
                key: try environment.get("PGB_S3_KEY", require: true)!,
                secret: try environment.get("PGB_S3_SECRET", require: true)!,
                bucket: try environment.get("PGB_S3_BUCKET", require: true)!,
                httpVersion: s3Http1 ? .http1Only : .automatic
            )

            do {
                try await s3.send(file: file, directory: directory)

                if keep > 0 {
                    try await s3.cleanup(directory, keep: keep)
                }
            } catch {
                try await s3.done()

                print()
                logger.error(.init(stringLiteral: error.localizedDescription))

                throw ExitCode.failure
            }

            try await s3.done()
        case .local:
            let local = Local()

            try await local.send(file: file, directory: directory)

            if keep > 0 {
                try await local.cleanup(directory, keep: keep)
            }
        }
    }

    mutating func run() async throws {
        let fileManager: FileManager = .default

        if let env = self.env {
            try await environment.loadVariables(
                fromFile: env.hasPrefix("/") ? URL(fileURLWithPath: env) : URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent(env)
            )
        }

        if fileManager.fileExists(atPath: pgDumpPath) {
            let name = ISO8601DateFormatter.string(from: Date(), timeZone: .gmt, formatOptions: [.withFullDate, .withTime, .withTimeZone]) + ".pgb"
            let file = fileManager.temporaryDirectory.appendingPathComponent(name)

            let dump = Process()

            dump.executableURL = URL(fileURLWithPath: pgDumpPath)

            var arguments: [String] = ["-Fc", "-Z", "9", "-f", file.path(percentEncoded: false)]

            if !keepPublicSchema {
                arguments.append("--exclude-schema")
                arguments.append("public")
            }

            arguments.append(try environment.get("PGB_CONNECTION_URI", require: true)!)

            dump.arguments = arguments

            let pipe = Pipe()
            dump.standardOutput = pipe
            dump.standardError = pipe

            print("saving database to file...", terminator: " ")
            fflush(stdout)

            try dump.run()
            dump.waitUntilExit()

            if dump.terminationStatus == 0 {
                print("DONE", terminator: "\n\n")
                let size: Int64 = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize.map { Int64($0) }!
                
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useKB, .useMB, .useGB]
                formatter.countStyle = .file

                print("\(name) [\(formatter.string(fromByteCount: size))]", terminator: "\n\n")
                
                try await upload(file)

                if storage != .local {
                    try fileManager.removeItem(at: file)
                }
            } else {
                print("ERROR", terminator: "\n\n")

                logger.error(.init(stringLiteral: String(
                    data: pipe.fileHandleForReading.readDataToEndOfFile(),
                    encoding: .utf8
                )!))

                throw ExitCode.failure
            }
        } else {
            logger.error("pg_dump not found")

            throw ExitCode.failure
        }
    }
}
