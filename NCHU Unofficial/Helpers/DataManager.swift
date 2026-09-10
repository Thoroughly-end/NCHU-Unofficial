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
    @AppStorage("scheduleList", store: UserDefaults(suiteName: "group.com.allen.NCHU-Unofficial")) var scheduleList: ScheduleWrapper = ScheduleWrapper(items: [])
    @Published var courses: [CourseData] = []
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
