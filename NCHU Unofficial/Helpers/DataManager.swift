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
    
    @AppStorage("hasCportalCookies") var hasCportalCookies: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("hasiLearningCookies") var hasiLearningCookies: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    @Published var showLoginSheet: Bool = false
    @Published var courses: [CourseData] = []
    
    func logout() {
        isLoggedIn = false
        hasCportalCookies = false
        hasiLearningCookies = false
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

struct ScheduleData: Codable, Equatable {
    var name: String?
    var teacher: String?
    var location: String?
    
    init(text: String) {
        guard text != "nil", !text.isEmpty else { return }
        
        let parts = text.split(separator: " ").map(String.init)
        
        guard parts.count > 1 else {
            self.name = text.removingBracket()
            return
        }
        
        if let lastPart = parts.last {
            let info = parseTeacherAndRoom(lastPart)
            self.teacher = info.teacher
            self.location = info.room
            
            if self.teacher == nil && self.location == nil {
                self.teacher = lastPart
            }
        }
        let nameParts = parts.dropLast()
        self.name = nameParts.joined(separator: " ").removingBracket()
    }
    
    private func parseTeacherAndRoom(_ input: String) -> (teacher: String?, room: String?) {
        let regex = /^(.+?)([A-Za-z]{1,2}\d{3})$/

        if let match = input.wholeMatch(of: regex) {
            return (String(match.output.1), String(match.output.2))
        }
        return (nil, nil)
    }
}

struct Period: Identifiable {
    let id = UUID()
    let day: Int
    let range: ClosedRange<Int>
    let info: ScheduleData
}

class SchedulePeriod {
    let schedule: [ScheduleData]
    var periods: [Period] = []
    
    init(schedule: [ScheduleData]) {
        self.schedule = schedule
        
        if schedule.count < 91 { return }
        
        for i in 1...7 {
            var currentCourse = ScheduleData(text: "nil")
            var start = 0
            for j in 1...13 {
                
                if currentCourse.name == nil {
                    currentCourse = schedule[(j - 1) * 7 + (i - 1)]
                    start = j
                    continue
                }
                
                if currentCourse != schedule[(j - 1) * 7 + (i - 1)] {
                    if currentCourse.name == nil { continue }
                    periods.append(Period(day: i, range: start...(j - 1), info: currentCourse))
                    
                    start = j
                    currentCourse = schedule[(j - 1) * 7 + (i - 1)]
                }
                
                if j == 13 {
                    if currentCourse.name == nil { continue }
                    periods.append(Period(day: i, range: start...13, info: currentCourse))
                }
            }
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

class AnnouncementData: Identifiable, ObservableObject {
    var courseID: Int
    var title: String
    var url: String
    var date: Date?
    
    @Published var content: String?
    @Published var attachments: [Attachment] = []
    
    init(courseID: Int, title: String, url: String, date: Date?) {
        self.courseID = courseID
        self.title = title
        self.url = url
        self.date = date
        self.content = nil
    }
    
    func setContentAndAttachments(content: String, attachments: [Attachment]) {
        DispatchQueue.main.async {
            self.content = content
            self.attachments = attachments
        }
    }
}

class Attachment: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    
    init(name: String, url: String) {
        self.name = name.removingBracket()
        self.url = url
    }
}

class Homework: Identifiable, ObservableObject {
    let id: Int
    let url: String
    let name: String
    let courseID: Int
    @Published var startDate: Date?
    @Published var dueDate: Date?
    let isCompleted: Bool
    let score: Int?
    @Published var explanation: String?
    @Published var proportion: String?
    
    
    init(id: Int, url: String, name: String, isCompleted: Bool, score: Int?, courseID: Int) {
        self.id = id
        self.url = url
        self.name = name
        self.startDate = nil
        self.dueDate = nil
        self.isCompleted = isCompleted
        self.score = score
        self.explanation = nil
        self.proportion = nil
        self.courseID = courseID
    }
    
    func setExplanationAndPropotion(explanation: String?, proportion: String?) {
        DispatchQueue.main.async {
            self.explanation = explanation
            self.proportion = proportion
        }
    }
    
    func setStartAndDueDate(startDate: Date, dueDate: Date) {
        DispatchQueue.main.async {
            self.startDate = startDate
            self.dueDate = dueDate
        }
    }
}

class CourseData: Identifiable, ObservableObject {
    var id: Int
    var name: String
    @Published var announcements: [AnnouncementData]
    @Published var homeworks: [Homework]
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
        self.announcements = []
        self.homeworks = []
    }
    
    func addAnnouncement(_ announcement: AnnouncementData) {
        self.announcements.append(announcement)
    }
    
    func addHomework(_ homework: Homework) {
        self.homeworks.append(homework)
    }
    
    static func getRecentAnnouncements(from courses: [CourseData]) -> [AnnouncementData] {
        guard let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date()) else {
            return []
        }
        let allAnnouncements = courses.flatMap { $0.announcements }

        let recentAnnouncements = allAnnouncements.filter { announcement in
            if let date = announcement.date {
                return date >= tenDaysAgo
            }
            return false
        }
        
        let sortedAnnouncements = recentAnnouncements.sorted { a1, a2 in
            let date1 = a1.date ?? Date.distantPast
            let date2 = a2.date ?? Date.distantPast
            return date1 > date2
        }
        
        return sortedAnnouncements
    }
    
    static func getRecentHomework(from courses: [CourseData]) -> [Homework] {
        guard let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date()) else {
            return []
        }
        let allHomeworks = courses.flatMap { $0.homeworks }

        let recentHomeworks = allHomeworks.filter { homework in
            if let date = homework.dueDate {
                return date >= tenDaysAgo
            }
            return false
        }
        
        let sortedHomeworks = recentHomeworks.sorted { h1, h2 in
            let date1 = h1.dueDate ?? Date.distantPast
            let date2 = h2.dueDate ?? Date.distantPast
            return date1 > date2
        }
        
        return sortedHomeworks
    }
}
