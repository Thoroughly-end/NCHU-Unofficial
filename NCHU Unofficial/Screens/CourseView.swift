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
    @State var selectedHomework: Homework? = nil
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            Color(backgroundColor).ignoresSafeArea()
            VStack(spacing: 20) {
                headerSection
                announcementsSection
                homeworkSection
                footerSection
                Spacer()
            }
            .padding(.horizontal, 30)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .sheet(item: $selectedAnnouncement) { announcement in
            AnnouncementDetailView(announcement: announcement, isLoading: $isLoading)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedHomework) { homework in
            HomeworkDetailView(homework: homework, isLoading: $isLoading)
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
                            isLoading = true
                            fetchAnnouncementDetail()
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
                            .frame(maxWidth: .infinity, maxHeight: 80, alignment: .leading)
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
        .frame(height: 240, alignment: .init(horizontal: .leading, vertical: .top))
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
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView(.vertical) {
                        ForEach(Array(course.homeworks.enumerated()), id: \.element.id) { index, homework in
                            Button {
                                selectedHomework = homework
                                isLoading = true
                                fetchHomeworkDetail()
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(homework.name)
                                        .font(.headline)
                                        .foregroundStyle(homework.isCompleted ? Color.green : Color.primary)
                                        .lineLimit(1)
                                    if let dueDate = homework.dueDate {
                                        Text("Deadline: \(dueDate, format: .dateTime.month().day().hour().minute())")
                                            .font(.caption)
                                            .foregroundStyle(Calendar.current.isDateInToday(dueDate) ? .red : .secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: 80, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
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
        .frame(height: 240, alignment: .init(horizontal: .leading, vertical: .top))
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
    
    private func fetchAnnouncementDetail() {
        guard isLoading else { return }
        
        if let announcement = selectedAnnouncement {
            guard announcement.content == nil else {
                isLoading = false
                return
            }
            Task {
                await ILearningScraper.shared.fetchAnnouncementContent(for: announcement)
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func fetchHomeworkDetail() {
        guard isLoading else { return }
        
        if let homework = selectedHomework {
            if homework.explanation != nil || homework.proportion != nil {
                isLoading = false
                return
            } else {
                Task {
                    await ILearningScraper.shared.fetchHomeworkDetail(homework: homework)
                    await MainActor.run {
                        isLoading = false
                    }
                }
            }
        }
    }
}

struct AnnouncementDetailView: View {
    @ObservedObject var announcement: AnnouncementData
    @State private var downloadingAttachmentID: UUID? = nil
    @Binding var isLoading: Bool
    
    var body: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(1.5)
        } else {
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
                                            VStack {
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
                                                .padding(4)
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
                .ignoresSafeArea(.all, edges: .bottom)
            }
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
            
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            topVC.present(activityVC, animated: true)
        }
    }
}

struct HomeworkDetailView: View {
    @ObservedObject var homework: Homework
    @Binding var isLoading: Bool
    
    var body: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(1.5)
        } else {
            NavigationStack {
                VStack(spacing: 4) {
                    ScrollView(.vertical) {
                        VStack {
                            Text(homework.explanation ?? "No details available")
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Group {
                        if let proportion = homework.proportion {
                            Text("Weight：\(proportion)")
                                .font(.subheadline)
                        }
                        
                        if let score = homework.score {
                            Text("Score：\(score)")
                                .font(.subheadline)
                        } else {
                            Text("Score：Not graded yet")
                                .font(.subheadline)
                        }
                        
                        if let startDate = homework.startDate {
                            Text("Start Date: \(startDate, format: .dateTime.month().day().hour().minute())")
                                .font(.subheadline)
                        }
                        
                        if let dueDate = homework.dueDate {
                            Text("Deadline: \(dueDate, format: .dateTime.month().day().hour().minute())")
                                .font(.subheadline)
                                .foregroundStyle(Calendar.current.isDateInToday(dueDate) ? .red : .primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if homework.isCompleted {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                            
                            Text("Handed in")
                                .font(.title2.bold())
                            Spacer()
                        }
                        .padding(.top, 10)
                    } else {
                        HStack {
                            Image(systemName: "x.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                            Text("Not handed in")
                                .font(.title2.bold())
                            Spacer()
                        }
                        .padding(.top, 10)
                    }
                }
                .navigationTitle(homework.name)
                .navigationBarTitleDisplayMode(.inline)
                .padding(20)
                .ignoresSafeArea(.all, edges: .bottom)
            }
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
    
    let hw1 = Homework(id: 1, url: "https://example.com", name: "Math Assignment 1", isCompleted: true, score: 95, courseID: 123)
    hw1.explanation = "Please complete exercises 1 to 10 on page 42. Show all your work for full credit."
    hw1.proportion = "10%"
    hw1.startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())
    hw1.dueDate = Date() // Today
    course.addHomework(hw1)
    
    let hw2 = Homework(id: 2, url: "https://example.com", name: "Final Project Draft", isCompleted: false, score: nil, courseID: 123)
    hw2.explanation = "Submit the first draft of your final project. Must include at least 3 references and a clear introduction."
    hw2.proportion = "30%"
    hw2.startDate = Date()
    hw2.dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) // Future
    course.addHomework(hw2)
    
    return CourseView(course: course)
}
