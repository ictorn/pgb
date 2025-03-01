import Foundation
import ArgumentParser

@main
struct App: AsyncParsableCommand {
    static var _commandName: String { "pgb" }

    enum StorageType: String, ExpressibleByArgument {
        case s3, local
    }

    @Option(name: .long, help: .init("path to pg_dump executable", valueName: "path"))
    var pgDumpPath: String = "/dump"
    
    @Option(name: .long, help: .init("dump filename prefix", valueName: "value"))
    var prefix: String? = nil
    
    @Option(name: .shortAndLong, help: .init("storage to upload dumped file [s3, local]", valueName: "value"))
    var storage: StorageType = .s3
    
    @Option(name: .shortAndLong, help: .init("destination directory for dumped file", valueName: "path"))
    var directory: String = ".backups/db/"
    
    @Option(name: .shortAndLong, help: "number of backups to keep [set 0 to keep all]")
    var keep: UInt8 = 2

    private let env: Environment
    
    init () {
        env = Environment()
    }

    private func upload(_ file: URL) async throws {
        switch storage {
        case .s3:
            let s3 = S3(
                endpoint: try env.get("PGB_S3_ENDPOINT", require: true)!,
                region: try env.get("PGB_S3_REGION", require: true)!,
                key: try env.get("PGB_S3_KEY", require: true)!,
                secret: try env.get("PGB_S3_SECRET", require: true)!,
                bucket: try env.get("PGB_S3_BUCKET", require: true)!
            )
            
            print("uploading dump file to S3...", terminator: " ")
            fflush(stdout)
            
            do {
                try await s3.send(file: file, directory: directory)
                print("DONE")
            } catch {
                print("ERROR", terminator: "\n\n")
                print(error)
            }
            
            try await s3.done()

        case .local:
            let fileManager: FileManager = .default
            
            let to: URL
            if directory.first == "/" {
                to = URL(fileURLWithPath: directory)
            } else {
                to = URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent(directory)
            }

            try fileManager.copyItem(at: file, to: to.appendingPathComponent(file.lastPathComponent))
        }
    }

    func run() async throws {
        let fileManager: FileManager = .default

        if fileManager.fileExists(atPath: pgDumpPath) {
            let date = ISO8601DateFormatter()
            date.timeZone = TimeZone(abbreviation: "UTC")
            
            var name: String = date.string(from: Date()) + ".pg";
            if let prefix = prefix {
                name = prefix + "_" + name
            }
            
            let file = URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent(name)

            let dump = Process()

            dump.executableURL = URL(fileURLWithPath: pgDumpPath)
            dump.arguments = ["-Fc", "-Z", "9", "--exclude-schema", "public", "-f", file.path(percentEncoded: false), try env.get("PGB_CONNECTION_URI", require: true)!]

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

                print("\(file.lastPathComponent) [\(formatter.string(fromByteCount: size))]", terminator: "\n\n")
                
                try await upload(file)
                
                try fileManager.removeItem(at: file)
            } else {
                print("ERROR", terminator: "\n\n")
                print(String(
                    data: pipe.fileHandleForReading.readDataToEndOfFile(),
                    encoding: .utf8
                )!)
            }
        } else {
            print("pg_dump not found")
        }
    }
}
