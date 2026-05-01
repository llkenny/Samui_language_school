//
//  PracticeSessionSupport.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 01.05.2026.
//

import Foundation

enum PracticeTaskResolver {
    static func selectedTask(
        in lesson: LessonContentModel,
        requestedTaskID: String?
    ) -> LessonContentModel.PracticeTask? {
        if let requestedTaskID,
           let task = lesson.practiceTasks.first(where: { $0.id == requestedTaskID }) {
            return task
        }

        return lesson.practiceTasks.first
    }
}

struct PracticeEvaluation: Equatable {
    let state: PracticeEvaluationState
    let expectedAnswer: String?
    let explanation: String?
    let errorType: String?
    let notes: String?
    let sampleAnswers: [String]

    var isGradable: Bool {
        switch state {
        case .correct, .incorrect:
            return true
        case .reviewed:
            return false
        }
    }

    var isCorrect: Bool {
        state == .correct
    }
}

enum PracticeEvaluationState: Equatable {
    case correct
    case incorrect
    case reviewed
}

enum PracticeAnswerEvaluator {
    static func evaluate(
        response: String,
        for item: LessonContentModel.TaskItem,
        answerKey: LessonContentModel.AnswerKeyTask?
    ) -> PracticeEvaluation {
        if item.type == .sorting {
            return evaluateSorting(response: response, item: item, answerKey: answerKey)
        }

        let entry = answerKey?.entries.first { $0.itemId == item.id }
        guard let entry else {
            return reviewedEvaluation(entry: nil, taskNotes: answerKey?.teacherNotes)
        }

        let candidates = answerCandidates(from: entry)
        guard !candidates.isEmpty else {
            return reviewedEvaluation(entry: entry, taskNotes: answerKey?.teacherNotes)
        }

        let normalizedResponse = normalized(response)
        let isCorrect = candidates.contains { normalized($0) == normalizedResponse }

        return PracticeEvaluation(
            state: isCorrect ? .correct : .incorrect,
            expectedAnswer: expectedAnswerText(from: entry),
            explanation: entry.explanation,
            errorType: entry.errorType,
            notes: entry.notes ?? answerKey?.teacherNotes,
            sampleAnswers: entry.sampleAnswers ?? []
        )
    }

    static func isAutoGradable(
        item: LessonContentModel.TaskItem,
        answerKey: LessonContentModel.AnswerKeyTask?
    ) -> Bool {
        if item.type == .sorting {
            guard let number = item.number?.sortingNumber,
                  let categories = item.categories,
                  let entries = answerKey?.entries,
                  categories.count <= entries.count else {
                return false
            }

            return entries.prefix(categories.count).contains { entry in
                entry.answer?.integerArrayValue?.contains(number) == true
            }
        }

        guard let entry = answerKey?.entries.first(where: { $0.itemId == item.id }) else {
            return false
        }

        return !answerCandidates(from: entry).isEmpty
    }

