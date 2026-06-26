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
                
                function fillForm() {
                    retryCount++;
                    console.log('Attempting to fill form, retry: ' + retryCount);
                    
                    var usernameField = document.getElementById('username') || 
                                       document.querySelector('input[name="username"]') ||
                                       document.querySelector('input[id*="user"]') ||
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
                        
                        // wait 3 second
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
                                // if can not find button, submit the form
                                var form = document.querySelector('form');
                                if (form) {
                                    console.log('Auto-submitting form');
                                    form.submit();
                                }
                            }
                        }, 3000);
                        
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
    
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            SharedWebBot.shared.attachToWindow(window)
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
