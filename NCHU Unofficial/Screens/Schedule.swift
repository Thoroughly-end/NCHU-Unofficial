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
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
    }
    
    init() {
        UIScrollView.appearance().bounces = false
    }
    
    var body: some View {
        VStack {
            if isCheckingSession {
                ProgressView("Checking Session")
            } else {
                if isLoggedIn {
                    let days = 0..<8
                    let times = 1..<14
                    
                    if scheduleList.items.count < 91 {
                        Text("Not enough data")
                    } else {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("My Schedule")
                                    .font(.system(size: 34, weight: .black, design: .rounded))
                                    .foregroundColor(Color.primary)
                                    .padding(.horizontal)
                                    .padding(.top, 20)
                                Spacer()
                                
                                Button {
                                    manualRefresh()
                                } label: {
                                    VStack(alignment: .center) {
                                        Image(systemName: "arrow.trianglehead.counterclockwise")
                                            .font(.title3)
                                            .padding(.horizontal)
                                            .foregroundStyle(Color.primary)
                                    }
                                    .frame(width: 60, height: 60)
                                    .glassEffect()
                                    .padding(.horizontal)
                                    .padding(.top, 20)
                                }
                            }
                            .padding(.bottom, -20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 10) {
                                    ForEach(days, id: \.self) { day in
                                        DayCard(day: day)
                                            .padding(.top, 20)
                                    }
                                }
                                ScrollView(.vertical, showsIndicators: false) {
                                    ForEach(times, id: \.self) { time in
                                        HStack (alignment: .top, spacing: 10) {
                                            TimeCard(time: time)
                                                .glassEffect()
                                            ForEach(days, id: \.self) { day in
                                                if day != 0 {
                                                    Card(course: scheduleList.items[(time - 1) * 7 + day - 1])
                                                }
                                            }
                                        }
                                    }
                                    VStack {}.frame(height: 70)
                                }
                            }
                            .ignoresSafeArea()
                            Spacer()
                        }
                    }
                } else {
                    Text("Please login")
                }
            }
        }
        .onAppear {
            initialLoadIfNeeded()
        }
    }
    
    private func initialLoadIfNeeded() {
        guard isLoggedIn else { return }
        
        if dataManager.hasCportalCookies {
            return
        }
        
        isCheckingSession = true
        SessionManager.shared.verifyCookieStatus { isValid in
            if isValid {
                print("Session is valid, start to fetch schedule")
                Task {
                    dataManager.hasCportalCookies = true
                    if let schedule = await ScheduleScraper.shared.fetchSchedule() {
                        scheduleList.items = schedule
                    } else {
                        scheduleList.items = []
                    }
                    isCheckingSession = false
                }
            } else {
                print("Session expired")
                isLoggedIn = false
                dataManager.logout()
                isCheckingSession = false
            }
        }
    }
    
    private func manualRefresh() {
        guard isLoggedIn && dataManager.hasCportalCookies else { return }
        
        Task {
            if let newSchedule = await ScheduleScraper.shared.fetchSchedule() {
                scheduleList.items = newSchedule
                print("Manual refresh schedule successfully")
            } else {
                scheduleList.items = []
                print("Failure in manual refresh")
            }
        }
    }
}
