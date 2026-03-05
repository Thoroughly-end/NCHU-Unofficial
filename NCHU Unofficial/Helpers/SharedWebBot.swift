//
//  WebKitManager.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/5.
//

import WebKit

class SharedWebBot: NSObject {
    static let shared = SharedWebBot()
    
    let webView: WKWebView
    
    private override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        self.webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    }
    
    func attachToWindow(_ window: UIWindow) {
        webView.removeFromSuperview()
        webView.alpha = 0.0
        webView.isUserInteractionEnabled = false
        webView.frame = window.bounds
        window.insertSubview(webView, at: 0)
    }
}
