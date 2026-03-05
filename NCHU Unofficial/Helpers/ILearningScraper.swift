//
//  ILearningScraper.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/5.
//

import WebKit
import Foundation
import SwiftSoup

class ILearningScraper {
    static let shared = ILearningScraper()
    let baseURL = "https://lms2020.nchu.edu.tw"
    
    func fetchCourses() async -> [CourseData] {
        let dashboardURLString = "\(baseURL)/dashboard"
        guard let url = URL(string: dashboardURLString) else { return [] }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server rejected or session expired")
                return []
            }
            
            guard let html = String(data: data, encoding: .utf8) else { return [] }
            let document = try SwiftSoup.parse(html)
            
            let courseBlocks = try document.select(".fs-thumblist li.col-md-6")
            
            var courses: [CourseData] = []
            
            for block in courseBlocks {
                guard let linkElement = try block.select(".fs-caption .fs-label a").first() else {
                    continue
                }
                
                let href = try linkElement.attr("href")
                
                let courseName = try linkElement.text().trimmingCharacters(in: .whitespacesAndNewlines)
                
                var courseId = 0
                if let range = href.range(of: "\\d+", options: .regularExpression),
                   let extractedID = Int(String(href[range])) {
                    courseId = extractedID
                }
                
                if courseId != 0 && !courseName.isEmpty {
                    let newCourse = CourseData(id: courseId, name: courseName)
                    courses.append(newCourse)
                    print("Extract: [\(courseId)] \(courseName)")
                }
            }
            
            print("Got \(courses.count) CourseData！")
            return courses
            
        } catch {
            print("failed to fetch courses: \(error.localizedDescription)")
            return []
        }
    }
    
    // ⭐️ 抓取最新公告，並回傳 (課程ID, 公告資料) 的陣列，方便我們分類
    func fetchLatestAnnouncements() async -> [AnnouncementData] {
        let latestBulletinURLString = "\(baseURL)/dashboard/latestBulletin"
        guard let url = URL(string: latestBulletinURLString) else { return [] }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server rejected or session expired")
                return []
            }
            
            guard let html = String(data: data, encoding: .utf8) else { return [] }
            let document = try SwiftSoup.parse(html)
            
            // 🎯 1. 鎖定表格內所有帶有 data-url 的公告連結
            // CSS Selector 解析：找尋 id 為 bulletinMgrTable 裡面的 a 標籤，且 class 包含 fs-bulletin-item
            let announcementLinks = try document.select("#bulletinMgrTable a.fs-bulletin-item")
            
            var results: [AnnouncementData] = []
            
            for link in announcementLinks {
                // 🎯 2. 從自訂屬性中抽出「標題」與「真實網址」
                let title = try link.attr("data-modal-title").trimmingCharacters(in: .whitespacesAndNewlines)
                let dataUrl = try link.attr("data-url")
                
                // 防呆：如果網址是空的就跳過
                if dataUrl.isEmpty { continue }
                
                // 組裝成絕對網址
                let fullContentUrl = baseURL + dataUrl
                
                // 🎯 3. 從 dataUrl 裡面把課程 ID (course.44660) 挖出來
                var targetCourseId = 0
                // 用 Regex 尋找 "course." 後面的數字
                if let range = dataUrl.range(of: "(?<=course\\.)\\d+", options: .regularExpression),
                   let extractedID = Int(String(dataUrl[range])) {
                    targetCourseId = extractedID
                }
                
                // 🎯 4. 組裝資料
                if targetCourseId != 0 && !title.isEmpty {
                    let newAnnouncement = AnnouncementData(courseID: targetCourseId, title: title, url: fullContentUrl)
                    results.append(newAnnouncement)
                    print("Got announcement：[\(targetCourseId)] \(title)")
                }
            }
            
            print("Got \(results.count) announcements.")
            return results
            
        } catch {
            print("failed with error: \(error.localizedDescription)")
            return []
        }
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
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            print("Timeout!")
            self?.finish(success: false)
        }
        
        if let url = URL(string: "https://lms2020.nchu.edu.tw/sys/oitc/oa_redirect.php") {
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
            
        } else if url.contains("cas_login") {
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
