// © 2025 Tomasz Sądej
// SPDX-License-Identifier: MIT

import Foundation

protocol Storage {
    func send(file: URL, directory: String) async throws
    func cleanup(_ directory: String, keep: Int) async throws
}
