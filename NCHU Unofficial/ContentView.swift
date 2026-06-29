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
    @EnvironmentObject var dataManager: DataManager
    @State private var isLoadingPage: Bool = true

    var body: some View {
        Group {
            if dataManager.isLoggingIn,
               let credentials = CredentialHelper.shared.loadCredentials() {
                SSOWebView(
                    targetURLString: "https://ccidp.nchu.edu.tw/login",
                    isLoggedIn: $dataManager.isLoggedIn,
                    isLoadingPage: $isLoadingPage,
                    pageErrorMessage: $dataManager.loginErrorMessage,
                    autoFillCredentials: credentials,
                    onLoginSuccess: { cookies in
                        handleLoginSuccess(cookies)
                    }
                )
            }
        }
    }

    private func handleLoginSuccess(_ cookies: [HTTPCookie]) {
        print("Got \(cookies.count) Cookies")

        for cookie in cookies {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
        CookieManager.shared.saveCookies(cookies)

        Task {
            await fetchAllSystemCookies()
            if let schedule = await ScheduleScraper.shared.fetchSchedule() {
                dataManager.scheduleList.items = schedule
            }
            dataManager.isLoggingIn = false
            dataManager.showLoginSheet = false
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
            if dataManager.isLoggedIn == false {
                dataManager.showLoginSheet = true
            }
        }
        .sheet(isPresented: $dataManager.showLoginSheet) {
            NavigationView {
                Login()
                    .navigationTitle("Login")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cancel") {
                                dataManager.showLoginSheet = false
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
}

