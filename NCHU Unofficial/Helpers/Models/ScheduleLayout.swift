//
//  ScheduleLayout.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/9/11.
//

import Foundation

enum ScheduleLayout {
    static let periodPerDay: Int = 13
    static let periodTimes = ScheduleLayout.generatePeriods()
    
    static func generatePeriods() -> [(start: (hour: Int, minute: Int), end: (hour: Int, minute: Int))] {
        var i = 0
        var startHour = 8
        var startMinute = 10
        var endHour = 9
        var endMinute = 0
        var periods: [(start: (hour: Int, minute: Int), end: (hour: Int, minute: Int))] = []
        while i < 13 {
            periods.append((start: (hour: startHour, minute: startMinute), end: (hour: endHour, minute: endMinute)))
            
            if i < 8 {
                if i == 3 {
                    startHour += 2
                    endHour += 2
                } else {
                    startHour += 1
                    endHour += 1
                }
            } else {
                startHour += 1
                endHour += 1
                if i == 11 {
                    endHour -= 1
                }
                if i == 8 {
                    startMinute = 20
                    endMinute = 10
                } else {
                    startMinute -= 5
                    endMinute -= 5
                    endMinute = endMinute < 0 ? endMinute + 60 : endMinute
                }
            }
            
            i += 1
        }
        return periods
    }
}
