//
//  MessyDateHelper.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/9/23.
//

import Foundation

class MessyDateHelper {
    static let shared = MessyDateHelper()
    
    func parseMessyDate(_ dateString: String) -> Date {
        let cleanedString = dateString.trimmingCharacters(in: .whitespacesAndNewlines)

        if let match = cleanedString.range(of: #"^(\d+)\s*(天前|小時前)$"#, options: .regularExpression) {
            let matchedString = cleanedString[match]
            let component: Calendar.Component = matchedString.hasSuffix("小時前") ? .hour : .day
            let numberString = matchedString.replacingOccurrences(of: "天前", with: "").replacingOccurrences(of: "小時前", with: "").trimmingCharacters(in: .whitespaces)
            if let amountAgo = Int(numberString) {
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(identifier: "Asia/Taipei") ?? .current
                return calendar.date(byAdding: component, value: -amountAgo, to: Date()) ?? Date()
            }
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        
        let possibleFormats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "yyyy/MM/dd HH:mm",
            "yyyy/MM/dd",
            "MM-dd HH:mm",
            "MM-dd"
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
