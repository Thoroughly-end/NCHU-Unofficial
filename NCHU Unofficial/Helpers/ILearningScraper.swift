//
//  ILearningScraper.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/5.
//

import WebKit
import Foundation
import SwiftSoup

class ILearningScraper {
    static let shared = ILearningScraper()
    let baseURL = "https://lms2020.nchu.edu.tw"
    
    func fetchCourses() async -> [CourseData] {
        let dashboardURLString = "\(baseURL)/dashboard"
        guard let url = URL(string: dashboardURLString) else { return [] }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
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
    
    func fetchLatestAnnouncements() async -> [AnnouncementData] {
        let latestBulletinURLString = "\(baseURL)/dashboard/latestBulletin"
        guard let url = URL(string: latestBulletinURLString) else { return [] }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server rejected or session expired")
                return []
            }
            
            guard let html = String(data: data, encoding: .utf8) else { return [] }
            let document = try SwiftSoup.parse(html)
            let rows = try document.select("#bulletinMgrTable tr")
            
            var results: [AnnouncementData] = []
            
            for row in rows {
                let dateString = try row.select("td.hidden-xs.text-center.col-date div.text-overflow").text()
                let link = try row.select("a.fs-bulletin-item")
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let date = formatter.date(from: dateString)
                
                print(dateString)
                let title = try link.attr("data-modal-title").trimmingCharacters(in: .whitespacesAndNewlines)
                let dataUrl = try link.attr("data-url")
                
                if dataUrl.isEmpty { continue }
            
                let fullContentUrl = baseURL + dataUrl
            
                var targetCourseId = 0
                if let range = dataUrl.range(of: "(?<=course\\.)\\d+", options: .regularExpression),
                   let extractedID = Int(String(dataUrl[range])) {
                    targetCourseId = extractedID
                }
                
                if targetCourseId != 0 && !title.isEmpty {
                    let newAnnouncement = AnnouncementData(courseID: targetCourseId, title: title, url: fullContentUrl, date: date)
                    results.append(newAnnouncement)
                    print("Got announcement：[\(targetCourseId)] \(title)")
                }
            }
            
            results.sort { (announcement1, announcement2) -> Bool in
                let date1 = announcement1.date ?? Date.distantPast
                let date2 = announcement2.date ?? Date.distantPast
                return date1 > date2
            }
            
            print("Got \(results.count) announcements.")
            return results
            
        } catch {
            print("failed with error: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchAnnouncementContent(for course: CourseData) async {
        for announcement in course.announcements {
            await ILearningScraper.shared.fetchAnnouncementContent(for: announcement)
        }
    }
    
    func fetchAnnouncementContent(for announcement: AnnouncementData) async {
        guard announcement.content == nil else { return }
        guard let url = URL(string: announcement.url) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server rejected or session expired")
                return
            }
            guard let html = String(data: data, encoding: .utf8) else { return }
            let document = try SwiftSoup.parse(html)
            
            let contentText = try document.select("div.fs-text-break-word.bulletin-content").text()
            var extractedAttachments: [Attachment] = []
            let fileLinks = try document.select("div.fs-list.fs-filelist a")
            
            for link in fileLinks {
                let fileName = try link.text().trimmingCharacters(in: .whitespacesAndNewlines)
                let fileUrl = try link.attr("href")
                let fullFileUrl = "https://lms2020.nchu.edu.tw" + fileUrl
                
                if !fileName.isEmpty && !fileUrl.isEmpty {
                    let newAttachment = Attachment(name: fileName, url: fullFileUrl)
                    extractedAttachments.append(newAttachment)
                }
            }
            
            await MainActor.run {
                announcement.setContentAndAttachments(content: contentText, attachments: extractedAttachments)
            }
            
            print("Got announcement content：\(announcement.title)")
            print("Got \(extractedAttachments.count) attachments")
            
            try? await Task.sleep(nanoseconds: 500000000)
            
        } catch {
            print("Fetch \(announcement.title) content failed: \(error.localizedDescription)")
        }
    }
    
    func download(for attachment: Attachment) async -> URL? {
        guard let url = URL(string: attachment.url) else { return nil }
                
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        do {
            let (tempURL, response) = try await URLSession.shared.download(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Fail in downloading")
                return nil
            }
            
            let fileManager = FileManager.default
            
            guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                return nil
            }
            
            let safeFileName = attachment.name.removingPercentEncoding ?? attachment.name
            let destinationURL = cacheDirectory.appendingPathComponent(safeFileName)
            
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            print("Downloaded attachment to：\(destinationURL.path)")
            return destinationURL
        } catch {
            print("Error: \(error)")
            return nil
        }
    }
    
    func fetchHomeworkList(course: CourseData) async {
        let urlString = "https://lms2020.nchu.edu.tw/course/homeworkList/\(course.id)"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
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
                        detailUrl = "https://lms2020.nchu.edu.tw" + detailPath
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
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
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
            //print(startStr)
            let dueStr = try dl.select("dt:contains(繳交期限) + dd").text()
            //print(dueStr)
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
            try? await Task.sleep(nanoseconds: 500000000)
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

class ILearningScraperPrepare: NSObject, WKNavigationDelegate {
    static let shared = ILearningScraperPrepare()
    
    private var hiddenWebView: WKWebView!
    private var onResult: ((Bool) -> Void)?
    private var timeoutTimer: Timer?
    
    private var botWebView: WKWebView {
        return SharedWebBot.shared.webView
    }
    
    func fetchRequiredCookie(completion: @escaping (Bool) -> Void) {
        print("Start CAS process...")
        self.onResult = completion
        
        botWebView.navigationDelegate = self
        
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            print("Timeout!")
            self?.finish(success: false)
        }
        
        if let url = URL(string: "https://lms2020.nchu.edu.tw/sys/oitc/oa_redirect.php") {
            botWebView.load(URLRequest(url: url))
        }
    }
    
    private func finish(success: Bool) {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        let callback = onResult
        onResult = nil
        
        DispatchQueue.main.async {
            callback?(success)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url?.absoluteString else { return }
        print("Go to: \(url)")
        
        let isFinalDestination = url.contains("lms2020.nchu.edu.tw") && url.contains("dashboard")
        && !url.contains("ccidp.nchu.edu.tw") && !url.contains("cas_login")
        
        if isFinalDestination {
            print("Reach the final destination!")
            
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                print("Got \(cookies.count) Cookies")
                let hasTS = cookies.contains { $0.name.starts(with: "TS") }
                                
                if hasTS {
                    CookieManager.shared.saveCookies(cookies)
                    print("Successfully got TS Cookie！")
                    self.finish(success: true)
                } else {
                    print("Reached the final destination but no TS Cookie...")
                }
                
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                    print("   - \(cookie.name)")
                }
            }
            
        } else if url.contains("ccidp.nchu.edu.tw/login?") {
            print("Session Expired")
            CookieManager.shared.clearCookies()
        } else if url.contains("challenges.cloudflare.com") && url.contains("challenge-platform") {
            print("Cloudflare challenge...")
        } else {
            print("Loading...")
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url {
            print("Will going to: \(url.absoluteString)")
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Loading web page failed：\(error.localizedDescription)")
        finish(success: false)
    }
    
    func setupHiddenWebView(in window: UIWindow?) {
        guard let window = window else { return }
        
        hiddenWebView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        hiddenWebView.alpha = 0.0
        hiddenWebView.isUserInteractionEnabled = false
        
        window.addSubview(hiddenWebView)
    }
}
