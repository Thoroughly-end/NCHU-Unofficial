//
//  CookieManager.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/1.
//

import Foundation
import WebKit

class CookieManager {
    static let shared = CookieManager()
    
    // 定義我們保險箱的標籤
    private let serviceName = "com.nchu.unofficial"
    private let accountName = "SSOCookies"
    
    // 📦 1. 存入 Keychain
    func saveCookies(_ cookies: [HTTPCookie]) {
        var cookieDicts: [[String: Any]] = []
        for cookie in cookies {
            if let properties = cookie.properties {
                var stringDict: [String: Any] = [:]
                for (key, value) in properties {
                    stringDict[key.rawValue] = value
                }
                cookieDicts.append(stringDict)
            }
        }
        
        // ⭐️ 把字典轉成二進位 Data，然後鎖進 Keychain！
        do {
            let data = try JSONSerialization.data(withJSONObject: cookieDicts, options: [])
            KeychainHelper.shared.save(data, service: serviceName, account: accountName)
            print("🛡️ 成功將 \(cookies.count) 個 Cookie 安全鎖入 Keychain！")
        } catch {
            print("❌ Cookie 轉碼失敗：\(error)")
        }
    }
    
    // 🪄 2. 從 Keychain 讀取
    func loadCookies() {
        // ⭐️ 從 Keychain 拿出二進位 Data
        guard let data = KeychainHelper.shared.read(service: serviceName, account: accountName) else {
            print("⚠️ Keychain 裡沒有儲存的 Cookie")
            return
        }
        
        do {
            // 將 Data 解碼回字典陣列
            if let cookieDicts = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                var loadedCount = 0
                for stringDict in cookieDicts {
                    var properties: [HTTPCookiePropertyKey: Any] = [:]
                    for (key, value) in stringDict {
                        properties[HTTPCookiePropertyKey(rawValue: key)] = value
                    }
                    
                    if let cookie = HTTPCookie(properties: properties) {
                        HTTPCookieStorage.shared.setCookie(cookie)
                        loadedCount += 1
                    }
                }
                print("🛡️ 成功從 Keychain 還原 \(loadedCount) 個 Cookie！")
            }
        } catch {
            print("❌ Keychain Cookie 解碼失敗：\(error)")
        }
    }
    
    // 🗑️ 3. 登出時清空
    func clearCookies() {
        // 清除硬碟裡的
        KeychainHelper.shared.delete(service: serviceName, account: accountName)
        
        // 清除記憶體裡的
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        print("🗑️ 已徹底銷毀所有 Cookie 憑證！")
    }
}
