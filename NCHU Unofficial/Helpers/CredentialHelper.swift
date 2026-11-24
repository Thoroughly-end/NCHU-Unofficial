//
//  KeyChainHelper.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/3.
//

import Foundation
import Security

class CredentialHelper {
    static let shared = CredentialHelper()
    
    private let service = "com.nchu.unofficial"
    private let usernameKey = "nchu_username"
    private let server = "ccidp.nchu.edu.tw"
    
    // 🆕 添加一個標記，檢查是否已遷移到 Internet Password
    @UserDefault(key: "hasM igratedToInternetPassword", defaultValue: false)
    private var hasMigrated: Bool
    
    func saveCredentials(username: String, password: String) -> Bool {
        // 🆕 優先使用 Internet Password 方式儲存
        let internetSaved = saveAsInternetPassword(username: username, password: password)
        
        // 也保留舊的方式以防萬一（可選）
        guard saveUsername(username) else {
            print("Fail to save username")
            return false
        }
        
        print("save credential successfully")
        hasMigrated = true
        return internetSaved
    }
    
    // 🆕 新方法：使用 kSecClassInternetPassword 儲存
    private func saveAsInternetPassword(username: String, password: String) -> Bool {
        // 先刪除舊的
        deleteInternetPassword(for: username)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecAttrAccount as String: username,
            kSecAttrPort as String: 443,
            kSecAttrProtocol as String: kSecAttrProtocolHTTPS,
            kSecAttrAuthenticationType as String: kSecAttrAuthenticationTypeHTMLForm,
            kSecValueData as String: password.data(using: .utf8)!,
            kSecAttrLabel as String: "中興大學入口網站",
            kSecAttrDescription as String: "NCHU Portal Login",
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Saved as Internet Password for \(username)")
            return true
        } else {
            print("❌ Failed to save Internet Password: \(status)")
            return false
        }
    }
    
    private func saveUsername(_ username: String) -> Bool {
        deleteItem(account: usernameKey)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: usernameKey,
            kSecValueData as String: username.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func loadCredentials() -> (username: String, password: String)? {
        // 🆕 優先嘗試從 Internet Password 讀取
        if let credentials = loadFromInternetPassword() {
            return credentials
        }
        
        // 🆕 如果讀取失敗，嘗試從舊方式讀取並遷移
        return loadAndMigrateFromOldFormat()
    }
    
    // 🆕 從 Internet Password 讀取
    private func loadFromInternetPassword() -> (username: String, password: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let dict = result as? [String: Any],
              let username = dict[kSecAttrAccount as String] as? String,
              let passwordData = dict[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        
        print("✅ Loaded from Internet Password: \(username)")
        return (username, password)
    }
    
    // 🆕 從舊格式讀取並遷移
    private func loadAndMigrateFromOldFormat() -> (username: String, password: String)? {
        guard let username = loadUsername(),
              let password = loadPassword(for: username) else {
            print("Fail to load credential")
            return nil
        }
        
        // 遷移到新格式
        print("🔄 Migrating credentials to Internet Password format...")
        _ = saveAsInternetPassword(username: username, password: password)
        
        print("Load credential successfully")
        return (username, password)
    }
    
    private func loadUsername() -> String? {
        return loadItem(account: usernameKey)
    }
    
    private func loadPassword(for username: String) -> String? {
        return loadItem(account: username)
    }
    
    private func loadItem(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    func clearCredentials() {
        // 清除新格式
        clearInternetPasswords()
        
        // 清除舊格式
        if let username = loadUsername() {
            deletePasswordForUsername(username)
        }
        deleteItem(account: usernameKey)
        
        hasMigrated = false
        print("clear credentials successfully")
    }
    
    // 🆕 清除所有 Internet Password
    private func clearInternetPasswords() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // 🆕 刪除特定使用者的 Internet Password
    private func deleteInternetPassword(for username: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecAttrAccount as String: username
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    private func deleteItem(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    private func deletePasswordForUsername(_ username: String) {
        deleteItem(account: username)
    }
    
    func hasCredentials() -> Bool {
        guard let username = loadUsername() else {
            return false
        }
        return loadPassword(for: username) != nil
    }
}

// 🆕 Helper for UserDefaults
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
