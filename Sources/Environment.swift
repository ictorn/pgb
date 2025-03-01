import Foundation

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
