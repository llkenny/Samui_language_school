//
//  LearningProgressRecords.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 02.05.2026.
//

import Foundation
import SwiftData

@Model
final class LearningProgressState {
    static let defaultStorageKey = "default"

    @Attribute(.unique) var storageKey: String
    var currentLessonID: String?
    var currentTheorySectionID: String?
    var currentPracticeTaskID: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        storageKey: String = LearningProgressState.defaultStorageKey,
        currentLessonID: String? = nil,
        currentTheorySectionID: String? = nil,
        currentPracticeTaskID: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.storageKey = storageKey
        self.currentLessonID = currentLessonID
        self.currentTheorySectionID = currentTheorySectionID
        self.currentPracticeTaskID = currentPracticeTaskID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class CompletedTheorySectionRecord {
    @Attribute(.unique) var key: String
    var lessonID: String
    var sectionID: String
    var completedAt: Date

    init(
        lessonID: String,
        sectionID: String,
        completedAt: Date = Date()
    ) {
        self.key = CompletedTheorySectionRecord.key(lessonID: lessonID, sectionID: sectionID)
        self.lessonID = lessonID
        self.sectionID = sectionID
        self.completedAt = completedAt
    }

    static func key(lessonID: String, sectionID: String) -> String {
        "\(lessonID)#\(sectionID)"
    }
}

@Model
final class PracticeTaskProgressRecord {
    @Attribute(.unique) var key: String
    var lessonID: String
    var taskID: String
    var currentItemIndex: Int
    var isComplete: Bool
    var latestCompletedCount: Int
    var latestGradableCount: Int
    var latestCorrectCount: Int
    var updatedAt: Date
    var completedAt: Date?

    init(
        lessonID: String,
        taskID: String,
        currentItemIndex: Int = 0,
        isComplete: Bool = false,
        latestCompletedCount: Int = 0,
        latestGradableCount: Int = 0,
        latestCorrectCount: Int = 0,
        updatedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.key = PracticeTaskProgressRecord.key(lessonID: lessonID, taskID: taskID)
        self.lessonID = lessonID
        self.taskID = taskID
        self.currentItemIndex = currentItemIndex
        self.isComplete = isComplete
        self.latestCompletedCount = latestCompletedCount
        self.latestGradableCount = latestGradableCount
        self.latestCorrectCount = latestCorrectCount
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    static func key(lessonID: String, taskID: String) -> String {
        "\(lessonID)#\(taskID)"
    }
}

@Model
final class PracticeItemProgressRecord {
    @Attribute(.unique) var key: String
    var lessonID: String
    var taskID: String
    var itemID: String
    var response: String?
    var evaluationStateRawValue: String?
    var expectedAnswer: String?
    var explanation: String?
    var errorType: String?
    var notes: String?
    var sampleAnswersJSON: String?
    var updatedAt: Date

    init(
        lessonID: String,
        taskID: String,
        itemID: String,
        response: String? = nil,
        evaluation: PracticeEvaluation? = nil,
        updatedAt: Date = Date()
    ) {
        self.key = PracticeItemProgressRecord.key(lessonID: lessonID, taskID: taskID, itemID: itemID)
        self.lessonID = lessonID
        self.taskID = taskID
        self.itemID = itemID
        self.response = response
        self.evaluationStateRawValue = evaluation?.state.rawValue
        self.expectedAnswer = evaluation?.expectedAnswer
        self.explanation = evaluation?.explanation
        self.errorType = evaluation?.errorType
        self.notes = evaluation?.notes
        self.sampleAnswersJSON = Self.encodeSampleAnswers(evaluation?.sampleAnswers ?? [])
        self.updatedAt = updatedAt
    }

    var evaluation: PracticeEvaluation? {
        guard let evaluationStateRawValue,
              let state = PracticeEvaluationState(rawValue: evaluationStateRawValue) else {
            return nil
        }

        return PracticeEvaluation(
            state: state,
            expectedAnswer: expectedAnswer,
            explanation: explanation,
            errorType: errorType,
            notes: notes,
            sampleAnswers: Self.decodeSampleAnswers(sampleAnswersJSON)
        )
    }

    func update(response: String?, evaluation: PracticeEvaluation?, updatedAt: Date = Date()) {
        self.response = response
        self.evaluationStateRawValue = evaluation?.state.rawValue
        self.expectedAnswer = evaluation?.expectedAnswer
        self.explanation = evaluation?.explanation
        self.errorType = evaluation?.errorType
        self.notes = evaluation?.notes
        self.sampleAnswersJSON = Self.encodeSampleAnswers(evaluation?.sampleAnswers ?? [])
        self.updatedAt = updatedAt
    }

    static func key(lessonID: String, taskID: String, itemID: String) -> String {
        "\(lessonID)#\(taskID)#\(itemID)"
    }

    private static func encodeSampleAnswers(_ sampleAnswers: [String]) -> String? {
        guard !sampleAnswers.isEmpty,
              let data = try? JSONEncoder().encode(sampleAnswers) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private static func decodeSampleAnswers(_ json: String?) -> [String] {
        guard let json,
              let data = json.data(using: .utf8),
              let sampleAnswers = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }

        return sampleAnswers
    }
}
