import Foundation

/// Secure file-based storage for OAuth tokens.
/// Uses Application Support directory with data protection.
/// This avoids repeated Keychain permission prompts during development.
enum KeychainService {
    private static let appDir: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("AdMobWidget", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static func fileURL(for key: String) -> URL {
        let safeKey = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return appDir.appendingPathComponent(".\(safeKey).dat")
    }

    static func save(key: String, data: Data) -> Bool {
        let url = fileURL(for: key)
        do {
            // XOR obfuscation (not encryption, but prevents casual reading)
            let obfuscated = obfuscate(data)
            try obfuscated.write(to: url, options: [.atomic, .completeFileProtection])
            // Set file to owner-only readable
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: url.path
            )
            return true
        } catch {
            print("KeychainService save error: \(error)")
            return false
        }
    }

    static func load(key: String) -> Data? {
        let url = fileURL(for: key)
        guard let obfuscated = try? Data(contentsOf: url) else { return nil }
        return obfuscate(obfuscated) // XOR is symmetric
    }

    @discardableResult
    static func delete(key: String) -> Bool {
        let url = fileURL(for: key)
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Convenience for strings

    static func saveString(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(key: key, data: data)
    }

    static func loadString(forKey key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Convenience for Codable

    static func saveCodable<T: Encodable>(_ value: T, forKey key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        return save(key: key, data: data)
    }

    static func loadCodable<T: Decodable>(forKey key: String) -> T? {
        guard let data = load(key: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Simple XOR obfuscation

    private static func obfuscate(_ data: Data) -> Data {
        // XOR key for basic obfuscation (not encryption)
        let keyBytes: [UInt8] = [0xA3, 0x7B, 0x4F, 0xD1, 0x8E, 0x52, 0xC6, 0x19,
                                  0xF4, 0x3D, 0x68, 0xB0, 0x25, 0x9A, 0xE7, 0x0C]
        var result = Data(count: data.count)
        for i in 0..<data.count {
            result[i] = data[i] ^ keyBytes[i % keyBytes.count]
        }
        return result
    }
}
