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
    @EnvironmentObject var authManager: AuthManager
    
    
    var body: some View {
        @State var backgroundColor: Color = colorScheme  == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
        @State var textColor: Color = colorScheme == .dark ? Color.white : Color.black
        
        ZStack {
            Color(backgroundColor).ignoresSafeArea()
            
            
            VStack(spacing: 0) {
                switch activeTab {
                case .schedule:
                    Schedule()
                case .reminders:
                    Reminders()
                case .courses:
                    Courses()
                case .settings:
                    Settings()
                }
                
                
                Spacer()
                
                ZStack(alignment: .bottom) {
                    MorphingTabBar(activeTab: $activeTab, isExpanded: $isExpanded) {
                        
                    }
                    .padding(.horizontal, 20)
                    
                }
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .onAppear() {
            if authManager.isLoggedIn == false {
                authManager.showLoginSheet = true
            }
        }
        .sheet(isPresented: $authManager.showLoginSheet) {
            LoginSheetView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}

