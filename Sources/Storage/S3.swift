// © 2025 Tomasz Sądej
// SPDX-License-Identifier: MIT

import Foundation
import SotoS3
import SotoS3FileTransfer
import ArgumentParser

struct S3: Storage {
    private let bucket: String
    private let transfer: S3FileTransferManager
    
    init (endpoint: String, region: String, key: String, secret: String, bucket: String) {
        transfer = S3FileTransferManager(s3: SotoS3.S3(
            client: AWSClient(credentialProvider: .static(accessKeyId: key, secretAccessKey: secret)),
            region: Region(rawValue: region),
            endpoint: endpoint
        ))

        self.bucket = bucket
    }

    func send(file: URL, directory: String) async throws {
        var destination: String
        if directory.hasSuffix("/") {
            destination = directory + file.lastPathComponent
        } else {
            destination = directory + "/" + file.lastPathComponent
        }

        if destination.hasPrefix("/") {
            destination.trimPrefix("/")
        }

        print("uploading backup file to S3...", terminator: " ")
        fflush(stdout)

        do {
            try await transfer.copy(
                from: file.path(),
                to: S3File(url: "s3://\(bucket)/\(destination)")!
            )

            print("DONE")
        } catch {
            print("ERROR", terminator: "\n\n")

            var stderr = StandardError()
            print(error, to: &stderr)

            throw ExitCode.failure
        }
    }

    func cleanup(_ directory: String, keep: Int) async throws {
        var directory = directory
        if directory.hasPrefix("/") {
            directory.trimPrefix("/")
        }

        let dumps = try await transfer.listFiles(in: S3Folder(url: "s3://\(bucket)/\(directory)")!).filter { $0.file.extension == "pgb" }
        if dumps.count > keep {
            print("\nFound \(dumps.count) backups. Keeping \(keep) newest.", terminator: "\n\n")

            let count = dumps.count - keep
            for dump in dumps.min(count: count, sortedBy: { $0.file.name < $1.file.name }) {
                print("deleting \"", dump.file.name, "\"...", separator: "",  terminator: " ")
                fflush(stdout)
                
                try await transfer.delete(dump.file)
                print("DONE")
            }
        }
    }

    func done() async throws { try await transfer.s3.client.shutdown() }
}
