//
//  Card.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/3.
//

import SwiftUI

struct Card: View {
    let course: ScheduleData
    
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                let name = course.name == nil ? "" : "\(course.name!) "
                let location = course.location == nil ? "" : "\(course.location!) "
                
                Group {
                    Text(name)
                        .font(.system(size: 15))
                    
                    Text(location)
                        .font(.system(size: 10))
                }
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect()
        }
        .frame(maxWidth: 70, maxHeight: 200)
    }
}

struct DayCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    let day: Int
    
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
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
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect()
        }
        .frame(width: 70, height: 70)
    }
}

struct TimeCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    let time: Int
    
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
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
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect()
        }
        .frame(maxWidth: 70, maxHeight: 200)
    }
}


#Preview {
    Schedule()
        .environmentObject(DataManager())
}
