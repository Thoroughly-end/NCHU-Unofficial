//
//  KeyChainHelper.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/3.
//

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    // 🔒 存入保險箱
    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary
        
        // 嘗試新增。如果遇到重複的 (errSecDuplicateItem)，就改用更新的方式
        let status = SecItemAdd(query, nil)
        if status == errSecDuplicateItem {
            let updateQuery = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account
            ] as CFDictionary
            
            let attributesToUpdate = [kSecValueData: data] as CFDictionary
            SecItemUpdate(updateQuery, attributesToUpdate)
        }
    }
    
    // 🔓 從保險箱讀取
    func read(service: String, account: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
    
    // 🗑️ 銷毀機密資料 (登出時使用)
    func delete(service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary
        
        SecItemDelete(query)
    }
}
