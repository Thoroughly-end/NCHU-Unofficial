//
//  Settings.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI

struct LinkInfo: Identifiable {
    let id = UUID()
    let title: String
    let destination: AnyView
    let icon1: String
    let icon2: String
}

struct Settings: View {
    @State var backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
    
    var links: [LinkInfo] = [
        LinkInfo(title: "Account", destination: AnyView(Account()), icon1: "person.circle", icon2: "chevron.right"),
        LinkInfo(title: "Info", destination: AnyView(AboutThisAPP()), icon1: "info.circle", icon2: "chevron.right"),
    ]
    
    var body: some View {
        NavigationView {
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
        }
    }
}

private struct LinkView: View {
    let item: LinkInfo
    
    var body: some View {
        NavigationLink(destination: item.destination) {
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
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 50)
        .glassEffect()
    }
}
#Preview {
    ContentView()
        .environmentObject(DataManager())
}
