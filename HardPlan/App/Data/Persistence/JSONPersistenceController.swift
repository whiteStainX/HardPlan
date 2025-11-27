//
//  JSONPersistenceController.swift
//  HardPlan
//
//  Created in Phase 1 to manage JSON-based persistence.

import Foundation

final class JSONPersistenceController {
    private let fileManager: FileManager
    private let documentsDirectory: URL
    private let queue: DispatchQueue

    init(
        fileManager: FileManager = .default,
        directory: URL? = nil,
        queue: DispatchQueue = DispatchQueue(label: "com.hardplan.persistence", qos: .utility)
    ) {
        self.fileManager = fileManager
        self.documentsDirectory = directory ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        self.queue = queue
    }

    func save<T: Codable>(_ object: T, to filename: String) {
        queue.sync {
            let url = fileURL(for: filename)
            do {
                let data = try JSONEncoder().encode(object)
                try ensureDirectoryExists(for: url)
                try data.write(to: url, options: .atomic)
            } catch {
                print("JSONPersistenceController save error: \(error)")
            }
        }
    }

    func load<T: Codable>(from filename: String) -> T? {
        queue.sync {
            let url = fileURL(for: filename)
            guard fileManager.fileExists(atPath: url.path) else { return nil }

            do {
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("JSONPersistenceController load error: \(error)")
                return nil
            }
        }
    }

    func delete(filename: String) {
        queue.sync {
            let url = fileURL(for: filename)
            guard fileManager.fileExists(atPath: url.path) else { return }

            do {
                try fileManager.removeItem(at: url)
            } catch {
                print("JSONPersistenceController delete error: \(error)")
            }
        }
    }

    private func fileURL(for filename: String) -> URL {
        documentsDirectory.appendingPathComponent(filename)
    }

    private func ensureDirectoryExists(for url: URL) throws {
        let directoryURL = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
}
