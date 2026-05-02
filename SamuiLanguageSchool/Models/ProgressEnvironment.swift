//
//  ProgressEnvironment.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 01.05.2026.
//

import Combine
import Foundation
import SwiftData

@MainActor
final class ProgressEnvironment: ObservableObject {
    @Published var currentLessonID: String?
    @Published var currentTheorySectionID: String?
    @Published var currentPracticeTaskID: String?
    @Published private var completedTheorySectionKeys = Set<String>()
    @Published private var completedPracticeTaskKeys = Set<String>()

    private var modelContext: ModelContext?
    private var state: LearningProgressState?

    init(
        currentLessonID: String? = nil,
        currentTheorySectionID: String? = nil,
        currentPracticeTaskID: String? = nil
    ) {
        self.currentLessonID = currentLessonID
        self.currentTheorySectionID = currentTheorySectionID
        self.currentPracticeTaskID = currentPracticeTaskID
    }

    func configure(modelContext: ModelContext, lessons: [LessonContentModel] = []) {
        self.modelContext = modelContext
        state = fetchProgressState() ?? createProgressState()
        loadPublishedState()
        reloadCompletionState()

        if !lessons.isEmpty {
            validateCurrentStep(in: lessons)
        }
    }

    func actionTitle(for lesson: LessonContentModel) -> String {
        hasProgress(in: lesson) ? "Continue" : "Start"
    }

    func startOrContinueStep(for lesson: LessonContentModel) -> LearningStep? {
        if currentLessonID != lesson.id {
            setCurrentStep(lessonID: lesson.id, theorySectionID: nil, practiceTaskID: nil)
        }

        let taskIDs = Set(lesson.practiceTasks.map(\.id))
        if let taskID = currentPracticeTaskID, taskIDs.contains(taskID) {
            return .practice(lessonID: lesson.id, taskID: taskID)
        }

        let sectionIDs = Set(lesson.theorySections.map(\.id))
        if let sectionID = currentTheorySectionID, sectionIDs.contains(sectionID) {
            return .theory(lessonID: lesson.id, sectionID: sectionID)
        }

        guard let firstStep = LearningStepResolver.firstStep(in: lesson) else {
            return nil
        }

        updateProgress(to: firstStep)
        return firstStep
    }

    func updateTheoryProgress(lessonID: String, sectionID: String) {
        setCurrentStep(lessonID: lessonID, theorySectionID: sectionID, practiceTaskID: nil)
    }

    func updatePracticeProgress(lessonID: String, taskID: String?) {
        let theorySectionID = currentLessonID == lessonID ? currentTheorySectionID : nil
        setCurrentStep(lessonID: lessonID, theorySectionID: theorySectionID, practiceTaskID: taskID)
    }

    func updateProgress(to step: LearningStep) {
        switch step {
        case .theory(let lessonID, let sectionID):
            updateTheoryProgress(lessonID: lessonID, sectionID: sectionID)
        case .practice(let lessonID, let taskID):
            updatePracticeProgress(lessonID: lessonID, taskID: taskID)
        }
    }

    private func hasProgress(in lesson: LessonContentModel) -> Bool {
        currentLessonID == lesson.id && (currentTheorySectionID != nil || currentPracticeTaskID != nil)
    }

    func isCurrentStep(_ step: LearningStep) -> Bool {
        switch step {
        case .theory(let lessonID, let sectionID):
            currentLessonID == lessonID &&
            currentTheorySectionID == sectionID &&
            currentPracticeTaskID == nil
        case .practice(let lessonID, let taskID):
            currentLessonID == lessonID && currentPracticeTaskID == taskID
        }
    }

    func isStepCompleted(_ step: LearningStep) -> Bool {
        switch step {
        case .theory(let lessonID, let sectionID):
            completedTheorySectionKeys.contains(
                CompletedTheorySectionRecord.key(lessonID: lessonID, sectionID: sectionID)
            )
        case .practice(let lessonID, let taskID):
            completedPracticeTaskKeys.contains(
                PracticeTaskProgressRecord.key(lessonID: lessonID, taskID: taskID)
            )
        }
    }

    func markTheorySectionCompleted(lessonID: String, sectionID: String) {
        let key = CompletedTheorySectionRecord.key(lessonID: lessonID, sectionID: sectionID)
        guard !completedTheorySectionKeys.contains(key) else {
            return
        }

        completedTheorySectionKeys.insert(key)

        guard let modelContext else {
            return
        }

        let record = CompletedTheorySectionRecord(lessonID: lessonID, sectionID: sectionID)
        modelContext.insert(record)
        save()
    }

