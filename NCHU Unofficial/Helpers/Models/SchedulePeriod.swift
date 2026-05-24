//
//  SchedulePeriod.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/5/22.
//

import Foundation

struct Period: Identifiable {
    let id = UUID()
    let day: Int
    let range: ClosedRange<Int>
    let info: ScheduleData
}

struct SchedulePeriod {
    let schedule: [ScheduleData]
    var periods: [Period] = []
    
    init(schedule: [ScheduleData]) {
        self.schedule = schedule
        
        if schedule.count < 91 { return }
        
        for i in 1...7 {
            var currentCourse = ScheduleData(text: "nil")
            var start = 0
            for j in 1...13 {
                
                if currentCourse.name == nil {
                    currentCourse = schedule[(j - 1) * 7 + (i - 1)]
                    start = j
                    continue
                }
                
                if currentCourse != schedule[(j - 1) * 7 + (i - 1)] {
                    if currentCourse.name == nil { continue }
                    periods.append(Period(day: i, range: start...(j - 1), info: currentCourse))
                    
                    start = j
                    currentCourse = schedule[(j - 1) * 7 + (i - 1)]
                }
                
                if j == 13 {
                    if currentCourse.name == nil { continue }
                    periods.append(Period(day: i, range: start...13, info: currentCourse))
                }
            }
        }
    }
}
