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
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))))

                
            }
        }
    }
    
    private func fetchData() {
        guard isLoading else { return }
        isLoading = true
        
        Task {
            await ILearningAnnouncementsContentScraper.shared.fetchAnnouncementContent(for: course)
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct AnnouncementRowView: View {
    @ObservedObject var announcement: AnnouncementData
    @State private var downloadingAttachmentID: UUID? = nil
    
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
                                Button {
                                    downloadAndShare(attachment: attachment)
                                } label: {
                                    HStack {
                                        if downloadingAttachmentID == attachment.id {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .frame(width: 20, height: 20)
                                        } else {
                                            Image(systemName: "doc.text")
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Text(attachment.name)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .underline()
                                            .lineLimit(1)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .glassEffect(.regular.interactive())
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
    
    func downloadAndShare(attachment: Attachment) {
        guard downloadingAttachmentID == nil else { return }
        downloadingAttachmentID = attachment.id
        
        Task {
            if let localFileURL = await ILearningDownloadAttachment.shared.download(for: attachment) {
                
                await MainActor.run {
                    presentShareSheet(url: localFileURL)
                    downloadingAttachmentID = nil
                }
                
            } else {
                await MainActor.run {
                    downloadingAttachmentID = nil
                    print("Fail to download attachment")
                }
            }
        }
    }

    func presentShareSheet(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct RecentAnnouncementCard: View {
    @ObservedObject var announcement: AnnouncementData
    @EnvironmentObject var dataManager: DataManager
    @State var isExpanded: Bool = false
    @State private var isLoading: Bool = false
    @State private var downloadingAttachmentID: UUID? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Group {
                    if let courseName = dataManager.courses.first(where: { $0.id == announcement.courseID })?.name {
                        Text(courseName)
                            .font(.title3)
                            .foregroundColor(.blue)
                            .bold()
                    }
                    
                    Text(announcement.title)
                        .font(.headline)
                    
                    if let date = announcement.date {
                        Text(date, format: .dateTime.month().day())
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect()
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                print("Toggle")
                if isExpanded && announcement.content == nil {
                    print("Fetch data")
                    isLoading = true
                    fetchData()
                }
            }
            
            if isExpanded {
                HStack {
                    Spacer()
                    if let content = announcement.content {
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack {
                                Text(content)
                                    .font(.body)
                                if !announcement.attachments.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Attachments：")
                                            .font(.footnote)
                                            .foregroundColor(Color.primary)
                                        
                                        ForEach(announcement.attachments) { attachment in
                                            HStack {
                                                Button {
                                                    downloadAndShare(attachment: attachment)
                                                } label: {
                                                    HStack {
                                                        if downloadingAttachmentID == attachment.id {
                                                            ProgressView()
                                                                .scaleEffect(0.8)
                                                                .frame(width: 20, height: 20)
                                                        } else {
                                                            Image(systemName: "doc.text")
                                                                .foregroundColor(.gray)
                                                        }
                                                        
                                                        Text(attachment.name)
                                                            .font(.caption)
                                                            .foregroundColor(.blue)
                                                            .underline()
                                                            .lineLimit(1)
                                                    }
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal, 8)
                                                    .glassEffect(.regular.interactive())
                                                }
                                                Spacer()
                                            }
                                            
                                        }
                                    }
                                    .padding(.top, 6)
                                }
                            }
                            
                        }
                        .padding(60)
                        .frame(maxHeight: 300)
                        .glassEffect()
                    } else {
                        EmptyView()
                    }
                }
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))))
            }
        }
        
    }
    
    private func fetchData() {
        guard isLoading else { return }
        isLoading = true
        
        Task {
            await ILearningAnnouncementContentScraper.shared.fetchAnnouncementContent(for: announcement)
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func downloadAndShare(attachment: Attachment) {
        guard downloadingAttachmentID == nil else { return }
        downloadingAttachmentID = attachment.id
        
        Task {
            if let localFileURL = await ILearningDownloadAttachment.shared.download(for: attachment) {
                
                await MainActor.run {
                    presentShareSheet(url: localFileURL)
                    downloadingAttachmentID = nil
                }
                
            } else {
                await MainActor.run {
                    downloadingAttachmentID = nil
                    print("Fail to download attachment")
                }
            }
        }
    }

    func presentShareSheet(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
}


#Preview {
    AnnouncementsCard(course: CourseData(id: 123, name: "C++++++++++++++++"))
}
