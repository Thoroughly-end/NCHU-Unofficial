//
//  ContentView.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//
import SwiftUI

enum APPTab: String {
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
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        TabView(selection: $activeTab) {
            Tab("Schedule", systemImage: APPTab.schedule.symbolImage, value: APPTab.schedule) {
                Schedule()
                    .ignoresSafeArea(.container, edges: .bottom)
            }
            
            Tab("Courses", systemImage: APPTab.courses.symbolImage, value: APPTab.courses) {
                AllCourses()
                    .ignoresSafeArea(.container, edges: .bottom)
            }
            
            Tab("Setting", systemImage: APPTab.settings.symbolImage, value: APPTab.settings) {
                Settings()
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .tint(.blue)
        .onAppear() {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = windowScene.windows.first {
                SharedWebBot.shared.attachToWindow(window)
            }
            
            if dataManager.isLoggedIn == false {
                dataManager.showLoginSheet = true
            }
        }
        .sheet(isPresented: $dataManager.showLoginSheet) {
            NavigationView {
                Login()
                    .navigationTitle("Login")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cancel") {
                                dataManager.showLoginSheet = false
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
}

