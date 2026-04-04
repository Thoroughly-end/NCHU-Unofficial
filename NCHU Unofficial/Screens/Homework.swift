//
//  Courses.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI

enum HomeworkTab {
    case all
    case recent
}

struct Courses: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var isCheckingSession: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab: AnnouncementTab = .recent
    
    var recentHomeworks: [Homework] {
        return CourseData.getRecentHomework(from: dataManager.courses)
    }
    
    var body: some View {
        VStack {
            if isCheckingSession {
                ProgressView("Checking Session")
            } else {
                if dataManager.isLoggedIn {
                    VStack {
                        HStack {
                            Text("Homeworks")
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
                        }
                        
                        if selectedTab == .all {
                            ScrollView(.vertical) {
                                VStack {}.frame(height: 20)
                                renderAllCoursesView()
                            }
                        } else {
                            ScrollView(.vertical) {
                                VStack {}.frame(height: 20)
                                renderRecentHomeWorksView()
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
        .onChange(of: dataManager.hasiLearningCookies) {
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
                    let courses = await ILearningScraper.shared.fetchCourses()
                    for course in courses {
                        await ILearningScraper.shared.fetchHomeworkList(course: course)
                        
                        if !course.homeworks.isEmpty {
                            for homework in course.homeworks {
                                await ILearningScraper.shared.fetchHomeworkDetail(homework: homework)
                                printInfo(homework: homework)
                            }
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
    
    private func printInfo(homework: Homework) {
        print(homework.name)
        print(homework.id)
        if let dueDate = homework.dueDate {
            print(dueDate)
        } else {
            print("Error")
        }
        if let startDate = homework.startDate {
            print(startDate)
        } else {
            print("Error")
        }
        if let explain = homework.explanation {
            print(explain)
        } else {
            print("No Explaination")
        }
        print(homework.isCompleted)
    }
    
    @ViewBuilder
    private func renderAllCoursesView() -> some View {
        VStack {
            ForEach(dataManager.courses) { course in
                CourseCard(course: course)
            }
            
            VStack {}.frame(height: 70)
        }
    }
    
    @ViewBuilder
    private func renderRecentHomeWorksView() -> some View {
        VStack(spacing: 15) {
            if recentHomeworks.isEmpty {
                Text("There is no announcements in ten days.")
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            } else {
                ForEach(recentHomeworks) { homework in
                    RecentHomeworkCard(homework: homework)
                }
            }
        }
        VStack {}.frame(height: 70)
    }
}

#Preview {
    Courses()
        .environmentObject(DataManager())
}
