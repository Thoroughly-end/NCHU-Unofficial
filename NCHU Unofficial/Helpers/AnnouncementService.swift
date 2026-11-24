//
//  AnnouncementService.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/5/25.
//
import Foundation
import SwiftSoup
import UniformTypeIdentifiers

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
        await withTaskGroup(of: Void.self) { group in
            for announcement in course.announcements {
                group.addTask {
                    await self.fetchAnnouncementContent(for: announcement)
                }
            }
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
                let rawFileName = try link.select("span.text").first()?.ownText() ?? link.text()
                let fileName = rawFileName.trimmingCharacters(in: .whitespacesAndNewlines)
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
            //if let announcementContent = announcement.content {
            //    print("Got announcement body: \(announcementContent.prefix(20))")
            //}
           
            print("Got \(extractedAttachments.count) attachments")
            
            //try? await Task.sleep(nanoseconds: 500000000)
            
        } catch {
            print("Fetch \(announcement.title) content failed: \(error.localizedDescription)")
        }
    }
    
    /// Extracts the file name from a Content-Disposition header, handling `filename*=UTF-8''...`,
    /// percent-encoded names, and raw UTF-8/Big5 bytes that Foundation decoded as Latin-1.
    static func fileName(fromContentDisposition header: String) -> String? {
        func value(of key: String) -> String? {
            let pattern = "\(key)\\s*=\\s*(\"([^\"]*)\"|[^;]*)"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: header, range: NSRange(header.startIndex..., in: header)) else {
                return nil
            }
            let quoted = Range(match.range(at: 2), in: header).map { String(header[$0]) }
            let whole = Range(match.range(at: 1), in: header).map { String(header[$0]) }
            return (quoted ?? whole)?.trimmingCharacters(in: .whitespaces)
        }

        // RFC 5987: filename*=charset'lang'percent-encoded
        if let extended = value(of: "filename\\*") {
            let parts = extended.split(separator: "'", maxSplits: 2, omittingEmptySubsequences: false)
            if parts.count == 3 {
                let encoding: String.Encoding = parts[0].lowercased() == "utf-8" ? .utf8 : .isoLatin1
                if let decoded = String(parts[2]).removingPercentEncoding,
                   encoding == .utf8 { return decoded }
                if let data = String(parts[2]).removingPercentEncoding?.data(using: .isoLatin1),
                   let decoded = String(data: data, encoding: encoding) { return decoded }
            }
        }

        guard var name = value(of: "filename(?!\\*)"), !name.isEmpty else { return nil }
        if let decoded = name.removingPercentEncoding { name = decoded }

        // Mojibake repair: bytes were read as Latin-1; reinterpret them as UTF-8, then Big5.
        if name.unicodeScalars.contains(where: { $0.value > 0x7F }),
           let data = name.data(using: .isoLatin1) {
            if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
            let big5 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.big5.rawValue)))
            if let decoded = String(data: data, encoding: big5) { return decoded }
        }
        return name
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
            
            // Prefer the real file name sent by the server (Content-Disposition); the passed-in name
            // may have a guessed extension. suggestedFilename is URL-derived without that header.
            var fileName = attachment.name
            if let header = httpResponse.value(forHTTPHeaderField: "Content-Disposition"),
               let serverName = Self.fileName(fromContentDisposition: header) {
                fileName = serverName
            } else if let mime = response.mimeType,
                      let mimeType = UTType(mimeType: mime),
                      let mimeExt = mimeType.preferredFilenameExtension,
                      !(UTType(filenameExtension: (fileName as NSString).pathExtension)?.conforms(to: mimeType) ?? false) {
                // No server-provided name: correct the extension from the actual content type.
                fileName = ((fileName as NSString).deletingPathExtension) + "." + mimeExt
            }
            let safeFileName = (fileName.removingPercentEncoding ?? fileName)
                .replacingOccurrences(of: "/", with: "_")
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
