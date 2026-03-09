//
//  HomeworkView.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/8.
//

import SwiftUI

struct HomeworkListView: View {
    @ObservedObject var course: CourseData
    var isLoading: Bool
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Synchronizing...")
                            .foregroundColor(.gray)
                    }
                }
                else if course.homeworks.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("There is no homework")
                            .font(.headline)
                    }
                }
                else {
                    List(course.homeworks) { homework in
                        HomeworkRowView(homework: homework)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(course.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HomeworkRowView: View {
    @ObservedObject var homework: Homework
    
    @State private var isExpanded: Bool = false
    @State private var isLoadingDetails: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(homework.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("Deadline:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let dueDate = homework.dueDate {
                            Text(dueDate, format: .dateTime.month().day().hour().minute())
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                    }
                    
                    if homework.isCompleted {
                        Label("Handed in", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
                if isExpanded && homework.explanation == nil && !isLoadingDetails {
                    fetchDetails()
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().padding(.vertical, 4)
                    
                    if isLoadingDetails {
                        HStack {
                            Spacer()
                            ProgressView("Loading details...")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    else {
                        if let proportion = homework.proportion {
                            Text("Weight：\(proportion)")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.blue)
                        }
                        
                        if let explanation = homework.explanation {
                            Text(explanation)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("No explanation provided.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.vertical, 6)
    }
    
    private func fetchDetails() {
        isLoadingDetails = true
        Task {
            await ILearningScraper.shared.fetchHomeworkDetail(homework: homework)
            
            await MainActor.run {
                isLoadingDetails = false
            }
        }
    }
}

struct RecentHomeworkCard: View {
    @ObservedObject var homework: Homework
    @EnvironmentObject var dataManager: DataManager
    
    @State var isExpanded: Bool = false
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack {
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        
                        if let courseName = dataManager.courses.first(where: { $0.id == homework.courseID })?.name {
                            Text(courseName)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .bold()
                        }
                        
                        Text(homework.name)
                            .font(.headline)
                        
                        if let dueDate = homework.dueDate {
                            Text("Deadline：\(dueDate, format: .dateTime.month().day().hour().minute())")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                    }
                    
                    Spacer()
                }
                .padding(30)
            }
            .contentShape(Rectangle())
            .glassEffect(.regular.interactive())
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                
                if isExpanded && homework.explanation == nil && !isLoading {
                    fetchDetails()
                }
            }
            HStack {
                Spacer()
                if isExpanded {
                    ScrollView(.vertical, showsIndicators: true) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                if isLoading {
                                    HStack {
                                        Spacer()
                                        ProgressView("Loading...")
                                            .font(.caption)
                                        Spacer()
                                    }
                                } else {
                                    if let proportion = homework.proportion {
                                        Text("Weight：\(proportion)")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                            .bold()
                                    }
                                    
                                    if let explanation = homework.explanation {
                                        Text(explanation)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    } else {
                                        Text("No explanation provided.")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(60)
                            Spacer()
                        }
                        .glassEffect()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .frame(maxHeight: 300)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                }
            }
            
        }
    }
    
    private func fetchDetails() {
        isLoading = true
        Task {
            await ILearningScraper.shared.fetchHomeworkDetail(homework: homework)
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
