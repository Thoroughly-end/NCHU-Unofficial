//
//  Material.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/9/16.
//

import Foundation
import Combine

class Material: ObservableObject, Identifiable {
    let id: Int
    let url: String
    let courseID: Int
    @Published var downloadable: Bool
    @Published var attachments: [Attachment]?
    @Published var pdfUrl: String?
    
    init(id: Int, url: String, courseID: Int) {
        self.id = id
        self.url = url
        self.courseID = courseID
        self.downloadable = false
        self.attachments = nil
        self.pdfUrl = nil
    }
    
    func setPDFandAttachments(pdfUrl: String, attachments: [Attachment]?) {
        DispatchQueue.main.async {
            self.downloadable = true
            self.pdfUrl = pdfUrl
            self.attachments = attachments
        }
    }
}
