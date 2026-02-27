//
//  SessionManager.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/1.
//

import Foundation

class SessionManager {
    static let shared = SessionManager()
    
    func verifyCookieStatus(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://cportal.nchu.edu.tw/cas_login/") else { return }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, error == nil else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            if let responseURL = httpResponse.url?.absoluteString, responseURL.contains("https://ccidp.nchu.edu.tw/login") {
                print("Redirecte to SSO page. Session expire")
                DispatchQueue.main.async { completion(false) }
                
            } else if httpResponse.statusCode == 200 {
                print("Session valid")
                DispatchQueue.main.async { completion(true) }
                
            } else {
                print("Server reject：\(httpResponse.statusCode)")
                DispatchQueue.main.async { completion(false) }
            }
        }
        task.resume()
    }
}
