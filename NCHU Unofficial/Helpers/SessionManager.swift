//
//  SessionManager.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/1.
//

import Foundation
import SwiftUI

class SessionManager {
    static let shared = SessionManager()
    
    private var cachedValidationResult: Bool?
    private var cachedValidationTime: Date?
    private let cacheValidityDuration: TimeInterval = AppConstants.Cache.sessionValidityDuration
    
    func verifyCookieStatus(useCache: Bool = true) async -> Bool {
        if useCache, let cachedResult = cachedValidationResult, let cachedTime = cachedValidationTime, Date().timeIntervalSince(cachedTime) < cacheValidityDuration {
            print("Using cached session status: \(cachedResult)")
            return cachedResult
        }
        
        guard let url = URL(string: "https://cportal.nchu.edu.tw/cas_login/") else { return false }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }

            let isValid: Bool
            if let responseURL = httpResponse.url?.absoluteString,
               responseURL.contains("https://ccidp.nchu.edu.tw/login") {
                print("Redirected to SSO page. Session expired")
                CookieManager.shared.clearCookies()
                isValid = false
            } else if httpResponse.statusCode == 200 {
                print("Session valid")
                isValid = true
            } else {
                print("Server rejected: \(httpResponse.statusCode)")
                CookieManager.shared.clearCookies()
                isValid = false
            }
            
            cachedValidationResult = isValid
            cachedValidationTime = Date()
            
            return isValid
        } catch {
            print("Network error: \(error.localizedDescription)")
            return false
        }
    }
    
    func reLogInIfNeeded() async {
        
    }

    func invalidateCache() {
        cachedValidationResult = nil
        cachedValidationTime = nil
    }
}
