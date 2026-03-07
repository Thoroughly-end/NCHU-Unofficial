//
//  Settings 2.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//


import SwiftUI

enum AnnouncementTab {
    case all
    case recent
}

struct Announcements: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var isCheckingSession: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab: AnnouncementTab = .recent
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
    }
    
    var recentAnnouncements: [AnnouncementData] {
        return CourseData.getRecentAnnouncements(from: dataManager.courses)
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
                        HStack {
                            Spacer()
                            Picker("DisplayMode", selection: $selectedTab) {
                                Text("All").tag(AnnouncementTab.all)

                                Text("Recent").tag(AnnouncementTab.recent)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                            .padding(.trailing, 30)
                            //.glassEffect()
                        }
                        
                        
                        ScrollView(.vertical) {
                            VStack {}.frame(height: 20)
                            if selectedTab == .all {
                                renderAllCoursesView()
                            } else {
                                renderRecentAnnouncementsView()
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
    
    @ViewBuilder
    private func renderAllCoursesView() -> some View {
        VStack {
            ForEach(dataManager.courses) { course in
                if !course.announcements.isEmpty {
                    AnnouncementsCard(course: course)
                }
                
            }
            /*ForEach(recentAnnouncements) { announcement in
                Text(announcement.title)
            }*/
            
            VStack {}.frame(height: 70)
        }
    }
    
    @ViewBuilder
    private func renderRecentAnnouncementsView() -> some View {
        VStack(spacing: 15) {
            if recentAnnouncements.isEmpty {
                Text("There is no announcements in ten days.")
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            } else {
                ForEach(recentAnnouncements) { announcement in
                    RecentAnnouncementCard(announcement: announcement)
                }
            }
        }
        VStack {}.frame(height: 70)
    }
}


#Preview {
    Announcements()
        .environmentObject(DataManager())
}