    func savePracticeSnapshot(lessonID: String, taskID: String, snapshot: PracticeSessionSnapshot) {
        let now = Date()
        let taskRecord = practiceTaskProgressRecord(lessonID: lessonID, taskID: taskID)
        taskRecord.currentItemIndex = max(snapshot.currentItemIndex, 0)
        taskRecord.isComplete = snapshot.isComplete
        taskRecord.updatedAt = now

        if let result = snapshot.result {
            taskRecord.latestCompletedCount = result.completedCount
            taskRecord.latestGradableCount = result.gradableCount
            taskRecord.latestCorrectCount = result.correctCount
            taskRecord.completedAt = now
        }

        for (itemID, response) in snapshot.responses {
            let itemRecord = practiceItemProgressRecord(lessonID: lessonID, taskID: taskID, itemID: itemID)
            itemRecord.update(response: response, evaluation: snapshot.evaluations[itemID], updatedAt: now)
        }

        for (itemID, evaluation) in snapshot.evaluations where snapshot.responses[itemID] == nil {
            let itemRecord = practiceItemProgressRecord(lessonID: lessonID, taskID: taskID, itemID: itemID)
            itemRecord.update(response: nil, evaluation: evaluation, updatedAt: now)
        }

        if snapshot.isComplete {
            completedPracticeTaskKeys.insert(PracticeTaskProgressRecord.key(lessonID: lessonID, taskID: taskID))
        }

        save()
    }

    func practiceSnapshot(lessonID: String, taskID: String, validItemIDs: Set<String>) -> PracticeSessionSnapshot? {
        guard let taskRecord = fetchPracticeTaskProgressRecord(lessonID: lessonID, taskID: taskID) else {
            return nil
        }

        let itemRecords = fetchPracticeItemProgressRecords(lessonID: lessonID, taskID: taskID)
            .filter { validItemIDs.contains($0.itemID) }

        let responses = Dictionary(
            uniqueKeysWithValues: itemRecords.compactMap { record -> (String, String)? in
                guard let response = record.response else {
                    return nil
                }

                return (record.itemID, response)
            }
        )
        let evaluations = Dictionary(
            uniqueKeysWithValues: itemRecords.compactMap { record -> (String, PracticeEvaluation)? in
                guard let evaluation = record.evaluation else {
                    return nil
                }

                return (record.itemID, evaluation)
            }
        )
        let result: PracticeSessionResult?
        if taskRecord.completedAt != nil {
            result = PracticeSessionResult(
                completedCount: taskRecord.latestCompletedCount,
                gradableCount: taskRecord.latestGradableCount,
                correctCount: taskRecord.latestCorrectCount
            )
        } else {
            result = nil
        }

        return PracticeSessionSnapshot(
            currentItemIndex: max(taskRecord.currentItemIndex, 0),
            responses: responses,
            evaluations: evaluations,
            isComplete: taskRecord.isComplete,
            result: result
        )
    }

    func savePracticeResult(lessonID: String, taskID: String, result: PracticeSessionResult) {
        let snapshot = PracticeSessionSnapshot(
            currentItemIndex: 0,
            responses: [:],
            evaluations: [:],
            isComplete: true,
            result: result
        )
        savePracticeSnapshot(lessonID: lessonID, taskID: taskID, snapshot: snapshot)
    }

    private func setCurrentStep(lessonID: String?, theorySectionID: String?, practiceTaskID: String?) {
        currentLessonID = lessonID
        currentTheorySectionID = theorySectionID
        currentPracticeTaskID = practiceTaskID

        guard let state = state ?? fetchProgressState() ?? createProgressState() else {
            return
        }

        state.currentLessonID = lessonID
        state.currentTheorySectionID = theorySectionID
        state.currentPracticeTaskID = practiceTaskID
        state.updatedAt = Date()
        self.state = state
        save()
    }

