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
    @State var backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
    
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(backgroundColor)
                    .ignoresSafeArea()
                VStack {
                    if isCheckingSession {
                        ProgressView("Checking Session")
                    } else {
                        if !dataManager.isLoggedIn {
                            Text("Please login")
                        } else {
                            VStack {
                                headerSection
                                    .padding(.bottom, 20)
                                    .padding(.horizontal, 30)
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
                                    .padding(.horizontal, 30)
                                    VStack {}.frame(height: 30)
                                }
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                    }
                }
            }
            
        }
        .onAppear() {
            initialLoadIfNeeded()
        }
    }
    
    var headerSection: some View {
        HStack {
            Text("All Courses")
                .font(.largeTitle)
                .bold()
            Spacer()
            
            NavigationLink(destination: RecentAnnouncement()) {
                VStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                }
                .frame(width: 60, height: 60)
                .glassEffect(.regular.interactive())
            }
        }
        
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
