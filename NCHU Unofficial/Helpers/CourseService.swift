//
//  CourseService.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/5/25.
//

import Foundation
import SwiftSoup

class CourseService {
    private let baseURL = AppConstants.Network.baseURL
    
    func fetchCourses() async -> [CourseData] {
        let dashboardURLString = "\(baseURL)/dashboard"
        guard let url = URL(string: dashboardURLString) else { return [] }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(AppConstants.Network.userAgent, forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server rejected or session expired")
                return []
            }
            
            guard let html = String(data: data, encoding: .utf8) else { return [] }
            let document = try SwiftSoup.parse(html)
            
            let courseBlocks = try document.select(".fs-thumblist li.col-md-6")
            
            var courses: [CourseData] = []
            
            for block in courseBlocks {
                guard let linkElement = try block.select(".fs-caption .fs-label a").first() else {
                    continue
                }
                
                let href = try linkElement.attr("href")
                
                let courseName = try linkElement.text().trimmingCharacters(in: .whitespacesAndNewlines)
                
                var courseId = 0
                if let range = href.range(of: "\\d+", options: .regularExpression),
                   let extractedID = Int(String(href[range])) {
                    courseId = extractedID
                }
                
                if courseId != 0 && !courseName.isEmpty {
                    let newCourse = CourseData(id: courseId, name: courseName)
                    courses.append(newCourse)
                    print("Extract: [\(courseId)] \(courseName)")
                }
            }
            
            print("Got \(courses.count) CourseData！")
            return courses
            
        } catch {
            print("failed to fetch courses: \(error.localizedDescription)")
            return []
        }
    }
}