    private func validateCurrentStep(in lessons: [LessonContentModel]) {
        guard let currentLessonID else {
            return
        }

        guard let lesson = lessons.first(where: { $0.id == currentLessonID }) else {
            setCurrentStep(lessonID: nil, theorySectionID: nil, practiceTaskID: nil)
            return
        }

        let sectionIDs = Set(lesson.theorySections.map(\.id))
        let taskIDs = Set(lesson.practiceTasks.map(\.id))
        let hasValidTheory = currentTheorySectionID.map(sectionIDs.contains) ?? false
        let hasValidPractice = currentPracticeTaskID.map(taskIDs.contains) ?? false

        if currentPracticeTaskID != nil, !hasValidPractice {
            setCurrentStep(lessonID: lesson.id, theorySectionID: nil, practiceTaskID: nil)
        } else if currentPracticeTaskID == nil, currentTheorySectionID != nil, !hasValidTheory {
            setCurrentStep(lessonID: lesson.id, theorySectionID: nil, practiceTaskID: nil)
        }
    }

    private func loadPublishedState() {
        currentLessonID = state?.currentLessonID
        currentTheorySectionID = state?.currentTheorySectionID
        currentPracticeTaskID = state?.currentPracticeTaskID
    }

    private func reloadCompletionState() {
        guard let modelContext else {
            return
        }

        completedTheorySectionKeys = Set((try? modelContext.fetch(FetchDescriptor<CompletedTheorySectionRecord>()))?.map(\.key) ?? [])
        completedPracticeTaskKeys = Set(
            ((try? modelContext.fetch(FetchDescriptor<PracticeTaskProgressRecord>())) ?? [])
                .filter { $0.completedAt != nil || $0.isComplete }
                .map(\.key)
        )
    }

    private func fetchProgressState() -> LearningProgressState? {
        guard let modelContext else {
            return nil
        }

        return (try? modelContext.fetch(FetchDescriptor<LearningProgressState>()))?
            .first { $0.storageKey == LearningProgressState.defaultStorageKey }
    }

    private func createProgressState() -> LearningProgressState? {
        guard let modelContext else {
            return nil
        }

        let state = LearningProgressState()
        modelContext.insert(state)
        save()
        return state
    }

    private func practiceTaskProgressRecord(lessonID: String, taskID: String) -> PracticeTaskProgressRecord {
        if let record = fetchPracticeTaskProgressRecord(lessonID: lessonID, taskID: taskID) {
            return record
        }

        let record = PracticeTaskProgressRecord(lessonID: lessonID, taskID: taskID)
        modelContext?.insert(record)
        return record
    }

    private func fetchPracticeTaskProgressRecord(lessonID: String, taskID: String) -> PracticeTaskProgressRecord? {
        guard let modelContext else {
            return nil
        }

        let key = PracticeTaskProgressRecord.key(lessonID: lessonID, taskID: taskID)
        return (try? modelContext.fetch(FetchDescriptor<PracticeTaskProgressRecord>()))?
            .first { $0.key == key }
    }

    private func practiceItemProgressRecord(lessonID: String, taskID: String, itemID: String) -> PracticeItemProgressRecord {
        if let record = fetchPracticeItemProgressRecord(lessonID: lessonID, taskID: taskID, itemID: itemID) {
            return record
        }

        let record = PracticeItemProgressRecord(lessonID: lessonID, taskID: taskID, itemID: itemID)
        modelContext?.insert(record)
        return record
    }

    private func fetchPracticeItemProgressRecord(lessonID: String, taskID: String, itemID: String) -> PracticeItemProgressRecord? {
        guard let modelContext else {
            return nil
        }

        let key = PracticeItemProgressRecord.key(lessonID: lessonID, taskID: taskID, itemID: itemID)
        return (try? modelContext.fetch(FetchDescriptor<PracticeItemProgressRecord>()))?
            .first { $0.key == key }
    }

    private func fetchPracticeItemProgressRecords(lessonID: String, taskID: String) -> [PracticeItemProgressRecord] {
        guard let modelContext else {
            return []
        }

        return ((try? modelContext.fetch(FetchDescriptor<PracticeItemProgressRecord>())) ?? [])
            .filter { $0.lessonID == lessonID && $0.taskID == taskID }
    }

    private func save() {
        do {
            try modelContext?.save()
        } catch {
            assertionFailure("Could not save learning progress: \(error)")
        }
    }
}

extension LessonContentModel {
    var orderedTheorySections: [TheorySection] {
        theorySections.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return lhs.id < rhs.id
            }

            return lhs.order < rhs.order
        }
    }

    var firstTheorySection: TheorySection? {
        orderedTheorySections.first
    }
}
