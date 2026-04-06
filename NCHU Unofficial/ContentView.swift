//
//  ContentView.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//
import SwiftUI

enum APPTab: String, MorphingTabProtocol {
    case schedule = "schedule"
    case courses = "courses"
    case settings = "settings"
    
    var symbolImage: String {
        return switch self {
        case .schedule: "calendar"
        case .courses: "book.closed.fill"
        case .settings: "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var activeTab: APPTab = .schedule
    @State private var isExpanded: Bool = false
    @State var backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
    @EnvironmentObject var dataManager: DataManager
    
    
    var body: some View {
        ZStack {
            Color(backgroundColor).ignoresSafeArea()
            switch activeTab {
            case .schedule:
                Schedule()
                    .ignoresSafeArea(.all, edges: .bottom)
            case .courses:
                AllCourses()
                    .ignoresSafeArea(.all, edges: .bottom)
            case .settings:
                Settings()
                    .ignoresSafeArea(.all, edges: .bottom)
            }
            VStack {
                Spacer()
                MorphingTabBar(activeTab: $activeTab, isExpanded: $isExpanded) {}.padding(.horizontal, 20)
            }
            .padding(.bottom, 30)
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

