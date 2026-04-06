//
//  SwiftUIView.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/4/6.
//

import SwiftUI

struct AllCourses: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var isCheckingSession: Bool = false
    
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        NavigationStack {
            if isCheckingSession {
                ProgressView("Checking Session")
            } else {
                VStack {
                    headerSection
                        .padding(.bottom, 20)
                    ScrollView {
                        VStack(alignment: .leading) {
                            LazyVGrid(columns: columns, spacing: 15) {
                                ForEach(dataManager.courses) { course in
                                    NavigationLink(destination: CourseView(course: course)) {
                                        courseCard(for: course)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        VStack {}.frame(height: 30)
                    }
                }
                .padding(30)
            }
        }
        .onAppear() {
            initialLoadIfNeeded()
        }
    }
    
    var headerSection: some View {
        Text("All Courses")
            .font(.largeTitle)
            .bold()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func courseCard(for course: CourseData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "books.vertical.fill")
                .font(.title2)
                .foregroundColor(.primary)
            
            Text(course.name)
                .font(.headline)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
    }
    
    private func initialLoadIfNeeded() {
        guard dataManager.isLoggedIn else { return }
        guard dataManager.hasiLearningCookies else { return }
        guard dataManager.courses.isEmpty else { return }
        
        isCheckingSession = true
        
        SessionManager.shared.verifyCookieStatus { isValid in
            if isValid {
                print("Session is valid, start to fetch courses")
                Task { @MainActor in
                    let courses = await ILearningScraper.shared.fetchCourses()
                    let announcements = await ILearningScraper.shared.fetchLatestAnnouncements()
                    
                    for course in courses {
                        let matchedAnnouncements = announcements.filter { $0.courseID == course.id }
                        
                        for announcement in matchedAnnouncements {
                            course.addAnnouncement(announcement)
                        }
                        await ILearningScraper.shared.fetchHomeworkList(course: course)
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
    ContentView()
        .environmentObject(DataManager())
}
