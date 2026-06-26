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
    private let passwordKey = "nchu_password"
    
    func saveCredentials(username: String, password: String) -> Bool {
        guard saveUsername(username) else {
            print("Fail to save username")
            return false
        }
        
        guard savePassword(password, for: username) else {
            print("Fail to save password")
            return false
        }
        
        print("save credential sussessfully")
        return true
    }
    
    private func saveUsername(_ username: String) -> Bool {
        deleteItem(account: usernameKey)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: usernameKey,
            kSecValueData as String: username.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func savePassword(_ password: String, for username: String) -> Bool {
        deleteItem(account: passwordKey)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: passwordKey,
            kSecValueData as String: password.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func loadCredentials() -> (username: String, password: String)? {
        guard let username = loadUsername(),
              let password = loadPassword() else {
            print("Fail to load credential")
            return nil
        }
        
        print("Load credential successfully")
        return (username, password)
    }
    
    private func loadUsername() -> String? {
        return loadItem(account: usernameKey)
    }
    
    private func loadPassword() -> String? {
        return loadItem(account: passwordKey)
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
        deleteItem(account: usernameKey)
        deleteItem(account: passwordKey)
        print("clear credentials successfully")
    }
    
    private func deleteItem(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    func hasCredentials() -> Bool {
        return loadUsername() != nil && loadPassword() != nil
    }
}
