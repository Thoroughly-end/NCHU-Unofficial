//
//  Account.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI
import WebKit

struct Account: View {
    @State var backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
    
    var body: some View {
        ZStack {
            Color(backgroundColor).ignoresSafeArea()
            UserView()
        }
    }
}

struct UserView: View {
    @EnvironmentObject var dataManager: DataManager
    var buttonColor: Color {dataManager.isLoggedIn == true ? Color.red : Color.green}
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                if !dataManager.isLoggedIn {
                    Image(systemName: "person.crop.circle")
                        .font(.title)
                    Spacer()
                    Button(action: {dataManager.showLoginSheet = true}) {
                        Text("Sign In")
                            .font(.title2)
                            .foregroundStyle(Color.primary)
                            .padding(10)
                    }
                    .glassEffect(.clear.interactive().tint(buttonColor))
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.title)
                    Spacer()
                    Button(action: dataManager.logout) {
                        Text("Sign Out")
                            .font(.title2)
                            .foregroundStyle(Color.primary)
                            .padding(10)
                    }
                    .glassEffect(.clear.interactive().tint(buttonColor))
                }
                
            }
            .frame(height: 70)
            .padding(.horizontal, 50)
            .glassEffect()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    Account()
        .environmentObject(DataManager())
}
