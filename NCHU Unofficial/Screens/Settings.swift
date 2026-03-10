//
//  Settings.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI

enum SettingsRoute: Hashable {
    case account
    case info
}

struct LinkInfo: Identifiable {
    let id = UUID()
    let title: String
    let route: SettingsRoute?
    let icon1: String
    let icon2: String
}

struct Settings: View {
    @State var backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
    
    var links: [LinkInfo] = [
        LinkInfo(title: "Account", route: .account, icon1: "person.circle", icon2: "chevron.right"),
        LinkInfo(title: "Info", route: .info, icon1: "info.circle", icon2: "chevron.right"),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(backgroundColor).ignoresSafeArea()
                
                VStack {
                    HStack {
                        Text("Settings")
                            .font(.largeTitle)
                            .bold()
                            .padding(.leading, 50)
                            .padding(.top, 20)
                        Spacer()
                    }
                    
                    VStack(spacing: 20) {
                        ForEach (links) { link in
                            LinkView(item: link)
                        }
                        Spacer()
                    }
                    .padding(40)
                }
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .account: Account()
                case .info: AboutThisAPP()
                }
            }
        }
    }
}

private struct LinkView: View {
    let item: LinkInfo
    
    var body: some View {
        NavigationLink(value: item.route) {
            HStack {
                Image(systemName: item.icon1)
                    .font(.title)
                Spacer()
                Text(item.title)
                    .font(.title2)

                Image(systemName: item.icon2)
                    .font(.title2)
            }
            .foregroundStyle(Color.primary)
            .padding(.vertical, 20)
            .padding(.horizontal, 50)
            .glassEffect()
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    ContentView()
        .environmentObject(DataManager())
}
