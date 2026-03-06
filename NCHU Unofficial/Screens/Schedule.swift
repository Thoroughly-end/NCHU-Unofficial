//
//  Schedule.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI

struct Schedule: View {
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
                if dataManager.isLoggedIn {
                    let days = 0..<8
                    let times = 1..<14
                    
                    if dataManager.scheduleList.items.count < 91 {
                        Text("Not enough data")
                    } else {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("My Schedule")
                                    .font(.largeTitle)
                                    .bold()
                                    .padding(.leading, 50)
                                    .padding(.top, 10)
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
                                    .padding(.top, 10)
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
                                            ForEach(days, id: \.self) { day in
                                                if day != 0 {
                                                    Card(course: dataManager.scheduleList.items[(time - 1) * 7 + day - 1])
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
            initialLoad()
        }
    }
    
    private func initialLoad() {
        guard dataManager.isLoggedIn else { return }
        guard dataManager.hasCportalCookies else { return }
        
        if !dataManager.scheduleList.items.isEmpty {
            return
        }
        
        isCheckingSession = true
        SessionManager.shared.verifyCookieStatus { isValid in
            if isValid {
                print("Session valid, Start to fetch schedule")
                
                Task { @MainActor in
                    if let schedule = await ScheduleScraper.shared.fetchSchedule() {
                        dataManager.scheduleList.items = schedule
                    } else {
                        dataManager.scheduleList.items = []
                    }
                    isCheckingSession = false
                }
            } else {
                print("Session expired, please login again")
                DispatchQueue.main.async {
                    dataManager.logout()
                    isCheckingSession = false
                }
            }
        }
    }
    
    private func manualRefresh() {
        guard dataManager.isLoggedIn && dataManager.hasCportalCookies else { return }
        
        isCheckingSession = true
        SessionManager.shared.verifyCookieStatus { isValid in
            if isValid {
                isCheckingSession = false
                Task {
                    if let newSchedule = await ScheduleScraper.shared.fetchSchedule() {
                        dataManager.scheduleList.items = newSchedule
                        print("Manual refresh schedule successfully")
                    } else {
                        dataManager.scheduleList.items = []
                        print("Failure in manual refresh")
                    }
                }
            } else {
                print("Session expired, please login again")
                DispatchQueue.main.async {
                    dataManager.logout()
                    isCheckingSession = false
                }
            }
        }
        
        
    }
}
