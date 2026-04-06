//
//  SwiftUIView.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/4/6.
//

import SwiftUI

struct RecentAnnouncement: View {
    @State var backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
    @State var isLoading: Bool = false
    @EnvironmentObject var dataManager: DataManager
    @State var recentAnnouncements: [AnnouncementData] = []
    
    @State private var selectedAnnouncement: AnnouncementData? = nil
    @State private var isDetailLoading: Bool = false
    let elementBgColor = Color("ElementBackgroundColor")
    
    var body: some View {
        ZStack {
            Color(backgroundColor)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Text("Recent")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                if isLoading {
                    Spacer()
                    ProgressView()
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    if recentAnnouncements.isEmpty {
                        Spacer()
                        Text("No recent announcements")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 15) {
                                ForEach(recentAnnouncements) { announcement in
                                    Button {
                                        selectedAnnouncement = announcement
                                        fetchAnnouncementDetail(for: announcement)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(announcement.title)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                            
                                            HStack {
                                                if let course = dataManager.courses.first(where: { $0.id == announcement.courseID }) {
                                                    Text(course.name)
                                                        .font(.caption)
                                                        .foregroundStyle(.blue)
                                                        .lineLimit(1)
                                                }
                                                Spacer()
                                                if let date = announcement.date {
                                                    Text(date, format: .dateTime.month().day().hour().minute())
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                        .padding(20)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(elementBgColor)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .padding(30)
        }
        .sheet(item: $selectedAnnouncement) { announcement in
            AnnouncementDetailView(announcement: announcement, isLoading: $isDetailLoading)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear() {
            if recentAnnouncements.isEmpty {
                isLoading = true
                loadRecentAnnouncement()
            }
        }
    }
    
    private func loadRecentAnnouncement() {
        guard isLoading == true else {
            isLoading = false
            return
        }
        guard dataManager.courses.isEmpty == false else {
            isLoading = false
            return
        }
        
        recentAnnouncements = CourseData.getRecentAnnouncements(from: dataManager.courses)
            .sorted(by: { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) })
        isLoading = false
    }
    
    private func fetchAnnouncementDetail(for announcement: AnnouncementData) {
        guard announcement.content == nil else { return }
        isDetailLoading = true
        Task {
            await ILearningScraper.shared.fetchAnnouncementContent(for: announcement)
            await MainActor.run {
                isDetailLoading = false
            }
        }
    }
}

#Preview {
    RecentAnnouncement()
        .environmentObject(DataManager())
}
