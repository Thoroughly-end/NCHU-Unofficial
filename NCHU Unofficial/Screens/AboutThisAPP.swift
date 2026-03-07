//
//  aboutThisAPP.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI
import Foundation

struct AboutThisAPP: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showCopiedToast: Bool = false
    
    var body: some View {
        @State var backgroundColor: Color = colorScheme  == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
        @State var textColor: Color = colorScheme == .dark ? Color.white : Color.black
        
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown Version"
        
        ZStack {
            Color(backgroundColor).ignoresSafeArea()
            VStack(spacing: 30) {
                
                VStack{
                    Image(systemName: "graduationcap.circle.fill")
                        .resizable()
                        .frame(maxWidth: 70, maxHeight: 70)
                    Text("NCHU Unofficial")
                        .font(.title)
                        .padding()
                        .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                .glassEffect()
                
            
                
                VStack {
                    HStack {
                        Image(systemName: "person.fill").font(.title2)
                            .padding(.vertical, 20)
                            .padding(.leading, 30)
                        Text("Developer").font(.title3)
                        Spacer()
                        Text("Chia-Chun Kuo")
                            .padding(.trailing, 30)
                    }
                    .frame(height: 100, alignment: .center)
                    .padding(.bottom, -20)
                    
                    HStack {
                        Image(systemName: "envelope.fill").font(.title2)
                            .padding(.vertical, 20)
                            .padding(.leading, 30)
                        Text("Email").font(.title3)
                        Spacer()
                        Text(verbatim: "allenkuo0818@gmail.com")
                            .foregroundColor(.blue)
                            .padding(.trailing, 30)
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
                    .frame(height: 100, alignment: .center)
                    .padding(.top, -20)
                }
                .glassEffect()
                
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill").font(.title2)
                            .padding(.vertical, 20)
                            .padding(.leading, 30)
                        Text("Version").font(.title3)
                        Spacer()
                        Text(appVersion)
                            .padding(.trailing, 30)
                    }
                }
                .glassEffect()
                
                Spacer()
            }
            .padding(20)
        }
        .overlay(
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .glassEffect()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 40)
                }
            }
            .allowsHitTesting(false)
        )
    }
}
#Preview {
    AboutThisAPP()
}
