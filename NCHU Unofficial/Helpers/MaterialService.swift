//
//  MaterialService.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/9/16.
//

import Foundation
import SwiftSoup

class MaterialService {
    private let baseURL = AppConstants.Network.baseURL
    
    func fetchMaterialList(for course: CourseData) async {
        let urlString = "\(baseURL)/course/material/\(course.id)"
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
            
            let rows = try document.select("table#materialListTable tr").dropFirst()
            let noData: Bool = try !document.select("table#homeworkListTable tr#noData").isEmpty()
            
            if noData {
                print("There is no material")
                return
            }
            
            for row in rows {
                let cells = try row.select("td")
                
                guard let element = try cells.select("a").first() else { continue }
                let detailPath = try element.attr("href")
                let title = try element.text()
                var updateDate = Date()
                if let dateEntry = cells.last() {
                    let date = try dateEntry.select("div.text-overflow").text()
                    updateDate = MessyDateHelper.shared.parseMessyDate(date)
                }
                course.addMaterial(Material(url: baseURL + detailPath, courseID: course.id, title: title, updateDate: updateDate))
                print("Materal fetched: title = \(title)")
                print("\(baseURL + detailPath)")
            }
        } catch {
            print("error when fetching material list: \(error)")
            return
        }
    }
    
    func fetchMaterialDetail(for material: Material) async {
        guard let url = URL(string: material.url) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(AppConstants.Network.userAgent, forHTTPHeaderField: "User-Agent")
        print("Start fetching detail")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server rejected or session expired")
                return
            }
            
            guard let html = String(data: data, encoding: .utf8) else { return }
            let document = try SwiftSoup.parse(html)
            
            let titleSection = try document.select("div.module.mod_media.mod_media-docTitle")
            let titleSectionPath = try titleSection.select("a").first()?.attr("href")
            
            
            let xboxInlineSection = try document.select("div#xbox-inline")
            let xboxInlineSectionPath = try xboxInlineSection.select("a[href*=/media/docDownload/]").first()?.attr("href")
            
            let attachmentSection = try document.select("div.module.mod_media.mod_media-attachList")
            let attachments = try attachmentSection.select("a")
            var attachmentList: [Attachment] = []
            for attachment in attachments {
                let path: String = try attachment.attr("href")
                let fullPath = baseURL + path
                let rawName = try attachment.select("span.text").first()?.ownText() ?? attachment.text()
                let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty && !path.isEmpty {
                    attachmentList.append(Attachment(name: name, url: fullPath))
                }
            }
            if !(titleSectionPath == nil && xboxInlineSectionPath == nil && attachmentList.isEmpty) {
                let pptxUrl = titleSectionPath != nil ? baseURL + titleSectionPath! : nil
                let pdfUrl = xboxInlineSectionPath != nil ? baseURL + xboxInlineSectionPath! : nil
                material.setPDFandAttachments(pptxUrl: pptxUrl, pdfUrl: pdfUrl, attachments: attachmentList)
                if let pptx = pptxUrl {
                    print("\(pptx)")
                }
                if let pdf = pdfUrl {
                    print("\(pdf)")
                }
            }
            
        } catch {
            print("Failed to fetch material detail：\(error)")
            return
        }
    }
}
