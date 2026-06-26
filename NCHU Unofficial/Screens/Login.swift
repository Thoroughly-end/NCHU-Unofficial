//
//  Login.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/6/27.
//

import SwiftUI

enum Field {
    case username, password
}

struct Login: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @FocusState private var focusedField: Field?
    @State var backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: DataManager
    @State private var isLoggingIn: Bool = false
    @State private var isPreparingCookies: Bool = false
    @State private var isLoadingPage: Bool = true
    @State private var pageErrorMessage: String? = nil
    
    var isDarkMode: Bool {
        colorScheme == .dark ? true : false
    }
    
    var body: some View {
        ZStack {
            Color(backgroundColor)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                }
            VStack {
                Image(isDarkMode ? "IconDark" : "Icon")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(.rect(cornerRadius: 10))
                    .padding(.bottom, 30)
                
                inputArea
                    .padding(.bottom, 15)
                    
                Button {
                    login()
                } label: {
                    HStack {
                        Spacer()
                        HStack {
                            if isLoggingIn {
                                ProgressView()
                                    .tint(.white)
                                Text("Logging in...")
                            } else {
                                Text("Login")
                                Image(systemName: "arrowshape.right.circle.fill")
                            }
                        }
                        .font(.title3)
                        .padding(8)
                        .foregroundStyle(.white)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .buttonStyle(.plain)
                .disabled(username.isEmpty || password.isEmpty || isLoggingIn)
                Spacer()
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 40)
            
            if isLoggingIn {
                HiddenWebLoginView(
                    username: username,
                    password: password,
                    isPreparingCookies: $isPreparingCookies,
                    isLoadingPage: $isLoadingPage,
                    pageErrorMessage: $pageErrorMessage,
                    onComplete: {
                        isLoggingIn = false
                        dataManager.showLoginSheet = false
                    }
                )
                .frame(width: 0, height: 0)
                .opacity(0)
            }
            
            /*if isPreparingCookies {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Fetching Cookies...")
                        .font(.headline)
                }
                .padding(40)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }*/
            
            if let errorMessage = pageErrorMessage {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.largeTitle)
                    Text("Login Failed")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        pageErrorMessage = nil
                        login()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
        }
    }
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            FloatingLabelField(title: "Username", text: $username, isSecure: false, focusBinding: $focusedField, field: .username)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            Divider()
                .background(Color.gray.opacity(0.5))
                
            FloatingLabelField(title: "Password", text: $password, isSecure: true, focusBinding: $focusedField, field: .password)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(Color(isDarkMode ? .elementBackground : .white))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private func login() {
        focusedField = nil
        
        let saved = CredentialHelper.shared.saveCredentials(username: username, password: password)
        
        if saved {
            print("Credentials saved successfully")
            isLoggingIn = true
            pageErrorMessage = nil
        } else {
            print("Failed to save credentials")
            pageErrorMessage = "Failed to save credentials"
        }
    }
}

// MARK: - Hidden WebView for Background Login
private struct HiddenWebLoginView: View {
    let username: String
    let password: String
    @Binding var isPreparingCookies: Bool
    @Binding var isLoadingPage: Bool
    @Binding var pageErrorMessage: String?
    var onComplete: () -> Void
    
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        SSOWebView(
            targetURLString: "https://ccidp.nchu.edu.tw/login",
            isLoggedIn: $dataManager.isLoggedIn,
            isLoadingPage: $isLoadingPage,
            pageErrorMessage: $pageErrorMessage,
            autoFillCredentials: (username: username, password: password),
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
                    if let courses = await ScheduleScraper.shared.fetchSchedule() {
                        dataManager.scheduleList.items = courses
                    }
                    
                    isPreparingCookies = false
                    onComplete()
                }
            }
        )
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

private struct FloatingLabelField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool
    var focusBinding: FocusState<Field?>.Binding
    let field: Field
    private var isFocused: Bool {
        focusBinding.wrappedValue == field
    }
    private var isFloating: Bool {
        !text.isEmpty || isFocused
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(title)
                .foregroundStyle(.gray)
                .font(isFloating ? .caption : .body)
                .offset(y: isFloating ? -22 : -7)
                .animation(.easeInOut(duration: 0.2), value: isFloating)
            
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .focused(focusBinding, equals: field)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            focusBinding.wrappedValue = field
        }
    }
}

#Preview {
    Login()
        .environmentObject(DataManager())
}
