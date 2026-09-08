//
//  AllCourseLoader.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/5/21.
//
import Foundation
import Combine

@MainActor
class CourseDataLoader: ObservableObject {
    static let shared = CourseDataLoader()
    
    @Published var isLoading: Bool = false
    @Published var lastLoadTime: Date?
    
    private var loadTask: Task<Void, Never>?
    
    func loadAllCourses(loginManager: LoginService, dataManager: DataManager) async -> Bool {
        if isLoading {
            await loadTask?.value
        }
        
        guard loginManager.isLoggedIn else { return false }
        guard loginManager.hasiLearningCookies else { return false }
        
        isLoading = true
        
        loadTask = Task { @MainActor in
            defer { isLoading = false }
            
            let isValid = await SessionManager.shared.verifyCookieStatus()
            
            guard isValid else {
                print("Session invalid, need to re-login")
                // Clear cookies but don't logout immediately
                CookieManager.shared.clearCookies()
                loginManager.isLoggedIn = false
                return
            }
            
            print("Session valid, loading all data...")
            
            let courses = await ILearningScraper.shared.fetchCourses()
            let announcements = await ILearningScraper.shared.fetchLatestAnnouncements()
            
            for course in courses {
                let matchedAnnouncements = announcements.filter { $0.courseID == course.id }
                matchedAnnouncements.forEach { course.addAnnouncement($0) }
            }
            
            await withTaskGroup(of: Void.self) { group in
                for course in courses {
                    group.addTask {
                        await ILearningScraper.shared.fetchHomeworkList(course: course)
                    }
                }
            }
            
            dataManager.courses = courses
            lastLoadTime = Date()
            print("Loaded \(courses.count) courses")
        }
        
        await loadTask?.value
        return true
    }
}
