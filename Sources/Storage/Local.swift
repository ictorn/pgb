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

        print("copying backup file to destination directory...", terminator: " ")
        fflush(stdout)

        do {
            try fileManager.createDirectory(atPath: to.path(), withIntermediateDirectories: true)
        } catch {
            print("ERROR")

            var stderr = StandardError()
            print(error, to: &stderr)

            throw ExitCode.failure
        }

        try fileManager.copyItem(at: file, to: to.appendingPathComponent(file.lastPathComponent))

        print("DONE")
    }

    func cleanup(_ directory: String, keep: Int) async throws {
        /// TODO
    }
}
