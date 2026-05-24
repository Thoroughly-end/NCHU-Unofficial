//
//  CourseData.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/5/22.
//

import Combine
import Foundation

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
        guard let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -AppConstants.UI.recentDaysThreshold, to: Date()) else {
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
        guard let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -AppConstants.UI.recentDaysThreshold, to: Date()) else {
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
