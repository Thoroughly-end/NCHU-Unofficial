//
//  SwiftUIView.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/6/27.
//

import SwiftUI

struct TestPage: View {
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        VStack(spacing: 20) {
            Text("isLoggedIn: \(dataManager.isLoggedIn ? "true" : "false")")

            Button("Set isLoggedIn = false") {
                dataManager.isLoggedIn = false
            }
            .buttonStyle(.borderedProminent)

            Button("Logout (keep credential) + reLogIn") {
                dataManager.isLoggedIn = false
                dataManager.hasCportalCookies = false
                dataManager.hasiLearningCookies = false
                CookieManager.shared.clearCookies()
                dataManager.isLoggingIn = true
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
