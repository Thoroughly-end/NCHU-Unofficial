//
//  Settings.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI

struct Settings: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        @State var backgroundColor: Color = colorScheme  == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
        @State var textColor: Color = colorScheme == .dark ? Color.white : Color.black
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
                        NavigationLink(destination: Account()) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .font(.title)
                                    .padding(.bottom)
                                    
                                Spacer()
                                Text("Account")
                                    .font(.title2)
                                    .padding(.bottom)

                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .padding(.bottom)
                            }
                            .foregroundStyle(textColor)
                        }
                        .padding(.horizontal, 50)
                        .padding(.top, 20)
                        .glassEffect()
                        
                        NavigationLink(destination: AboutThisAPP()) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .font(.title)
                                    .padding(.bottom)
                                Spacer()
                                Text("Info")
                                    .font(.title2)
                                    .padding(.bottom)
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .padding(.bottom)
                            }
                            .foregroundStyle(textColor)
                                
                        }
                        .padding(.horizontal, 50)
                        .padding(.top, 20)
                        .glassEffect()
                        
                        Spacer()
                    }
                    .padding(40)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
