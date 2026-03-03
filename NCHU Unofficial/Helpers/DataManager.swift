//
//  AuthManager.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/1.
//

import SwiftUI
import Combine
import Foundation

class DataManager: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("scheduleList") var scheduleList: ScheduleWrapper = ScheduleWrapper(items: []) {
        willSet {
            objectWillChange.send()
        }
    }
    
    @Published var showLoginSheet: Bool = false
    
    func logout() {
        isLoggedIn = false
        CookieManager.shared.clearCookies()
    }
}


struct ScheduleWrapper: RawRepresentable {
    var items: [String]
    
    init(items: [String]) {
        self.items = items
    }
    
    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        self.items = decoded
    }
    
    var rawValue: String {
        guard let data = try? JSONEncoder().encode(items),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }
}
