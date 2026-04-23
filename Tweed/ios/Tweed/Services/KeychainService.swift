import Foundation
import Security

/// Stores the Plaid "linked" flag in the iOS Keychain.
/// For MVP we just track whether the user has completed Link;
/// the actual access token lives on the backend.
final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private let service = "com.tweed.app"
    private let linkedKey = "plaid_linked"

    func hasAccessToken() -> Bool {
        return load(key: linkedKey) != nil
    }

    func markLinked() {
        save(key: linkedKey, value: "1")
    }

    func clear() {
        delete(key: linkedKey)
    }

    // MARK: - Private helpers

    private func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData:   data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func load(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
