//
//  Account.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI
import WebKit

struct Account: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        @State var backgroundColor: Color = colorScheme  == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
        @State var textColor: Color = colorScheme == .dark ? Color.white : Color.black
        
        ZStack {
            Color(backgroundColor).ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    if authManager.isLoggedIn == false {
                        Image(systemName: "person.crop.circle")
                            .font(.title)
                            .padding(.vertical)
                        Spacer()
                        Button(action: {authManager.showLoginSheet = true}) {
                            Text("Sign In")
                                .font(.title2)
                                .foregroundStyle(Color(textColor))
                                .padding(10)
                        }
                        .glassEffect(.clear.tint(Color.green))
                        .padding(.trailing, -10)
                            
                    } else {
                        Image(systemName: "person.crop.circle")
                            .font(.title)
                            .padding(.vertical)
                        Spacer()
                        Button(action: authManager.logout) {
                            Text("Sign Out")
                                .font(.title2)
                                .foregroundStyle(Color(textColor))
                                .padding(10)
                        }
                        .glassEffect(.clear.tint(Color.red))
                        .padding(.trailing, -10)
                    }
                }
                .padding(.horizontal, 50)
                .glassEffect()
                Spacer()
            }
            .padding(.horizontal, 40)
            
            
        }
        
    }
}

#Preview {
    Account()
        .environmentObject(AuthManager())
}
