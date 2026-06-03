import Security
import Foundation

enum KeychainHelper {
    private static let service = "com.begleiter.app"
    private static let apiKeyAccount = "anthropic_api_key"

    static func saveAPIKey(_ key: String) {
        // UserDefaults primary (works in simulator without code signing)
        UserDefaults.standard.set(key, forKey: "begleiter_api_key")

        // Keychain secondary (works on physical devices)
        guard let data = key.data(using: .utf8) else { return }
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: apiKeyAccount
        ]
        SecItemDelete(query as CFDictionary)
        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: apiKeyAccount,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func loadAPIKey() -> String? {
        // Try Keychain first (physical device)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: apiKeyAccount,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess,
           let data = result as? Data,
           let key = String(data: data, encoding: .utf8),
           !key.isEmpty {
            return key
        }
        // Fall back to UserDefaults (simulator)
        return UserDefaults.standard.string(forKey: "begleiter_api_key")
    }

    static func deleteAPIKey() {
        UserDefaults.standard.removeObject(forKey: "begleiter_api_key")
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: apiKeyAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
