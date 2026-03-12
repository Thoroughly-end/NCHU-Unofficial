//
//  aboutThisAPP.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI
import Foundation

struct AboutItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let content: String
    let action: (() -> Void)?
}

struct DeveloperInformation: Identifiable {
    let id = UUID()
    let row1: AboutItem
    let row2: AboutItem
}

struct AboutThisAPP: View {
    @State private var showCopiedToast: Bool = false
    @State var backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown Version"
    private let developer: DeveloperInformation = DeveloperInformation(row1: AboutItem(icon: "person.fill", title: "Developer", content: "Chia-Chun Kuo", action: nil), row2: AboutItem(icon: "envelope.fill", title: "Email", content: "allenkuo0818@gmail.com", action: nil))
    private var aboutItems: [AboutItem] {[
        AboutItem(icon: "exclamationmark.circle.fill", title: "Version", content: appVersion, action: nil)
    ]}
    
    var body: some View {
        ZStack {
            Color(backgroundColor).ignoresSafeArea()
            VStack(spacing: 30) {
                headerSection
                DeveloperInfoRow(info: developer, showCopiedToast: $showCopiedToast)
                InfoRow(item: aboutItems[0])
                Spacer()
            }
            .padding(20)
        }
        .overlay(toastOverlay)
    }
    
    private var headerSection: some View {
        VStack{
            Image(systemName: "graduationcap.circle.fill")
                .resizable()
                .frame(maxWidth: 70, maxHeight: 70)
                .padding(.top)
            Text("NCHU Unofficial")
                .font(.title.bold())
                .padding(.bottom)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .glassEffect()
    }
    
    private var toastOverlay: some View {
        VStack {
            Spacer()
            if showCopiedToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Copied to clipboard")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.primary)
                }
                .padding()
                .glassEffect()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.bottom, 50)
        .animation(.spring(), value: showCopiedToast)
        .allowsHitTesting(false)
    }
}

struct DeveloperInfoRow: View {
    let info: DeveloperInformation
    @Binding var showCopiedToast: Bool
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: info.row1.icon)
                    .font(.title2)
                Text(info.row1.title).font(.title3)
                Spacer()
                Text(info.row1.content)
            }
            .frame(height: 60, alignment: .center)
            .padding(.horizontal, 30)
            
            Divider()
            
            HStack {
                Image(systemName: info.row2.icon).font(.title2)
                Text(info.row2.title).font(.title3)
                Spacer()
                Text(verbatim: info.row2.content)
                    .foregroundColor(.blue)
                    .onTapGesture {
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            showCopiedToast = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showCopiedToast = false
                            }
                        }
                    }
                    
            }
            .frame(height: 60, alignment: .center)
            .padding(.horizontal, 30)
        }
        .glassEffect()
    }
}

struct InfoRow: View {
    let item: AboutItem
    var body: some View {
        VStack {
            HStack {
                Image(systemName: item.icon).font(.title2)
                Text(item.title).font(.title3)
                Spacer()
                Text(item.content)
                    
            }
            .frame(height: 60, alignment: .center)
            .padding(.horizontal, 30)
        }
        .glassEffect()
    }
}

#Preview {
    AboutThisAPP()
}
