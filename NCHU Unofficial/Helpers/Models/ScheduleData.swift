//
//  ScheduleData.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/5/22.
//

import Foundation

struct ScheduleData: Codable, Equatable {
    var name: String?
    var teacher: String?
    var location: String?
    
    init(text: String) {
        guard text != "nil", !text.isEmpty else { return }
        
        let parts = text.split(separator: " ").map(String.init)
        
        guard parts.count > 1 else {
            self.name = text.removingBracket()
            return
        }
        
        if let lastPart = parts.last {
            let info = parseTeacherAndRoom(lastPart)
            self.teacher = info.teacher
            self.location = info.room
            
            if self.teacher == nil && self.location == nil {
                self.teacher = lastPart
            }
        }
        let nameParts = parts.dropLast()
        self.name = nameParts.joined(separator: " ").removingBracket()
    }
    
    private func parseTeacherAndRoom(_ input: String) -> (teacher: String?, room: String?) {
        let regex = /^(.+?)([A-Za-z]{1,2}\d{3})$/

        if let match = input.wholeMatch(of: regex) {
            return (String(match.output.1), String(match.output.2))
        }
        return (nil, nil)
    }
}

extension String {
    func removingBracket() -> String {
        if let firstPart = self.split(separator: "(").first {
            return String(firstPart).trimmingCharacters(in: .whitespaces)
        }
        return self
    }
}
