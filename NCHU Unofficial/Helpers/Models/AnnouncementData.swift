//
//  AnnouncementData.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/5/22.
//

import Combine
import Foundation

class AnnouncementData: Identifiable, ObservableObject {
    var courseID: Int
    var title: String
    var url: String
    var date: Date?
    
    @Published var content: String?
    @Published var attachments: [Attachment] = []
    
    init(courseID: Int, title: String, url: String, date: Date?) {
        self.courseID = courseID
        self.title = title
        self.url = url
        self.date = date
        self.content = nil
    }
    
    func setContentAndAttachments(content: String, attachments: [Attachment]) {
        DispatchQueue.main.async {
            self.content = content
            self.attachments = attachments
        }
    }
}
