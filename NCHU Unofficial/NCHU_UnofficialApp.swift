//
//  NCHU_UnofficialApp.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI

@main
struct NCHU_UnofficialApp: App {
    @StateObject private var authManager = AuthManager()
    
    init() {
        CookieManager.shared.loadCookies()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
