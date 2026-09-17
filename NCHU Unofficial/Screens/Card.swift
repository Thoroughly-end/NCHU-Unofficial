//
//  Card.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/3.
//

import SwiftUI

struct Card: View {
    let period: Period
    var width: CGFloat = 70
    @State private var bgColor: Color = .blue

    var height: CGFloat {
        let duration: Int = period.range.upperBound - period.range.lowerBound + 1
        return CGFloat(duration * 100 + 10 * (duration - 1))
    }

    var body: some View {
        VStack(spacing: 4) {
            if let name = period.info.name {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    //.lineLimit(3)
            }

            if let location = period.info.location {
                Text(location)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(8)
        .frame(width: width, height: height)
        .background(bgColor.opacity(0.6))
        .cornerRadius(12)
        .onAppear {
            bgColor = ramdomColor()
        }
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
    var width: CGFloat = 70

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
        .frame(width: day == 0 ? 40 : width, height: 40)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(backgroundColr))
        )
    }
}

struct TimeCard: View {
    @State var cardBackgroundColor = UIColor(named: "ScheduleTimeCardBackgroundColor") ?? UIColor.systemBackground
    
    static let timePeriod = ScheduleLayout.generatePeriods()
    let time: Int
    
    var body: some View {
        VStack {
            Group {
                Text(String(format: "%02d:%02d", TimeCard.timePeriod[time - 1].start.hour, TimeCard.timePeriod[time - 1].start.minute))
                Text("|")
                Text(String(format: "%02d:%02d", TimeCard.timePeriod[time - 1].end.hour, TimeCard.timePeriod[time - 1].end.minute))
             }
            .multilineTextAlignment(.center)
            .font(.system(size: 13))
            .foregroundStyle(Color.primary)
        }
        .frame(width: 40, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(cardBackgroundColor))
        )
    }
}


#Preview {
    Schedule()
        .environmentObject(DataManager())
}
