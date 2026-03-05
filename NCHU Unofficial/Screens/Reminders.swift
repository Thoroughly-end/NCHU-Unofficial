//
//  Settings 2.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//


import SwiftUI

struct Reminders: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State private var isCheckingSession: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
    }
    
    var body: some View {
        VStack {
            Text("Reminders")
        }
        .onAppear() {
            initialLoadIfNeeded()
        }
    }
    
    private func initialLoadIfNeeded() {
        guard isLoggedIn else { return }
        guard dataManager.hasiLearningCookies else { return }
        
        isCheckingSession = true
        SessionManager.shared.verifyCookieStatus { isValid in
            if isValid {
                print("Session is valid, start to fetch courses")
                Task { @MainActor in
                    dataManager.hasCportalCookies = true
                    let courses = await ILearningScraper.shared.fetchCourses()
                    let announcements = await ILearningScraper.shared.fetchLatestAnnouncements()
                    for course in courses {
                        let matchedAnnouncements = announcements.filter { $0.courseID == course.id }
                        
                        for announcement in matchedAnnouncements {
                            course.addAnnouncement(announcement)
                        }
                    }
                    for course in courses {
                        let announcementCount = course.announcements.count
                        if announcementCount > 0 {
                            print("Course: [\(course.name)] has \(announcementCount) announcements")
                        }
                    }
                    dataManager.courses = courses
                    isCheckingSession = false
                }
            } else {
                DispatchQueue.main.async {
                    isLoggedIn = false
                    dataManager.logout()
                    isCheckingSession = false
                }
            }
        }
    }
}
