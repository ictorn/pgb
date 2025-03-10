// © 2025 Tomasz Sądej
// SPDX-License-Identifier: MIT

import Foundation

internal extension Character {
    var isAlphanumeric: Bool { self.isLetter || self.isNumber }
}

private struct DotEnv {
    private let file: URL

    init(_ url: URL) {
        self.file = url
    }

    private func isValid(key: String) -> Bool {
        if key.isEmpty {
            return false
        }

        for (index, char) in key.enumerated() {
            if index == 0 && char.isNumber {
                return false
            }

            if !char.isAlphanumeric && char != "_" {
                return false;
            }
        }

        return true;
    }

    func parse() async throws -> [String: String] {
        var variables: [String: String] = [:]

        #if canImport(Darwin)
        for try await line in file.lines where !line.isEmpty {
            let substrings = line.split(separator: "=", maxSplits: 1)

            let key: String = String(substrings.first ?? "")
            let value: String = String(substrings.last ?? "")

            if value.isEmpty || !isValid(key: key)  {
                continue
            }

            variables.updateValue(value, forKey: key)
        }
        #endif

        return variables
    }
}

struct Environment: Decodable {
    private var variables: [String: String] = [:]
    
    private struct Error: Swift.Error {
        enum ErrorType {
            case missingRequiredVariable
        }

        let type: ErrorType
        let description: String?

        init(_ type: ErrorType, description: String? = nil) {
            self.type = type
            self.description = description
        }
    }

    init() {
        for item in ProcessInfo.processInfo.environment {
            variables[item.key.uppercased()] = item.value
        }
    }

    mutating func loadVariables(fromFile url: URL) async throws {
        for variable in try await DotEnv(url).parse() {
            variables.updateValue(variable.value, forKey: variable.key.uppercased())
        }
    }

    func get(_ string: String, require: Bool = false) throws -> String? {
        let key = string.uppercased()
        let value = variables[key]

        if require && value == nil {
            throw Error(.missingRequiredVariable, description: "env variable $\(key) does not exists")
        }

        return value
    }

    func get<T: LosslessStringConvertible>(_ string: String, as: T.Type, require: Bool = false) throws -> T? {
        let key = string.uppercased()
        let value = variables[key].map { T($0) } ?? nil

        if require && value == nil {
            throw Error(.missingRequiredVariable, description: "env variable $\(key) does not exists")
        }

        return value
    }
}
