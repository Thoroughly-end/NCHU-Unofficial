//
//  LoginService.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/7/2.
//

import Foundation
import Combine
import SwiftUI

class LoginService: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @Published var isLoggingIn: Bool = false
    @Published var loginErrorMessage: String? = nil
    @Published var showLoginSheet: Bool = false
    @AppStorage("hasCportalCookies") var hasCportalCookies: Bool = false
    @AppStorage("hasiLearningCookies") var hasiLearningCookies: Bool = false
    
    func logout() {
        isLoggedIn = false
        hasCportalCookies = false
        hasiLearningCookies = false
        CookieManager.shared.clearCookies()
        CredentialHelper.shared.clearCredentials()
    }
    
    //func relogin() {
    //
    //}
    
    func login() async {
        isLoggedIn = false
        showLoginSheet = true
        isLoggingIn = true
    }
}
