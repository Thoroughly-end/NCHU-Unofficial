//
//  Card.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/3.
//

import SwiftUI

struct Card: View {
    let period: Period
    @State private var gradientColors: [Color] = [.blue, .purple]
    
    var height: CGFloat {
        let duration: Int = period.range.upperBound - period.range.lowerBound + 1
        return CGFloat(duration * 150 + 10 * (duration - 1))
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if let name = period.info.name {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            if let location = period.info.location {
                Text(location)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(8)
        .frame(width: 70, height: height)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.5)) {
                generateNewGradient()
            }
        }
        .onAppear {
            generateNewGradient()
        }
    }
    
    private func generateNewGradient() {
        let num = Int.random(in: 2...4)
        var newColors: [Color] = []
        
        for _ in 0..<num {
            newColors.append(ramdomColor())
        }

        self.gradientColors = newColors
    }
    
    private func ramdomColor() -> Color {
        return Color(
            hue: Double.random(in: 0...1),
            saturation: Double.random(in: 0.5...0.7),
            brightness: Double.random(in: 0.8...0.9)
        )
    }
}

struct DayCard: View {
    @State var cardBackgroundColor = UIColor(named: "ScheduleDayCardBackgroundColor") ?? UIColor.systemBackground
    
    let day: Int
    
    var body: some View {
        let backgroundColr = day == 0 ? UIColor(.clear) : cardBackgroundColor
        VStack {
            Group {
                if day == 1 {
                    Text("Mon")
                } else if day == 2 {
                    Text("Tue")
                } else if day == 3 {
                    Text("Wed")
                } else if day == 4 {
                    Text("Thu")
                } else if day == 5 {
                    Text("Fri")
                } else if day == 6 {
                    Text("Sat")
                } else if day == 7{
                    Text("Sun")
                } else {
                    Text("   ")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .foregroundStyle(.primary)
            .font(.system(size: 15))
            .multilineTextAlignment(.center)
        }
        .frame(width: day == 0 ? 40 : 70, height: 40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(backgroundColr))
        )
    }
}

struct TimeCard: View {
    @State var cardBackgroundColor = UIColor(named: "ScheduleTimeCardBackgroundColor") ?? UIColor.systemBackground
    
    let time: Int
    
    var body: some View {
        VStack {
            Group {
                if time == 1 {
                    Text("08:10")
                    Text("     |")
                    Text("09:00")
                } else if time == 2 {
                    Text("09:10")
                    Text("     |")
                    Text("10:00")
                } else if time == 3 {
                    Text("10:10")
                    Text("     |")
                    Text("11:00")
                } else if time == 4 {
                    Text("11:10")
                    Text("     |")
                    Text("12:00")
                } else if time == 5 {
                    Text("13:10")
                    Text("     |")
                    Text("14:00")
                } else if time == 6 {
                    Text("14:10")
                    Text("     |")
                    Text("15:00")
                } else if time == 7 {
                    Text("15:10")
                    Text("     |")
                    Text("16:00")
                } else if time == 8 {
                    Text("16:10")
                    Text("     |")
                    Text("17:00")
                } else if time == 9 {
                    Text("17:10")
                    Text("     |")
                    Text("18:00")
                } else if time == 10 {
                    Text("18:20")
                    Text("     |")
                    Text("19:10")
                } else if time == 11{
                    Text("19:15")
                    Text("     |")
                    Text("20:05")
                } else if time == 12 {
                    Text("20:10")
                    Text("     |")
                    Text("21:00")
                } else if time == 13 {
                    Text("21:05")
                    Text("     |")
                    Text("21:55")
                }
             }
            .multilineTextAlignment(.center)
            .font(.system(size: 13))
            .foregroundStyle(Color.primary)
        }
        .frame(width: 40, height: 150)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(cardBackgroundColor))
        )
    }
}


#Preview {
    Schedule()
        .environmentObject(DataManager())
}
