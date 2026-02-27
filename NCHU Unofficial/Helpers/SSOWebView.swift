//
//  SSOWebView.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI
import WebKit

struct SSOWebView: UIViewRepresentable {
    let targetURLString: String
    @Binding var isLoggedIn: Bool
    
    var onLoginSuccess: ([HTTPCookie]) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url == nil, let url = URL(string: targetURLString) {
            uiView.load(URLRequest(url: url))
        }
    }
    
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: SSOWebView
        
        init(_ parent: SSOWebView) {
            self.parent = parent
        }
        
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                print("GO TO：\(url.absoluteString)")
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let urlString = webView.url?.absoluteString else { return }
            print("Loaded：\(urlString)")
            
            if urlString.contains("https://cportal.nchu.edu.tw/cas_login/") {
                print("Login Successfully")
                
                WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                    let cookieNames = cookies.map { $0.name }
                    print("Cookies：\(cookieNames)")
                    
                    let hasSession = cookies.contains(where: { $0.name.contains("SESSION") })
                    
                    DispatchQueue.main.async {
                        if hasSession {
                            print("Get SESSION Successfully")
                            self.parent.isLoggedIn = true
                            self.parent.onLoginSuccess(cookies)
                        }
                    }
                }
            }
        }
    }
}
