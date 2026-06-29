//
//  ILearningScraper.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/5.
//

import WebKit

class ILearningScraper {
    static let shared = ILearningScraper()
    private let courseService = CourseService()
    private let announcementService = AnnouncementService()
    private let homeworkService = HomeworkService()
    
    func fetchCourses() async -> [CourseData] {
        var courses: [CourseData] = []
        let isValid = await SessionManager.shared.verifyCookieStatus()
        if isValid {
            courses = await courseService.fetchCourses()
        } else {
            await SessionManager.shared.reLogInIfNeeded()
            courses = await courseService.fetchCourses()
        }
        return courses
    }
    
    func fetchLatestAnnouncements() async -> [AnnouncementData] {
        var results: [AnnouncementData] = []
        let isValid = await SessionManager.shared.verifyCookieStatus()
        if isValid {
            results = await announcementService.fetchLatestAnnouncements()
        } else {
            await SessionManager.shared.reLogInIfNeeded()
            results = await announcementService.fetchLatestAnnouncements()
        }
        return results
    }
    
    func fetchAnnouncementContent(for course: CourseData) async {
        let isValid = await SessionManager.shared.verifyCookieStatus()
        if isValid {
            await announcementService.fetchAnnouncementContent(for: course)
        } else {
            await SessionManager.shared.reLogInIfNeeded()
            await announcementService.fetchAnnouncementContent(for: course)
        }
    }
    
    func fetchAnnouncementContent(for announcement: AnnouncementData) async {
        let isValid = await SessionManager.shared.verifyCookieStatus()
        if isValid {
            await announcementService.fetchAnnouncementContent(for: announcement)
        } else {
            await SessionManager.shared.reLogInIfNeeded()
            await announcementService.fetchAnnouncementContent(for: announcement)
        }
    }
    
    func download(for attachment: Attachment) async -> URL? {
        let isValid = await SessionManager.shared.verifyCookieStatus()
        if isValid {
            return await announcementService.download(for: attachment)
        } else {
            await SessionManager.shared.reLogInIfNeeded()
            return await announcementService.download(for: attachment)
        }
    }
    
    func fetchHomeworkList(course: CourseData) async {
        let isValid = await SessionManager.shared.verifyCookieStatus()
        if isValid {
            await homeworkService.fetchHomeworkList(course: course)
        }
    }
    
    func fetchHomeworkDetail(homework: Homework) async {
        let isValid = await SessionManager.shared.verifyCookieStatus()
        if isValid {
            await homeworkService.fetchHomeworkDetail(homework: homework)
        }
    }
    
    func fetchAllData() async -> (courses: [CourseData], announcements: [AnnouncementData]) {
        let isValid = await SessionManager.shared.verifyCookieStatus()
        guard isValid else { return ([], []) }
        
        async let courses = courseService.fetchCourses()
        async let announcements = announcementService.fetchLatestAnnouncements()
        
        return await (courses, announcements)
    }
    
}

class ILearningScraperPrepare: NSObject, WKNavigationDelegate {
    static let shared = ILearningScraperPrepare()
    
    private var hiddenWebView: WKWebView!
    private var onResult: ((Bool) -> Void)?
    private var timeoutTimer: Timer?
    
    private var botWebView: WKWebView {
        return SharedWebBot.shared.webView
    }
    
    func fetchRequiredCookie(completion: @escaping (Bool) -> Void) {
        print("Start CAS process...")
        self.onResult = completion
        
        botWebView.navigationDelegate = self
        
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { [weak self] _ in
            print("Timeout!")
            self?.finish(success: false)
        }
        
        if let url = URL(string: "\(AppConstants.Network.baseURL)/sys/oitc/oa_redirect.php") {
            botWebView.load(URLRequest(url: url))
        }
    }
    
    private func finish(success: Bool) {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        let callback = onResult
        onResult = nil
        
        DispatchQueue.main.async {
            callback?(success)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url?.absoluteString else { return }
        print("Go to: \(url)")
        
        let isFinalDestination = url.contains("lms2020.nchu.edu.tw") && url.contains("dashboard")
        && !url.contains("ccidp.nchu.edu.tw") && !url.contains("cas_login")
        
        if isFinalDestination {
            print("Reach the final destination!")
            //timeoutTimer?.invalidate()
            
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                print("Got \(cookies.count) Cookies")
                let hasTS = cookies.contains { $0.name.starts(with: "TS") }
                                
                if hasTS {
                    CookieManager.shared.saveCookies(cookies)
                    print("Successfully got TS Cookie！")
                    self.finish(success: true)
                } else {
                    print("Reached the final destination but no TS Cookie...")
                }
                
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                    print("   - \(cookie.name)")
                }
            }
            
        } else if url.contains("ccidp.nchu.edu.tw/login?") {
            print("Session Expired")
            CookieManager.shared.clearCookies()
        } else if url.contains("challenges.cloudflare.com") && url.contains("challenge-platform") {
            print("Cloudflare challenge...")
        } else {
            print("Loading...")
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url {
            print("Will going to: \(url.absoluteString)")
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Loading web page failed：\(error.localizedDescription)")
        finish(success: false)
    }
    
    func setupHiddenWebView(in window: UIWindow?) {
        guard let window = window else { return }
        
        hiddenWebView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        hiddenWebView.alpha = 0.0
        hiddenWebView.isUserInteractionEnabled = false
        
        window.addSubview(hiddenWebView)
    }
}
