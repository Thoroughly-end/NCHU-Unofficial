//
//  Constatnt.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/5/22.
//

import Foundation

enum AppConstants {
    enum Network {
        static let baseURL = "https://lms2020.nchu.edu.tw"
        static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        static let requestDelay: UInt64 = 500_000_000 // 0.5 second
    }
    
    enum Cache {
        static let sessionValidityDuration: TimeInterval = 60 // second
    }
    
    enum UI {
        static let recentDaysThreshold = 10
    }
}
