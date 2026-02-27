//
//  aboutThisAPP.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI

struct AboutThisAPP: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        @State var backgroundColor: Color = colorScheme  == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
        @State var textColor: Color = colorScheme == .dark ? Color.white : Color.black
        
        ZStack {
            Color(backgroundColor).ignoresSafeArea()
            VStack(spacing: 40) {
                
                VStack{
                    Image(systemName: "graduationcap.circle.fill").font(.title)
                    Text("NCHU Unofficial")
                        .font(.title)
                        .padding()
                        .padding(.vertical, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                .glassEffect()
                
            
                
                VStack {
                    HStack {
                        Image(systemName: "person.fill").font(.title2)
                            .padding(.vertical, 20)
                            .padding(.leading, 20)
                        Text("Developer").font(.title2)
                        Spacer()
                        Text("Chia-Chun Kuo")
                            .padding(.trailing, 20)
                    }
                    .frame(height: 100, alignment: .center)
                    .padding(.bottom, -20)
                    
                    HStack {
                        Image(systemName: "envelope.fill").font(.title2)
                            .padding(.vertical, 20)
                            .padding(.leading, 20)
                        Text("Email").font(.title2)
                        Spacer()
                        Text("allenkuo0818@gmail.com")
                            .padding(.trailing, 20)
                    }
                    .frame(height: 100, alignment: .center)
                    .padding(.top, -20)
                }
                .glassEffect()
                .containerShape(.rect)
                
                
                
                Spacer()
            }
            .padding(20)
        }
        
    }
}
#Preview {
    AboutThisAPP()
}
