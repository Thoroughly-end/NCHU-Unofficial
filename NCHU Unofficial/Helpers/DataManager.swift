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
    @Published var hasCportalCookies: Bool = false
    @Published var hasiLearningCookies: Bool = false
    
    func logout() {
        isLoggedIn = false
        CookieManager.shared.clearCookies()
    }
    
    
    
}


struct ScheduleWrapper: RawRepresentable {
    var items: [ScheduleData]
    
    init(items: [ScheduleData]) {
        self.items = items
    }
    
    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([ScheduleData].self, from: data) else {
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

struct ScheduleData: Codable {
    var name: String?
    var teacher: String?
    var location: String?
    
    init(text: String) {
        if text == "nil" {
            name = nil
            teacher = nil
            location = nil
            return
        }
        let data = text.split(separator: " ")
        
        if data.isEmpty {
            name = nil
            teacher = nil
            location = nil
        } else if data.count == 1 {
            name = String(data[0]).removingBracket()
            teacher = nil
            location = nil
        } else if data.count == 2 {
            name = String(data[0]).removingBracket()
            teacher = String(data[1])
            location = nil
        } else {
            name = String(data[0]).removingBracket()
            teacher = String(data[1])
            location = String(data[2])
        }
    }
    
}

extension String {
    func removingBracket() -> String {
        if let firstPart = self.split(separator: "(").first {
            return String(firstPart).trimmingCharacters(in: .whitespaces)
        }
        return self
    }
}
