//
//  Schedule.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI

struct Schedule: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("scheduleList") private var scheduleList = ScheduleWrapper(items: [])
    @State private var isCheckingSession: Bool = false
    
    var body: some View {
        VStack {
            if isCheckingSession {
                ProgressView("Checking Session")
            } else {
                if isLoggedIn {
                    Text("You have logged in")
                    Text(scheduleList.rawValue)
                } else {
                    Text("You are not logging in")
                }
            }
        }
        .onAppear() {
            if isLoggedIn {
                isCheckingSession = true
                SessionManager.shared.verifyCookieStatus { isValid in
                    isCheckingSession = false
                    if isValid {
                        print("Valid Session")
                        ScheduleScraperPrepare.shared.fetchRequiredCookie {
                            Task {
                                let schedule = await ScheduleScraper.shared.fetchSchedule()
                                if (schedule == nil) {
                                    scheduleList.items = []
                                } else {
                                    scheduleList.items = schedule!
                                }
                            }
                        }
                    }
                    else {
                        if isLoggedIn {
                            isLoggedIn = false
                        }
                        CookieManager.shared.clearCookies()
                        print("Session Expired")
                    }
                }
            }
        }
    }
}
