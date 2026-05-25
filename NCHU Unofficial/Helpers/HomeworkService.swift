//
//  HomeworkService.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/5/25.
//
import Foundation
import SwiftSoup

class HomeworkService {
    private let baseURL = AppConstants.Network.baseURL
    
    func fetchHomeworkList(course: CourseData) async {
        let urlString = "\(baseURL)/course/homeworkList/\(course.id)"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(AppConstants.Network.userAgent, forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server rejected or session expired")
                return
            }
            
            guard let html = String(data: data, encoding: .utf8) else { return }
            let document = try SwiftSoup.parse(html)
            
            let rows = try document.select("table#homeworkListTable tr").dropFirst()
            let noData: Bool = try !document.select("table#homeworkListTable tr#noData").isEmpty()
            
            if noData {
                print("No homework available")
                return
            }
            
            for row in rows {
                let cells = try row.select("td")
                var detailUrl = ""
                var name = ""
                var id = 0
                var isCompleted: Bool = false
                var score: Int? = nil
                var dueDate: Date = Date()
                var startDate: Date = Date()
                for (i, cell) in cells.enumerated() {
                    if i == 1 {
                        guard let linkElement = try cell.select("a").first() else { continue }
                        name = try linkElement.text()
                        let detailPath = try linkElement.attr("href")
                        detailUrl = baseURL + detailPath
                        id = Int(detailPath.components(separatedBy: "/").last ?? "0") ?? 0
                    } else if i == 3 {
                        let startStr = try cell.select("div.text-overflow").text()
                        startDate = parseMessyDate(startStr)
                    } else if i == 4 {
                        let dueStr = try cell.select("div.text-overflow").text()
                        dueDate = parseMessyDate(dueStr)
                    } else if i == 5 {
                        isCompleted = try !cell.select("span.fa-check.fs-text-success").isEmpty()
                    } else if i == 6 {
                        let scoreStr = try cell.select("div.text-overflow").text()
                        if scoreStr == "尚未完成" {
                            score = nil
                        } else {
                            score = Int(scoreStr)
                        }
                    }
                }
                let newHomework = Homework(id: id, url: detailUrl, name: name, isCompleted: isCompleted, score: score, courseID: course.id)
                newHomework.setStartAndDueDate(startDate: startDate, dueDate: dueDate)
                course.addHomework(newHomework)
            }
        } catch {
            print("Failed to parse homework list：\(error)")
            return
        }
    }
    
    func fetchHomeworkDetail(homework: Homework) async {
        let urlString = homework.url
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(AppConstants.Network.userAgent, forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server rejected or session expired")
                return
            }
            
            guard let html = String(data: data, encoding: .utf8) else { return }
            let document = try SwiftSoup.parse(html)
            
            let dl = try document.select("dl.dl-horizontal")
            let startStr = try dl.select("dt:contains(開放繳交) + dd").text()
            print(startStr)
            let dueStr = try dl.select("dt:contains(繳交期限) + dd").text()
            print(dueStr)
            let proportion = try dl.select("dt:contains(成績比重) + dd").text()
            var explanationHTML = try dl.select("dt:contains(說明) + dd").html()
            explanationHTML = explanationHTML.replacingOccurrences(of: "<br>", with: "\n")
            explanationHTML = explanationHTML.replacingOccurrences(of: "</p>", with: "\n")
            let cleanTextWithNewlines = try SwiftSoup.parse(explanationHTML).text()
            var explaination: String? = nil
            if !cleanTextWithNewlines.isEmpty {
                explaination = cleanTextWithNewlines
            }
            
            let startDate = parseMessyDate(startStr)
            let dueDate = parseMessyDate(dueStr)
            
            homework.setExplanationAndPropotion(explanation: explaination, proportion: proportion)
            homework.setStartAndDueDate(startDate: startDate, dueDate: dueDate)
            try? await Task.sleep(nanoseconds: AppConstants.Network.requestDelay)
        } catch {
            print("Failed to fetch homework detail：\(error)")
            return
        }
    }
    
    private func parseMessyDate(_ dateString: String) -> Date {
        let cleanedString = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        
        let possibleFormats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "yyyy/MM/dd HH:mm",
            "yyyy/MM/dd",
            "MM-dd HH:mm"
        ]
        
        for format in possibleFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: cleanedString) {
                return date
            }
        }
        
        print("Unknown date format: \(cleanedString)")
        return Date()
    }
}
