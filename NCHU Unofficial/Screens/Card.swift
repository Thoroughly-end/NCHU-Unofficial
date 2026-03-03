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
        // 不需要 ZStack 鋪底色了！直接讓 VStack 加上玻璃效果即可
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                let name = course.name == nil ? "" : "\(course.name!) "
                let teacher = course.teacher == nil ? "" : "\(course.teacher!) "
                let location = course.location == nil ? "" : "\(course.location!) "
                
                Group {
                    Text(name)
                        .font(.system(size: 15))
                    
                    Text(teacher)
                        .font(.system(size: 10))
                    
                    Text(location)
                        .font(.system(size: 10))
                }
                // 使用 .primary，系統會自動處理：亮色模式=黑字，深色模式=白字
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 15)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // 讓玻璃效果直接覆蓋在內容上，透出母視圖的背景
            .glassEffect()
        }
        .frame(maxWidth: 60, maxHeight: 200)
    }
}

struct DayCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    let day: Int
    
    var body: some View {
        @State var backgroundColor: Color = colorScheme  == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
        @State var textColor: Color = colorScheme == .dark ? Color.white : Color.black
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
                .multilineTextAlignment(.trailing)
                
                
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect()
        }
        .frame(width: 60, height: 60)
    }
}

struct TimeCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    let time: Int
    
    var body: some View {
        @State var backgroundColor: Color = colorScheme  == .dark ? Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12, opacity: 1) : Color.white
        @State var textColor: Color = colorScheme == .dark ? Color.white : Color.black
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
        .frame(maxWidth: 60, maxHeight: 200)
    }
}


#Preview {
    Schedule()
}
