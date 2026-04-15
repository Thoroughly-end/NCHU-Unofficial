//
//  LoginSheet.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI

struct LoginSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var isPreparingCookies: Bool = false
    @State private var isLoadingPage: Bool = true
    @State private var pageErrorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                SSOWebView(
                    targetURLString: "https://ccidp.nchu.edu.tw/login",
                    isLoggedIn: $dataManager.isLoggedIn,
                    isLoadingPage: $isLoadingPage,
                    pageErrorMessage: $pageErrorMessage,
                    onLoginSuccess: { cookies in
                        print("Got \(cookies.count) Cookies")
                        
                        saveCookiesForScraping(cookies)
                        CookieManager.shared.saveCookies(cookies)
                        
                        isPreparingCookies = true
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                            let window = windowScene.windows.first {
                            SharedWebBot.shared.attachToWindow(window)
                        }
                        
                        Task {
                            await fetchAllSystemCookies()
                        
                            isPreparingCookies = false
                            dataManager.showLoginSheet = false
                            dismiss()
                        }
                    }
                )
                .ignoresSafeArea(.container, edges: .bottom)
                
                if isLoadingPage {
                    ProgressView("Loading Portal...")
                        .scaleEffect(1.2)
                        .padding(30)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
                
                if let errorMessage = pageErrorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.largeTitle)
                        Text("Network Error")
                            .font(.headline)
                            .padding(.top, 5)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            pageErrorMessage = nil
                            isLoadingPage = true
                        }
                        .padding(.top, 10)
                    }
                    .padding(30)
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                }
                
                if isPreparingCookies {
                    ProgressView("Fetching TS Cookies...")
                        .scaleEffect(1.2)
                        .padding(30)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dataManager.showLoginSheet = false
                        dismiss()
                    }
                    .disabled(isPreparingCookies)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func saveCookiesForScraping(_ cookies: [HTTPCookie]) {
        let cookieStorage = HTTPCookieStorage.shared
        for cookie in cookies {
            cookieStorage.setCookie(cookie)
        }
    }
    
    private func fetchAllSystemCookies() async {
        let cportalSuccess = await withCheckedContinuation { continuation in
            ScheduleScraperPrepare.shared.fetchRequiredCookie { success in
                continuation.resume(returning: success)
            }
        }
        
        dataManager.hasCportalCookies = cportalSuccess
        if !cportalSuccess {
            print("Can not fetch Cportal cookie")
        }
        
        let iLearningSuccess = await withCheckedContinuation { continuation in
            ILearningScraperPrepare.shared.fetchRequiredCookie { success in
                continuation.resume(returning: success)
            }
        }
        
        dataManager.hasiLearningCookies = iLearningSuccess
        if !iLearningSuccess {
            print("Can not fetch iLearning cookie")
        }
        
        print("Successfully prepared all cookies!")
    }
}
