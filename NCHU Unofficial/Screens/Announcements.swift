//
//  Settings 2.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//


import SwiftUI

struct Announcements: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var isCheckingSession: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
    }
    
    var body: some View {
        VStack {
            if isCheckingSession {
                ProgressView("Checking Session")
            } else {
                if dataManager.isLoggedIn {
                    VStack {
                        HStack {
                            Text("Announcements")
                                .font(.largeTitle)
                                .bold()
                                .padding(.leading, 50)
                                .padding(.top, 20)
                            Spacer()
                        }
                        ScrollView(.vertical) {
                            VStack {
                                ForEach(dataManager.courses) { course in
                                    if !course.announcements.isEmpty {
                                        AnnouncementsCard(course: course)
                                    }
                                    
                                }
                                VStack {}.frame(height: 70)
                            }
                        }
                    }
                } else {
                    Text("Please login")
                }
            }
        }
        .onAppear() {
            initialLoadIfNeeded()
        }
    }
    
    private func initialLoadIfNeeded() {
        guard dataManager.isLoggedIn else { return }
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
                    dataManager.logout()
                    isCheckingSession = false
                }
            }
        }
    }
}


#Preview {
    Announcements()
        .environmentObject(DataManager())
}
