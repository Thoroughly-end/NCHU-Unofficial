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
    
    var body: some View {
        @State var backgroundColor: Color = colorScheme  == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
        @State var textColor: Color = colorScheme == .dark ? Color.white : Color.black
        VStack {
            if isCheckingSession {
                ProgressView("Checking Session")
            } else {
                if isLoggedIn {
                    let days = 0..<8
                    let times = 1..<14
                    //Text("You have logged in")
                    if scheduleList.items.count < 91 {
                        Text("no enough data")
                    } else {
                        VStack(alignment: .leading) {
                            Text("My Schedule")
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundColor(textColor)
                                .padding(.horizontal)
                                .padding(.top, 20)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 10) {
                                    ForEach(days, id: \.self) { day in
                                        DayCard(day: day)
                                    }
                                }
                                ScrollView(.vertical, showsIndicators: false) {
                                    ForEach(times, id: \.self) { time in
                                        HStack (alignment: .top, spacing: 10) {
                                            TimeCard(time: time)
                                            ForEach(days, id: \.self) { day in
                                                if !(day == 0) {
                                                    Card(course: scheduleList.items[(time - 1) * 7 + day - 1])
                                                }
                                                
                                                
                                            }
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                    
                } else {
                    
                    
                    Text("You are not logging in")
                    
                    
                }
            }
        }
        .onAppear() {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = windowScene.windows.first {
                ScheduleScraperPrepare.shared.setupHiddenWebView(in: window)
            }
            
            if isLoggedIn {
                isCheckingSession = true
                SessionManager.shared.verifyCookieStatus { isValid in
                    isCheckingSession = false
                    if isValid {
                        print("Valid Session")
                        if !dataManager.hasFullCookies {
                            ScheduleScraperPrepare.shared.fetchRequiredCookie { success in
                                if success {
                                    Task {
                                        dataManager.hasFullCookies = true
                                        let schedule = await ScheduleScraper.shared.fetchSchedule()
                                        if (schedule == nil) {
                                            scheduleList.items = []
                                        } else {
                                            scheduleList.items = schedule!
                                        }
                                    }
                                } else {
                                    isCheckingSession = false
                                }
                            }
                        }
                        
                    }
                    else {
                        if isLoggedIn {
                            isLoggedIn = false
                        }
                        print("Session Expired")
                    }
                }
            }
        }
    }
}


#Preview {
    Schedule()
        .environmentObject(DataManager())
}
