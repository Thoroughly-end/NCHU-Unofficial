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
    @Binding var isLoadingPage: Bool
    @Binding var pageErrorMessage: String?
    
    var autoFillCredentials: (username: String, password: String)? = nil
    var shouldSaveCredentials: Bool = false
    
    var onLoginSuccess: ([HTTPCookie]) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        if let credentials = autoFillCredentials {
            let script = """
            (function() {
                var retryCount = 0;
                var maxRetries = 10;
                var formFilled = false;
                var cloudflareCheckInterval = null;
                
                // 檢查 Cloudflare Turnstile 是否完成
                function isCloudflareComplete() {
                    // 方法 1: 檢查 Turnstile 的 response token
                    var turnstileInput = document.querySelector('input[name="cf-turnstile-response"]');
                    if (turnstileInput && turnstileInput.value && turnstileInput.value.length > 0) {
                        console.log('Cloudflare Turnstile token found');
                        return true;
                    }
                    
                    // 方法 2: 檢查 reCAPTCHA response
                    var recaptchaResponse = document.querySelector('textarea[name="g-recaptcha-response"]');
                    if (recaptchaResponse && recaptchaResponse.value && recaptchaResponse.value.length > 0) {
                        console.log('reCAPTCHA token found');
                        return true;
                    }
                    
                    // 方法 3: 檢查 Turnstile iframe 的狀態
                    var turnstileIframe = document.querySelector('iframe[src*="challenges.cloudflare.com"]');
                    if (turnstileIframe) {
                        var parentDiv = turnstileIframe.closest('div');
                        // Turnstile 完成後通常會添加特定的 class 或 attribute
                        if (parentDiv && (parentDiv.getAttribute('data-state') === 'success' || 
                            parentDiv.classList.contains('success'))) {
                            console.log('Cloudflare iframe shows success state');
                            return true;
                        }
                    }
                    
                    // 方法 4: 檢查是否沒有 Cloudflare 元素（可能不需要驗證）
                    var hasCloudflare = document.querySelector('[class*="cloudflare"]') || 
                                       document.querySelector('[id*="cloudflare"]') ||
                                       turnstileIframe ||
                                       turnstileInput;
                    
                    if (!hasCloudflare) {
                        console.log('No Cloudflare challenge detected');
                        return true; // 沒有 Cloudflare，視為已完成
                    }
                    
                    console.log('Waiting for Cloudflare verification...');
                    return false;
                }
                
                // 填寫表單
                function fillForm() {
                    retryCount++;
                    console.log('Attempting to fill form, retry: ' + retryCount);
                    
                    var usernameField = document.getElementById('username') || 
                                       document.querySelector('input[name="username"]') ||
                                       document.querySelector('input[id="user"]') ||
                                       document.querySelector('input[type="text"]');
                    var passwordField = document.getElementById('password') || 
                                       document.querySelector('input[name="password"]') ||
                                       document.querySelector('input[type="password"]');
                    
                    if(usernameField && passwordField) {
                        console.log('Found username and password fields');
                        
                        usernameField.value = '\(credentials.username)';
                        passwordField.value = '\(credentials.password)';
                        
                        var inputEvent = new Event('input', { bubbles: true });
                        var changeEvent = new Event('change', { bubbles: true });
                        var keyupEvent = new Event('keyup', { bubbles: true });
                        
                        usernameField.dispatchEvent(inputEvent);
                        usernameField.dispatchEvent(changeEvent);
                        usernameField.dispatchEvent(keyupEvent);
                        
                        passwordField.dispatchEvent(inputEvent);
                        passwordField.dispatchEvent(changeEvent);
                        passwordField.dispatchEvent(keyupEvent);
                        
                        console.log('Auto-fill completed - Username: ' + usernameField.value);
                        formFilled = true;
                        
                        // 開始監聽 Cloudflare 驗證完成
                        startCloudflareMonitoring();
                        
                        return true;
                    } else {
                        console.log('Fields not found yet');
                        if (retryCount < maxRetries) {
                            setTimeout(fillForm, 500);
                        } else {
                            console.log('Max retries reached, giving up');
                        }
                        return false;
                    }
                }
                
                // 監聽 Cloudflare 驗證完成
                function startCloudflareMonitoring() {
                    var checkCount = 0;
                    var maxChecks = 30; // 最多檢查 15 秒 (30 * 500ms)
                    
                    console.log('Starting Cloudflare verification monitoring...');
                    
                    cloudflareCheckInterval = setInterval(function() {
                        checkCount++;
                        
                        if (isCloudflareComplete()) {
                            clearInterval(cloudflareCheckInterval);
                            console.log('Cloudflare verification complete! Submitting form...');
                            submitForm();
                        } else if (checkCount >= maxChecks) {
                            clearInterval(cloudflareCheckInterval);
                            console.log('Cloudflare verification timeout, attempting to submit anyway...');
                            submitForm();
                        }
                    }, 500); // 每 500ms 檢查一次
                }
                
                // 提交表單
                function submitForm() {
                    setTimeout(function() {
                        var submitButton = document.querySelector('button[type="submit"]') ||
                                         document.querySelector('input[type="submit"]') ||
                                         document.querySelector('button[name="submitBtn"]') ||
                                         document.querySelector('.btn-submit') ||
                                         document.querySelector('#submitBtn') ||
                                         document.querySelector('button');
                        
                        if (submitButton) {
                            console.log('Auto-clicking submit button');
                            submitButton.click();
                        } else {
                            // 如果找不到按鈕，直接提交表單
                            var form = document.querySelector('form');
                            if (form) {
                                console.log('Auto-submitting form');
                                form.submit();
                            }
                        }
                    }, 1000); // 等待 1 秒後提交，確保 token 已經設置
                }
                
                // 開始執行
                if (!fillForm()) {
                    console.log('Initial fill failed, will retry');
                }
            })();
            """
            
            let userScript = WKUserScript(source: script,
                                         injectionTime: .atDocumentEnd,
                                         forMainFrameOnly: true)
            config.userContentController.addUserScript(userScript)
        }
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.navigationDelegate = context.coordinator
        webView.alpha = 1.0
        webView.isUserInteractionEnabled = true
        
        if let url = URL(string: targetURLString) {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if isLoadingPage, pageErrorMessage == nil {
            if let _ = uiView.url {
                if !uiView.isLoading {
                    uiView.reload()
                }
            } else if !uiView.isLoading {
                if let url = URL(string: targetURLString) {
                    uiView.load(URLRequest(url: url))
                }
            }
        }
    }
    
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {}
    
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
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoadingPage = true
                self.parent.pageErrorMessage = nil
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                print("reached")
                self.parent.isLoadingPage = false
            }
            guard let urlString = webView.url?.absoluteString else { return }
            print("Loaded：\(urlString)")
            
            if urlString.contains("https://cportal.nchu.edu.tw/cas_login/") {
                print("Login Successfully: SSO WebView")
                
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
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoadingPage = false
                self.parent.pageErrorMessage = error.localizedDescription
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoadingPage = false
                self.parent.pageErrorMessage = error.localizedDescription
            }
        }
    }
}
