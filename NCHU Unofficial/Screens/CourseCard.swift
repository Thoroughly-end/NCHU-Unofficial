//
//  CourseCard.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/3/8.
//

import SwiftUI

struct CourseCard: View {
    @ObservedObject var course: CourseData
    @State private var isLoading: Bool = false
    @EnvironmentObject var dataManager: DataManager
    @State private var showHomeworkSheet: Bool = false
    
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
                        .frame(width: 170, alignment: .leading)
                    
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            }
            .glassEffect(.regular.interactive())
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showHomeworkSheet = true
                    fetchData()
                }
                print("Toggle")
            }
            
            
        }
        .sheet(isPresented: $showHomeworkSheet) {
            HomeworkListView(course: course, isLoading: isLoading)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func fetchData() {
        guard isLoading else { return }
        isLoading = true
        
        Task {
            await ILearningScraper.shared.fetchHomeworkList(course: course)
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
