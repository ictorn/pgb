import Foundation
import SotoS3
import SotoS3FileTransfer

struct S3 {
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

    func send(file: URL, directory: String? = nil) async throws {
        var destination: String = file.lastPathComponent
        if var directory = directory {
            if directory.last != "/" {
                destination = "/" + destination
            }
            if directory.first == "/" {
                directory.removeFirst()
            }
            destination = directory + destination
        }

        try await transfer.copy(
            from: file.path(),
            to: S3File(url: "s3://\(bucket)/\(destination)")!
        )
    }
    
    func done() async throws { try await transfer.s3.client.shutdown() }
}
