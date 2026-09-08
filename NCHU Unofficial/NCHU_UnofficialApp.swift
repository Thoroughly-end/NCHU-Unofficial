//
//  NCHU_UnofficialApp.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI

@main
struct NCHU_UnofficialApp: App {
    @StateObject private var dataManager = DataManager()
    @StateObject private var loginManager = LoginService()
    
    init() {
        CookieManager.shared.loadCookies()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(loginManager)
                .task { @MainActor in
                    print("preloading WebBot...")
                    async let _ = SharedWebBot.shared
                    let isValid = await SessionManager.shared.verifyCookieStatus()
                    if !isValid {
                        if loginManager.isLoggedIn {
                            loginManager.logout()
                        }
                    }
                }
        }
    }
}
