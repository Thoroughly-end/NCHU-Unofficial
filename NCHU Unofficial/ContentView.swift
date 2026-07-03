//
//  ContentView.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//
import SwiftUI
import WebKit

/// Embeds the shared cookie-acquisition `WKWebView` invisibly into the view
/// hierarchy so that `*ScraperPrepare` navigations (which require a live browser
/// context) can run from anywhere in the app.
struct SharedWebBotHost: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let webView = SharedWebBot.shared.webView
        webView.isUserInteractionEnabled = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

/// Drives SSO login in the background from anywhere in the app. It only acts
/// while `dataManager.isLoggingIn` is true, pulling the saved account from
/// `CredentialHelper`, then refreshes the Cportal / iLearning cookies on success.
struct HiddenWebView: View {
    @EnvironmentObject var loginManager: LoginService
    @EnvironmentObject var dataManager: DataManager
    @State private var isLoadingPage: Bool = true
    @State private var credentials: (String, String)?
    @State private var shouldShowWebView: Bool = false

    var body: some View {
        Group {
            if shouldShowWebView, let credentials = credentials {
                SSOWebView(
                    targetURLString: "https://ccidp.nchu.edu.tw/login",
                    isLoggedIn: $loginManager.isLoggedIn,
                    isLoadingPage: $isLoadingPage,
                    pageErrorMessage: $loginManager.loginErrorMessage,
                    autoFillCredentials: credentials,
                    onLoginSuccess: { cookies in
                        handleLoginSuccess(cookies)
                    }
                )
            }
        }
        .onChange(of: loginManager.isLoggingIn) { oldValue, newValue in
            if newValue && credentials == nil {
                credentials = CredentialHelper.shared.loadCredentials()
                shouldShowWebView = credentials != nil
            } else if !newValue {
                credentials = nil
                shouldShowWebView = false
            }
        }
    }

    private func handleLoginSuccess(_ cookies: [HTTPCookie]) {
        print("Got \(cookies.count) Cookies")

        for cookie in cookies {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
        CookieManager.shared.saveCookies(cookies)

        Task { @MainActor in
            await fetchAllSystemCookies()
            if let schedule = await ScheduleScraper.shared.fetchSchedule() {
                dataManager.scheduleList.items = schedule
            }
            loginManager.completeLogin(success: true)
        }
    }

    private func fetchAllSystemCookies() async {
        let cportalSuccess = await withCheckedContinuation { continuation in
            ScheduleScraperPrepare.shared.fetchRequiredCookie { success in
                continuation.resume(returning: success)
            }
        }
        loginManager.hasCportalCookies = cportalSuccess
        if !cportalSuccess {
            print("Can not fetch Cportal cookie")
        }

        let iLearningSuccess = await withCheckedContinuation { continuation in
            ILearningScraperPrepare.shared.fetchRequiredCookie { success in
                continuation.resume(returning: success)
            }
        }
        loginManager.hasiLearningCookies = iLearningSuccess
        if !iLearningSuccess {
            print("Can not fetch iLearning cookie")
        }

        print("Successfully prepared all cookies!")
    }
}

enum APPTab: String {
    case schedule = "schedule"
    case courses = "courses"
    case settings = "settings"
    
    var symbolImage: String {
        return switch self {
        case .schedule: "calendar"
        case .courses: "book.closed.fill"
        case .settings: "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var activeTab: APPTab = .schedule
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var loginManager: LoginService
    
    var body: some View {
        TabView(selection: $activeTab) {
            Tab("Schedule", systemImage: APPTab.schedule.symbolImage, value: APPTab.schedule) {
                Schedule()
                    .ignoresSafeArea(.container, edges: .bottom)
            }
            
            Tab("Courses", systemImage: APPTab.courses.symbolImage, value: APPTab.courses) {
                AllCourses()
                    .ignoresSafeArea(.container, edges: .bottom)
            }
            
            Tab("Setting", systemImage: APPTab.settings.symbolImage, value: APPTab.settings) {
                Settings()
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .tint(.blue)
        .background {
            ZStack {
                SharedWebBotHost()
                HiddenWebView()
            }
            .frame(width: 1, height: 1)
            .opacity(0)
            .allowsHitTesting(false)
        }
        .onAppear() {
            Task {
                if !loginManager.isLoggedIn {
                    let success = await loginManager.login()
                    if success {
                        print("Login success: Homepage")
                    } else {
                        print("Login failed: Homepage")
                    }
                }
            }
        }
        .sheet(isPresented: $loginManager.showLoginSheet) {
            NavigationView {
                Login()
                    .navigationTitle("Login")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cancel") {
                                loginManager.cancelLogin()
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
        .environmentObject(LoginService())
}

