//
//  SwiftUIView.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/6/27.
//

import SwiftUI

struct TestPage: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var loginManager: LoginService

    var body: some View {
        VStack(spacing: 20) {
            Text("isLoggedIn: \(loginManager.isLoggedIn ? "true" : "false")")

            Button("Set isLoggedIn = false") {
                loginManager.isLoggedIn = false
            }
            .buttonStyle(.borderedProminent)

            Button("Logout (keep credential) + reLogIn") {
                loginManager.isLoggedIn = false
                loginManager.hasCportalCookies = false
                loginManager.hasiLearningCookies = false
                CookieManager.shared.clearCookies()
                loginManager.isLoggingIn = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    TestPage()
        .environmentObject(DataManager())
}
