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
    private let cookieKey = "SavedSessionCookies"
    
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
        
        UserDefaults.standard.set(cookieDicts, forKey: cookieKey)
        print("\(cookies.count) Cookies saved")
    }

    func loadCookies() {
        guard let cookieDicts = UserDefaults.standard.array(forKey: cookieKey) as? [[String: Any]] else {
            print("No Cookie in disk")
            return
        }
        
        var loadedCount = 0
        
        for stringDict in cookieDicts {
            var properties: [HTTPCookiePropertyKey: Any] = [:]
            for (key, value) in stringDict {
                properties[HTTPCookiePropertyKey(rawValue: key)] = value
            }
            
            if let cookie = HTTPCookie(properties: properties) {
                HTTPCookieStorage.shared.setCookie(cookie)
                WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie)
                loadedCount += 1
            }
        }
        print("Load \(loadedCount) Cookies")
    }
    
    func clearCookies() {
        UserDefaults.standard.removeObject(forKey: cookieKey)
        
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
        print("Clear all Cookies")
    }
}
