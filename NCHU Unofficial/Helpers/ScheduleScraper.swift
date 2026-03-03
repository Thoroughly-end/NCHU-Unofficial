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
    
    func fetchSchedule() async -> [String]? {
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
    
    private func parseHTML(_ html: String) throws -> [String] {
        var result: [String] = []
        let document = try SwiftSoup.parse(html)
        print(try document.select("table").size())
        let table = try document.select("table")[1]
        let rows = try table.select("tr")
        
        for i in 1..<rows.count {
            let cells = try rows[i].select("td")
            
            for j in 1..<cells.count {
                let innerText = try cells[j].text()
                if innerText.isEmpty {
                    result.append("nil")
                } else {
                    result.append(innerText)
                }
            }
        }
        return result
    }
    
}

class ScheduleScraperPrepare: NSObject, WKNavigationDelegate {
    static let shared = ScheduleScraperPrepare()
    
    private var hiddenWebView: WKWebView!
    private var onReady: (() -> Void)?
    
    private override init() {
        super.init()
        self.hiddenWebView = WKWebView()
        self.hiddenWebView.navigationDelegate = self
    }
    
    func fetchRequiredCookie(completion: @escaping () -> Void) {
        print("Start CAS process...")
        self.onReady = completion
        
        if let url = URL(string: "https://cportal.nchu.edu.tw/cas_login/acad?p_subname=vocscrd_table") {
            hiddenWebView.load(URLRequest(url: url))
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
                for cookie in cookies {
                    print("   - \(cookie.name)")
                }
                
                self.onReady?()
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
}
