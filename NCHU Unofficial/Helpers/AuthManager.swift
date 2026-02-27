//
//  AuthManager.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/1.
//

import SwiftUI
import Combine

class AuthManager: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    @Published var showLoginSheet: Bool = false
    
    func logout() {
        isLoggedIn = false
        CookieManager.shared.clearCookies()
    }
}
