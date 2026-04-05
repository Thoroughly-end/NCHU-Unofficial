//
//  CourseView.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/4/5.
//

import SwiftUI

struct CourseView: View {
    @State var backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
    let elementBgColor = Color("ElementBackgroundColor")
    var course: CourseData
    @State var selectedAnnouncement: AnnouncementData? = nil
    
    var body: some View {
        ZStack {
            Color(backgroundColor).ignoresSafeArea()
            VStack(spacing: 20) {
                headerSection
                    .padding(.bottom, 20)
                announcementsSection
                homeworkSection
                footerSection
                Spacer()
            }
            .padding(30)
        }
        .sheet(item: $selectedAnnouncement) { announcement in
            AnnouncementDetailView(announcement: announcement)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    var headerSection: some View {
        HStack {
            Text(course.name)
                .font(.largeTitle.bold())
                .lineLimit(1)
            Spacer()
        }
    }
    
    var announcementsSection: some View {
        VStack {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "megaphone.fill")
                        .foregroundStyle(.primary)
                        .font(.title2)
                    Text("Announcements")
                        .font(.title2.bold())
                    Spacer()
                }
                ScrollView(.vertical) {
                    ForEach(Array(course.announcements.enumerated()), id: \.element.id) { index, announcement in
                        Button{
                            selectedAnnouncement = announcement
                        } label: {
                            VStack(alignment: .leading) {
                                Text(announcement.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                if let date = announcement.date {
                                    Text(date, format: .dateTime.month().day().hour().minute())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                            }
                            .frame(maxWidth:.infinity, maxHeight: 80, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if index < course.announcements.count - 1 {
                            Divider().padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding()
            
        }
        .background(
            RoundedRectangle(cornerRadius: 30)
            .fill(elementBgColor)
        )
        .frame(height: 250, alignment: .init(horizontal: .leading, vertical: .top))
    }
    
    var homeworkSection: some View {
        VStack {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.primary)
                        .font(.title2)
                    Text("Homework")
                        .font(.title2.bold())
                    Spacer()
                }
                if course.homeworks.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("There is no homework")
                            .font(.headline)
                    }
                } else {
                    ScrollView(.vertical) {
                        ForEach(Array(course.homeworks.enumerated()), id: \.element.id) { index, homework in
                            VStack(alignment: .leading) {
                                Text(homework.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                if let dueDate = homework.dueDate {
                                    Text("Deadline: \(dueDate, format: .dateTime.month().day().hour().minute())")
                                        .font(.caption)
                                        .foregroundStyle(Calendar.current.isDateInToday(dueDate) ? .red : .secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 80, alignment: .leading)
                            
                            if index < course.homeworks.count - 1 {
                                Divider().padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 30)
            .fill(elementBgColor)
        )
        .frame(height: 250, alignment: .init(horizontal: .leading, vertical: .top))
    }
    
    var footerSection: some View {
        HStack {
            Spacer()
            Text("If the information is differnt from iLearning, please refer to the information on iLearning.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(width: 300)
        }
    }
}

struct AnnouncementDetailView: View {
    @ObservedObject var announcement: AnnouncementData
    @State private var downloadingAttachmentID: UUID? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 20) {
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
                                    .padding(.bottom, 4)
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
                                        .glassEffect(.regular.interactive())
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle(announcement.title)
            .navigationBarTitleDisplayMode(.inline)
            .padding(20)
        }
    }
    
    func downloadAndShare(attachment: Attachment) {
        guard downloadingAttachmentID == nil else { return }
        downloadingAttachmentID = attachment.id
        
        Task {
            if let localFileURL = await ILearningScraper.shared.download(for: attachment) {
                
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
    let course = CourseData(id: 123, name: "Sample Course")
    
    let a1 = AnnouncementData(courseID: 1, title: "Sample Announcement1", url: "https://example.com/1", date: Date())
    a1.content = "This is a sample announcement 1\nWith multiline text."
    course.addAnnouncement(a1)
    
    let a2 = AnnouncementData(courseID: 2, title: "Sample Announcement2", url: "https://example.com/2", date: Date())
    a2.content = "This is the content for announcement 2!\nIt fully displays now."
    course.addAnnouncement(a2)
    
    let a3 = AnnouncementData(courseID: 3, title: "Sample Announcement3", url: "https://example.com/3", date: Date())
    a3.content = "Another test content."
    course.addAnnouncement(a3)
    
    let hw1 = Homework(id: 1, url: "https://example.com", name: "Sample Homework 1", isCompleted: false, score: nil, courseID: 123)
    hw1.dueDate = Date() // Today
    course.addHomework(hw1)
    
    let hw2 = Homework(id: 2, url: "https://example.com", name: "Sample Homework 2", isCompleted: false, score: nil, courseID: 123)
    hw2.dueDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) // Future
    course.addHomework(hw2)
    
    return CourseView(course: course)
}
