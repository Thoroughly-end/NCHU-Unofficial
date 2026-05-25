//
//  AnnouncementService.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/5/25.
//
import Foundation
import SwiftSoup

class AnnouncementService {
    private let baseURL = AppConstants.Network.baseURL
    
    func fetchLatestAnnouncements() async -> [AnnouncementData] {
        let latestBulletinURLString = "\(baseURL)/dashboard/latestBulletin"
        guard let url = URL(string: latestBulletinURLString) else { return [] }
        
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
            await self.fetchAnnouncementContent(for: announcement)
        }
    }
    
    func fetchAnnouncementContent(for announcement: AnnouncementData) async {
        guard announcement.content == nil else { return }
        guard let url = URL(string: announcement.url) else { return }
        
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
            
            let contentText = try document.select("div.fs-text-break-word.bulletin-content").text()
            var extractedAttachments: [Attachment] = []
            let fileLinks = try document.select("div.fs-list.fs-filelist a")
            
            for link in fileLinks {
                let fileName = try link.text().trimmingCharacters(in: .whitespacesAndNewlines)
                let fileUrl = try link.attr("href")
                let fullFileUrl = baseURL + fileUrl
                
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
        request.setValue(AppConstants.Network.userAgent, forHTTPHeaderField: "User-Agent")
        
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
}
