//
//  CourseCard.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/6.
//

import SwiftUI

struct AnnouncementsCard: View {
    @State var isExpanded: Bool = false
    @ObservedObject var course: CourseData
    @State private var isLoading: Bool = false
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Group {
                    Image(systemName: "books.vertical.circle.fill")
                        .font(.largeTitle)
                        .padding(.leading, 40)
                    Text(course.name)
                        .font(.title)
                        .lineLimit(2)
                        .padding(.leading, 10)
                        .frame(width: 170)
                    
                    Spacer()
                                    
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .padding(.trailing, 40)
                }
                .frame(maxHeight: .infinity)
            }
            .glassEffect(.regular.interactive())
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                print("Toggle")
                if isExpanded && course.announcements.contains(where: { $0.content == nil }) {
                    print("Fetch data")
                    isLoading = true
                    fetchData()
                }
            }
            
            if isExpanded {
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 10) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView("努力爬取公告中...")
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                                    .glassEffect()
                                Spacer()
                            }
                        } else if course.announcements.isEmpty {
                            Text("目前尚無最新公告")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 20)
                                .padding(.leading, 10)
                                .frame(maxWidth: .infinity)
                                .glassEffect()
                        } else {
                            ForEach(course.announcements, id: \.url) { announcement in
                                AnnouncementRowView(announcement: announcement)
                                .frame(maxHeight: 300)
                                .glassEffect()
                            }
                        }
                    }
                    .frame(maxWidth: 350)
                }
                .padding(.top, 10)
                .padding(.trailing, 20)
                
            }
        }
    }
    
    private func fetchData() {
        guard isLoading else { return }
        isLoading = true
        
        Task {
            await ILearningAnnouncementContentScraper.shared.fetchAnnouncementContent(for: course)
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct AnnouncementRowView: View {
    @ObservedObject var announcement: AnnouncementData
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            HStack {
                VStack(alignment: .leading) {
                    Text(announcement.title)
                        .font(.title2)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let content = announcement.content {
                        Text(content)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    } else {
                        VStack {}.frame(height: 10)
                    }
                    if !announcement.attachments.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Attachments：")
                                .font(.footnote)
                                .foregroundColor(Color.primary)
                            
                            ForEach(announcement.attachments) { attachment in
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.gray)
                                    Text(attachment.name)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .underline()
                                }
                            }
                        }
                        .padding(.top, 6)
                    }
                }
                Spacer()
            }
            
        }
        .padding(60)
    }
}



#Preview {
    AnnouncementsCard(course: CourseData(id: 123, name: "C++++++++++++++++"))
}