    static func responseIsPresent(_ response: String?, for item: LessonContentModel.TaskItem) -> Bool {
        switch item.type {
        case .speakingPrompt:
            return true
        default:
            return !(response ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    static func expectedAnswerText(
        from entry: LessonContentModel.AnswerEntry?
    ) -> String? {
        guard let entry else {
            return nil
        }

        if let object = entry.answer?.objectValue {
            let error = object["error"]?.displayText
            let correction = object["correction"]?.displayText

            switch (error, correction) {
            case let (.some(error), .some(correction)):
                return "Error: \(error)\nCorrection: \(correction)"
            case let (nil, .some(correction)):
                return correction
            case let (.some(error), nil):
                return error
            case (nil, nil):
                break
            }
        }

        if let acceptedAnswers = entry.acceptedAnswers, !acceptedAnswers.isEmpty {
            return acceptedAnswers.joined(separator: " / ")
        }

        return entry.answer?.displayText
    }

    private static func evaluateSorting(
        response: String,
        item: LessonContentModel.TaskItem,
        answerKey: LessonContentModel.AnswerKeyTask?
    ) -> PracticeEvaluation {
        guard let number = item.number?.sortingNumber,
              let categories = item.categories,
              let selectedCategoryIndex = categories.firstIndex(of: response),
              let entries = answerKey?.entries,
              entries.indices.contains(selectedCategoryIndex) else {
            return reviewedEvaluation(entry: nil, taskNotes: answerKey?.teacherNotes)
        }

        let selectedEntry = entries[selectedCategoryIndex]
        let isCorrect = selectedEntry.answer?.integerArrayValue?.contains(number) == true

        return PracticeEvaluation(
            state: isCorrect ? .correct : .incorrect,
            expectedAnswer: sortingExpectedAnswer(for: number, categories: categories, entries: entries),
            explanation: selectedEntry.explanation,
            errorType: selectedEntry.errorType,
            notes: selectedEntry.notes ?? answerKey?.teacherNotes,
            sampleAnswers: selectedEntry.sampleAnswers ?? []
        )
    }

    private static func sortingExpectedAnswer(
        for number: Int,
        categories: [String],
        entries: [LessonContentModel.AnswerEntry]
    ) -> String? {
        for (index, category) in categories.enumerated() where entries.indices.contains(index) {
            if entries[index].answer?.integerArrayValue?.contains(number) == true {
                return category
            }
        }

        return nil
    }

    private static func reviewedEvaluation(
        entry: LessonContentModel.AnswerEntry?,
        taskNotes: String?
    ) -> PracticeEvaluation {
        PracticeEvaluation(
            state: .reviewed,
            expectedAnswer: expectedAnswerText(from: entry),
            explanation: entry?.explanation,
            errorType: entry?.errorType,
            notes: entry?.notes ?? taskNotes,
            sampleAnswers: entry?.sampleAnswers ?? []
        )
    }

    private static func answerCandidates(from entry: LessonContentModel.AnswerEntry) -> [String] {
        var candidates = entry.acceptedAnswers ?? []

        if let answer = entry.answer {
            if let correction = answer.objectValue?["correction"]?.displayText {
                candidates.append(correction)
            } else {
                candidates.append(contentsOf: answer.candidateTexts)
            }
        }

        return candidates
    }

    private static func normalized(_ value: String) -> String {
        let trimmed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:"))
            .lowercased()

        let collapsedWhitespace = trimmed
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        switch collapsedWhitespace {
        case "zero article", "zero", "no article", "none":
            return "zero article"
        default:
            return collapsedWhitespace
        }
    }
}

private extension LessonContentNumber {
    var sortingNumber: Int? {
        switch self {
        case .integer(let value):
            return value
        case .string(let value):
            return Int(value)
        }
    }
}

private extension JSONValue {
    var objectValue: [String: JSONValue]? {
        guard case .object(let value) = self else {
            return nil
        }

        return value
    }

    var integerArrayValue: [Int]? {
        guard case .array(let values) = self else {
            return nil
        }

        return values.compactMap(\.integerValue)
    }

    var candidateTexts: [String] {
        switch self {
        case .string(let value):
            return [value]
        case .number(let value):
            return [Self.numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"]
        case .array(let values):
            return values.flatMap(\.candidateTexts)
        case .object, .bool, .null:
            return []
        }
    }

    var displayText: String? {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return Self.numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
        case .bool(let value):
            return value ? "true" : "false"
        case .array(let values):
            let displayValues = values.compactMap(\.displayText)
            return displayValues.isEmpty ? nil : displayValues.joined(separator: " / ")
        case .object(let object):
            let displayValues = object
                .sorted { $0.key < $1.key }
                .compactMap { key, value -> String? in
                    guard let displayText = value.displayText else {
                        return nil
                    }
                    return "\(key): \(displayText)"
                }
            return displayValues.isEmpty ? nil : displayValues.joined(separator: "\n")
        case .null:
            return nil
        }
    }

    private var integerValue: Int? {
        switch self {
        case .number(let value):
            return Int(value)
        case .string(let value):
            return Int(value)
        case .bool, .object, .array, .null:
            return nil
        }
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        return formatter
    }()
}
