//
//  ContentView.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//
import SwiftUI

enum APPTab: String, MorphingTabProtocol {
    case schedule = "schedule"
    case reminders = "reminders"
    case courses = "courses"
    case settings = "settings"
    
    var symbolImage: String {
        return switch self {
        case .schedule: "calendar"
        case .reminders: "bell.fill"
        case .courses: "book.closed.fill"
        case .settings: "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var activeTab: APPTab = .schedule
    @State private var isExpanded: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: DataManager
    
    
    var body: some View {
        @State var backgroundColor: Color = colorScheme  == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
        @State var textColor: Color = colorScheme == .dark ? Color.white : Color.black
        
        ZStack {
            Color(backgroundColor).ignoresSafeArea()
            
            
            switch activeTab {
            case .schedule:
                Schedule()
            case .reminders:
                Announcements()
            case .courses:
                Courses()
            case .settings:
                Settings()
            }
            VStack {
                Spacer()
                MorphingTabBar(activeTab: $activeTab, isExpanded: $isExpanded) {
                    
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
            .ignoresSafeArea(.all , edges: .bottom)
        }
        .onAppear() {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = windowScene.windows.first {
                SharedWebBot.shared.attachToWindow(window)
            }
            
            if dataManager.isLoggedIn == false {
                dataManager.showLoginSheet = true
            }
        }
        .sheet(isPresented: $dataManager.showLoginSheet) {
            LoginSheetView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
}

