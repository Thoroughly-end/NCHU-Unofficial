//
//  LoginService.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/7/2.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class LoginService: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @Published var isLoggingIn: Bool = false
    @Published var loginErrorMessage: String? = nil
    @Published var showLoginSheet: Bool = false
    @AppStorage("hasCportalCookies") var hasCportalCookies: Bool = false
    @AppStorage("hasiLearningCookies") var hasiLearningCookies: Bool = false
    
    // Continuation to wait for login completion
    private var loginContinuation: CheckedContinuation<Bool, Never>?
    
    func logout() {
        isLoggedIn = false
        hasCportalCookies = false
        hasiLearningCookies = false
        CookieManager.shared.clearCookies()
        CredentialHelper.shared.clearCredentials()
        SessionManager.shared.invalidateCache()
    }
    
    func startCAS() {
        isLoggingIn = true
        loginErrorMessage = nil
    }
    
    /// Initiates the login process by showing the login sheet.
    /// Waits asynchronously for the login to complete or be cancelled.
    /// - Returns: `true` if login succeeded, `false` if cancelled or failed
    func login() async -> Bool {
        // Don't start a new login if one is already in progress
        guard loginContinuation == nil else {
            print("Login already in progress")
            return false
        }
        
        isLoggedIn = false
        showLoginSheet = true
        loginErrorMessage = nil
        
        return await withCheckedContinuation { continuation in
            self.loginContinuation = continuation
        }
    }
    
    /// Call this when login succeeds (from HiddenWebView's handleLoginSuccess)
    func completeLogin(success: Bool) {
        isLoggingIn = false
        
        if success {
            isLoggedIn = true
            showLoginSheet = false
        }
        
        loginContinuation?.resume(returning: success)
        loginContinuation = nil
    }
    
    /// Call this when the user cancels the login sheet
    func cancelLogin() {
        isLoggingIn = false
        showLoginSheet = false
        isLoggedIn = false
        
        loginContinuation?.resume(returning: false)
        loginContinuation = nil
    }
    
    func stopLogin() {
        isLoggingIn = false
        isLoggedIn = false
        
        loginContinuation?.resume(returning: false)
        loginContinuation = nil
    }
}
