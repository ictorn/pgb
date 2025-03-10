// © 2025 Tomasz Sądej
// SPDX-License-Identifier: MIT

import Foundation
import ArgumentParser

struct Local: Storage {
    let fileManager: FileManager = .default

    func send(file: URL, directory: String) async throws {
        let to: URL
        if directory.first == "/" {
            to = URL(fileURLWithPath: directory)
        } else {
            to = URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent(directory)
        }

        print("moving backup file to destination directory...", terminator: " ")
        fflush(stdout)

        do {
            try fileManager.createDirectory(atPath: to.path(), withIntermediateDirectories: true)
        } catch {
            print("ERROR")

            logger.error(.init(stringLiteral: error.localizedDescription))

            throw ExitCode.failure
        }

        try fileManager.moveItem(at: file, to: to.appendingPathComponent(file.lastPathComponent))

        print("DONE")
    }

    func cleanup(_ directory: String, keep: Int) async throws {
        #if !canImport(Darwin)
            print("Backups cleanup for local storage is only availabe on macOS.")
            return
        #endif

        let destination: URL
        if directory.first == "/" {
            destination = URL(fileURLWithPath: directory)
        } else {
            destination = URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent(directory)
        }

        let dumps = try fileManager.contentsOfDirectory(
            at: destination,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ).filter { $0.pathExtension == "pgb" }

        if dumps.count > keep {
            print("\nFound \(dumps.count) backups. Keeping \(keep) newest.", terminator: "\n\n")

            let count = dumps.count - keep

            for file: URL in dumps.min(count: count, sortedBy: { $0.lastPathComponent < $1.lastPathComponent }) {
                let resource = try file.resourceValues(forKeys: [.isRegularFileKey])
                if resource.isRegularFile == true {
                    print("deleting \"", file.lastPathComponent, "\"...", separator: "",  terminator: " ")
                    fflush(stdout)

                    try fileManager.removeItem(at: file)
                    print("DONE")
                }
            }
        }
    }
}
