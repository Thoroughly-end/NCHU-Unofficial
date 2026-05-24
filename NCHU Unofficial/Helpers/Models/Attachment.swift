//
//  AttachmentData.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/5/22.
//

import Foundation

struct Attachment: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    
    init(name: String, url: String) {
        self.name = name.removingBracket()
        self.url = url
    }
}
