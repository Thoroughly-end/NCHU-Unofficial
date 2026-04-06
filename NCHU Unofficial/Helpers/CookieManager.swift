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
    
    private let cookieKey = "saved_nchu_cookies"
    
    func saveCookies(_ cookies: [HTTPCookie]) {
        var finalCookies: [HTTPCookie] = []
        
        for cookie in cookies {
            var properties = cookie.properties ?? [:]
            
            if properties[.expires] == nil {
                properties[.expires] = Date().addingTimeInterval(60 * 60 * 24 * 30)
            }
            
            if let newCookie = HTTPCookie(properties: properties) {
                finalCookies.append(newCookie)
            } else {
                finalCookies.append(cookie)
            }
        }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: finalCookies, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: cookieKey)
            print("Store \(finalCookies.count) Cookies successfully.")
        } catch {
            print("failed to store cookies: \(error.localizedDescription)")
        }
    }
    
    func loadCookies() {
        guard let data = UserDefaults.standard.data(forKey: cookieKey) else {
            print("Can not find saved cookies.")
            return
        }
        
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            
            unarchiver.requiresSecureCoding = false
            
            if let cookies = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [HTTPCookie] {
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                print("Successfully loaded \(cookies.count) Cookies")
            }
            
            unarchiver.finishDecoding()
            
        } catch {
            print("failed to load cookies: \(error.localizedDescription)")
        }
    }
    
    func clearCookies() {
        UserDefaults.standard.removeObject(forKey: cookieKey)
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        DispatchQueue.main.async {
            let dataStore = WKWebsiteDataStore.default()
            dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records, completionHandler: {
                    print("Clear WebKit stored data and cookies")
                })
            }
        }
        
        print("Clear all Cookies")
    }
}
