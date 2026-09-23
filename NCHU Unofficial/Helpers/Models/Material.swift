//
//  Material.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/9/16.
//

import Foundation
import Combine

class Material: ObservableObject, Identifiable {
    let url: String
    let courseID: Int
    let title: String
    let updateDate: Date
    @Published var downloadable: Bool
    @Published var attachments: [Attachment]
    @Published var pptxUrl: String?
    @Published var pdfUrl: String?

    init(url: String, courseID: Int, title: String, updateDate: Date) {
        self.url = url
        self.courseID = courseID
        self.title = title
        self.downloadable = false
        self.attachments = []
        self.pptxUrl = nil
        self.pdfUrl = nil
        self.updateDate = updateDate
    }

    func setPDFandAttachments(pptxUrl: String?, pdfUrl: String?, attachments: [Attachment]) {
        DispatchQueue.main.async {
            self.downloadable = true
            self.pptxUrl = pptxUrl
            self.pdfUrl = pdfUrl
            self.attachments = attachments
        }
    }
}
