//
//  ScheduleScraper.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/3.
//

import Foundation
import SwiftSoup
import WebKit

class ScheduleScraper {
    static let shared = ScheduleScraper()
    
    func fetchSchedule() async -> [ScheduleData]? {
        guard let url = URL(string: "https://cportal.nchu.edu.tw/cofsys/plsql/vocscrd_table") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let safariUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
            request.setValue(safariUserAgent, forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server rejected or session expired")
                return nil
            }
            print("URLSession finally go to：\(httpResponse.url?.absoluteString ?? "")")
            
            guard let htmlString = String(data: data, encoding: .utf8) else {
                print("HTML decoding failed")
                return nil
            }
            
            print("HTML：\n\(htmlString)")
            
            let result = try parseHTML(htmlString)
            return result
        } catch {
            print("Request failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func parseHTML(_ html: String) throws -> [ScheduleData] {
        var result: [ScheduleData] = []
        let document = try SwiftSoup.parse(html)
        print(try document.select("table").size())
        let tables = try document.select("table")
        
        guard tables.count > 1 else {
            print("Can not find schedule")
            return result
        }
        let table = tables[1]
        
        let rows = try table.select("tr").array()
        for row in rows.dropFirst() {
            let cells = try row.select("td").array()
            for cell in cells.dropFirst() {
                let cleanText = try cell.text().trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanText.isEmpty {
                    result.append(ScheduleData(text: "nil"))
                } else {
                    result.append(ScheduleData(text: cleanText))
                }
            }
        }
        return result
    }
    
}

class ScheduleScraperPrepare: NSObject, WKNavigationDelegate {
    static let shared = ScheduleScraperPrepare()
    
    private var hiddenWebView: WKWebView!
    private var onResult: ((Bool) -> Void)?
    private var timeoutTimer: Timer?
    
    private override init() {
        super.init()
        let config = WKWebViewConfiguration()
        self.hiddenWebView = WKWebView(frame: .zero, configuration: config)
        self.hiddenWebView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        self.hiddenWebView.navigationDelegate = self
    }
    
    func fetchRequiredCookie(completion: @escaping (Bool) -> Void) {
        print("Start CAS process...")
        self.onResult = completion
        
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            print("⏰ [WebView] 闖關逾時，判定為失敗")
            self?.finish(success: false)
        }
        
        if let url = URL(string: "https://cportal.nchu.edu.tw/cas_login/acad?p_subname=vocscrd_table") {
            hiddenWebView.load(URLRequest(url: url))
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
        
        let isFinalDestination = (url.contains("vocscrd_table") || url.contains("stud_subframeset1"))
                                 && url.contains("cofsys/plsql/")
                                 && !url.contains("cas_login")
                                 && !url.contains("cof_ssologin")
        
        if isFinalDestination {
            print("Reach the final destination!")
            
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                CookieManager.shared.saveCookies(cookies)
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
            
        } else if url.contains("ccidp.nchu.edu.tw/login") {
            print("Session Expired")
            CookieManager.shared.clearCookies()
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
