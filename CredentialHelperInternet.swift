//
//  CredentialHelperInternet.swift
//  NCHU Unofficial
//
//  使用 kSecClassInternetPassword 以更好地支援 Password AutoFill
//  這個版本專門為網路密碼設計，iOS AutoFill 更容易識別
//

import Foundation
import Security

class CredentialHelperInternet {
    static let shared = CredentialHelperInternet()
    
    private let server = "ccidp.nchu.edu.tw"
    private let protocolType = kSecAttrProtocolHTTPS
    
    /// 儲存網路密碼到 Keychain（使用 kSecClassInternetPassword）
    func saveCredentials(username: String, password: String) -> Bool {
        // 先刪除舊的（如果存在）
        deleteCredentials(for: username)
        
        // 使用 kSecClassInternetPassword 而不是 kSecClassGenericPassword
        // 這是 iOS Password AutoFill 專門設計的類型
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,  // 🔑 關鍵改變
            kSecAttrServer as String: server,
            kSecAttrAccount as String: username,
            kSecAttrPort as String: 443,
            kSecAttrProtocol as String: protocolType,
            kSecAttrAuthenticationType as String: kSecAttrAuthenticationTypeHTMLForm,
            kSecValueData as String: password.data(using: .utf8)!,
            kSecAttrLabel as String: "中興大學入口網站",  // 顯示給使用者看的名稱
            kSecAttrDescription as String: "NCHU Portal Login",
            kSecAttrComment as String: "NCHU student portal account",
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Credentials saved successfully for \(username)")
            return true
        } else {
            print("❌ Failed to save credentials: \(status)")
            return false
        }
    }
    
    /// 從 Keychain 讀取網路密碼
    func loadCredentials() -> (username: String, password: String)? {
        // 查詢所有該 server 的密碼
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne  // 只返回一個
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let dict = result as? [String: Any],
              let usernameData = dict[kSecAttrAccount as String] as? String,
              let passwordData = dict[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            print("❌ Failed to load credentials: \(status)")
            return nil
        }
        
        print("✅ Loaded credentials for \(usernameData)")
        return (usernameData, password)
    }
    
    /// 讀取特定使用者的密碼
    func loadPassword(for username: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecAttrAccount as String: username,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    /// 清除特定使用者的憑證
    func deleteCredentials(for username: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecAttrAccount as String: username
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            print("✅ Deleted credentials for \(username)")
        }
    }
    
    /// 清除所有憑證
    func clearAllCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            print("✅ Cleared all credentials")
        }
    }
    
    /// 檢查是否有儲存的憑證
    func hasCredentials() -> Bool {
        return loadCredentials() != nil
    }
    
    /// 列出所有已儲存的帳號
    func listAllAccounts() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }
}
