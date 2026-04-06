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
    let elementBgColor = Color("ElementBackgroundColor")
    
    private var processedPeriods: [Period] {
        guard !dataManager.scheduleList.items.isEmpty else { return [] }
        return SchedulePeriod(schedule: dataManager.scheduleList.items).periods
    }
    
    init() {
        UIScrollView.appearance().bounces = false
    }
    
    var body: some View {
        VStack {
            if isCheckingSession {
                ProgressView("Checking Session")
            } else {
                if !dataManager.scheduleList.items.isEmpty {
                    if dataManager.scheduleList.items.count < 91 {
                        Text("Insufficient data")
                    } else {
                        VStack {
                            headerSection
                                .padding(.bottom, 20)
                            scheduleTable
                            Spacer()
                        }
                        .padding(.horizontal,30)
                    }
                } else {
                    Text("Please login")
                }
            }
        }
        .onAppear {
            initialLoad()
        }
        .onChange(of: dataManager.hasCportalCookies) {
            initialLoad()
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("My Schedule")
                .font(.largeTitle)
                .bold()
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
                .glassEffect(.regular.interactive())
            }
        }
    }
    
    private var scheduleTable: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                let days = 0...7
                HStack(spacing: 10) {
                    ForEach(days, id: \.self) { day in
                        DayCard(day: day)
                    }
                }
                .padding(10)
                
                
                ScrollView(.vertical, showsIndicators: false) {
                    let periods = 1...13
                    HStack(spacing: 10) {
                        VStack {
                            ForEach(periods, id: \.self) { period in
                                TimeCard(time: period)
                            }
                        }
                        .frame(width: 40)
                        
                        
                        HStack(spacing: 10) {
                            ForEach(days.dropFirst(), id: \.self) { day in
                                VStack(alignment: .leading, spacing: 0) {
                                    ZStack(alignment: .top) {
                                        Color.clear
                                            .frame(height: CGFloat(2070))
                                        let today = processedPeriods.filter { $0.day == day }
                                        ForEach(today) { period in
                                            let start = period.range.lowerBound
                                            
                                            Card(period: period)
                                                .offset(y: CGFloat((start - 1) * 160))
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: 550, height: 2070, alignment: .top)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
                
            }
            .clipShape(.rect(cornerRadius: 30))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(elementBgColor)
        )
        .padding(.bottom, 100)
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
                        let period: SchedulePeriod = .init(schedule: newSchedule)
                        for p in period.periods {
                            print(p.day)
                            if let name = p.info.name {
                                print(name)
                            }
                            if let location = p.info.location {
                                print(location)
                            }
                            
                            print(p.range.lowerBound)
                            print(p.range.upperBound)
                        }
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

#Preview {
    Schedule()
        .environmentObject(DataManager())
}
