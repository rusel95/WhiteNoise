//
//  KeychainService.swift
//  WhiteNoise
//
//  Minimal Keychain wrapper for storing sensitive values that should not
//  be user-tamperable (e.g., entitlement override dates).
//  Uses kSecAttrAccessibleWhenUnlockedThisDeviceOnly — data is not backed
//  up to iCloud and is inaccessible while the device is locked.
//

import Foundation
import Security

enum KeychainService {

    // MARK: - Date Storage

    static func saveDate(_ date: Date, forKey key: String) {
        let data = withUnsafeBytes(of: date.timeIntervalSince1970) { Data($0) }
        save(data: data, forKey: key)
    }

    static func loadDate(forKey key: String) -> Date? {
        guard let data = load(forKey: key),
              data.count == MemoryLayout<Double>.size else { return nil }
        let interval = data.withUnsafeBytes { $0.load(as: Double.self) }
        return Date(timeIntervalSince1970: interval)
    }

    static func deleteValue(forKey key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: bundleIdentifier
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            LoggingService.log("⚠️ KeychainService.deleteValue - Failed for key '\(key)', status: \(status)")
        }
    }

    // MARK: - Private

    private static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.whitenoise.app"
    }

    private static func save(data: Data, forKey key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: bundleIdentifier,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData: data
        ]

        // Try to update first, then add
        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
        if updateStatus == errSecItemNotFound {
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            if addStatus != errSecSuccess {
                LoggingService.log("⚠️ KeychainService.save - SecItemAdd failed for key '\(key)', status: \(addStatus)")
            }
        } else if updateStatus != errSecSuccess {
            LoggingService.log("⚠️ KeychainService.save - SecItemUpdate failed for key '\(key)', status: \(updateStatus)")
        }
    }

    private static func load(forKey key: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: bundleIdentifier,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
}
