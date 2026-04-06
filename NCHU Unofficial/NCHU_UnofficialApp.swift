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
    
    init() {
        CookieManager.shared.loadCookies()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .task { @MainActor in
                    print("preloading WebBot...")
                    _ = SharedWebBot.shared
                    SessionManager.shared.verifyCookieStatus { isValid in
                        if !isValid {
                            print("Session expired, please login again")
                            dataManager.logout()
                        }
                    }
                }
        }
    }
}
