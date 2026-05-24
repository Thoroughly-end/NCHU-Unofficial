//
//  HomeworkData.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/5/22.
//

import Combine
import Foundation

class Homework: Identifiable, ObservableObject {
    let id: Int
    let url: String
    let name: String
    let courseID: Int
    @Published var startDate: Date?
    @Published var dueDate: Date?
    let isCompleted: Bool
    let score: Int?
    @Published var explanation: String?
    @Published var proportion: String?
    
    
    init(id: Int, url: String, name: String, isCompleted: Bool, score: Int?, courseID: Int) {
        self.id = id
        self.url = url
        self.name = name
        self.startDate = nil
        self.dueDate = nil
        self.isCompleted = isCompleted
        self.score = score
        self.explanation = nil
        self.proportion = nil
        self.courseID = courseID
    }
    
    func setExplanationAndPropotion(explanation: String?, proportion: String?) {
        DispatchQueue.main.async {
            self.explanation = explanation
            self.proportion = proportion
        }
    }
    
    func setStartAndDueDate(startDate: Date, dueDate: Date) {
        DispatchQueue.main.async {
            self.startDate = startDate
            self.dueDate = dueDate
        }
    }
}
