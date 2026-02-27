//
//  LoginSheet.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI

struct LoginSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    
    var body: some View {
        NavigationView {
            // 呼叫我們剛才寫好的強大 WebView
            SSOWebView(
                targetURLString: "https://ccidp.nchu.edu.tw/login",
                isLoggedIn: $authManager.isLoggedIn,
                onLoginSuccess: { cookies in
                    print("Got \(cookies.count) Cookies")
                    
                    for cookie in cookies {
                        print("Key：\(cookie.name), Value：\(cookie.value)")
                    }
                    saveCookiesForScraping(cookies)
                    CookieManager.shared.saveCookies(cookies)
                    authManager.showLoginSheet = false
                    dismiss()
                }
            )
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        authManager.showLoginSheet = false
                        dismiss()
                    }
                }
            }
        }
    }
    
    // 實務上：把 WebView 抓到的 Cookie，塞進共用的 HTTPCookieStorage
    private func saveCookiesForScraping(_ cookies: [HTTPCookie]) {
        let cookieStorage = HTTPCookieStorage.shared
        for cookie in cookies {
            cookieStorage.setCookie(cookie)
        }
    }
}
