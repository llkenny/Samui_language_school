//
//  LessonContentModel.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 01.05.2026.
//

import Foundation

struct LessonContentModel: Decodable, Identifiable {
    let id: String
    let title: String
    let level: Level
    let subtitle: String
    let estimatedMinutes: EstimatedMinutes
    let tags: [String]
    let source: Source
    let screenSummary: ScreenSummary
    let learningPath: [LearningPathStep]
    let objectives: [String]
    let difficultyGuide: [DifficultyGuideEntry]
    let review: Review?
    let theorySections: [TheorySection]
    let practiceTasks: [PracticeTask]
    let answerKey: [AnswerKeyTask]
    let selfAssessment: [String]?
}

extension LessonContentModel {
    struct EstimatedMinutes: Decodable {
        let min: Int
        let max: Int
    }

    struct Source: Decodable {
        let fileName: String
        let pageCount: Int
        let extractionMethod: String?
    }

    struct Level: Decodable {
        let code: String
        let label: String
        let descriptor: String?
    }

    struct ScreenSummary: Decodable {
        let themeTitle: String
        let levelLabel: String
        let lessonBadge: String
        let shortDescription: String
        let estimatedReadTimeLabel: String
        let primaryPracticeLabel: String?
        let progressLabel: String?
    }

    struct LearningPathStep: Decodable, Identifiable {
        let id: String
        let title: String
        let instructions: String
    }

    struct DifficultyGuideEntry: Decodable {
        let rating: String
        let label: String
        let taskIds: [String]
    }

    struct ContentBlock: Decodable {
        let type: ContentBlockType
        let title: String?
        let text: String?
        let items: [String]?
        let formula: String?
        let columns: [String]?
        let rows: [[String: JSONValue]]?
        let examples: [String]?
        let incorrect: String?
        let correct: String?
        let explanation: String?
        let calloutType: String?
        let caption: String?
    }

    enum ContentBlockType: String, Decodable {
        case paragraph
        case ruleList
        case formula
        case example
        case exampleList
        case table
        case callout
        case comparison
        case modelText
        case checklist
    }

    struct Review: Decodable {
        let title: String
        let contentBlocks: [ContentBlock]
        let warmUpTask: PracticeTask?
    }

    struct TheorySection: Decodable, Identifiable {
        let id: String
        let title: String
        let order: Int
        let contentBlocks: [ContentBlock]
        let tryItTaskIds: [String]
    }

    struct PracticeTask: Decodable, Identifiable {
        let id: String
        let title: String
        let sourceLabel: String?
        let kind: PracticeTaskKind
        let mode: PracticeTaskMode
        let difficulty: String?
        let estimatedMinutes: EstimatedMinutes?
        let instructions: String
        let stimulus: String?
        let supportingPrompts: [String]?
        let items: [TaskItem]
    }

    enum PracticeTaskKind: String, Decodable {
        case tryIt
        case activity
        case warmUp
    }

    enum PracticeTaskMode: String, Decodable {
        case noticing
        case practice
        case production
        case review
    }

    struct TaskItem: Decodable, Identifiable {
        let id: String
        let type: TaskItemType
        let number: LessonContentNumber?
        let prompt: String
        let context: String?
        let answerType: String?
        let options: [String]?
        let targetForm: String?
        let targetForms: [String]?
        let categories: [String]?
        let text: String?
        let original: String?
        let newSubject: String?
        let checklist: [String]?
    }

    enum TaskItemType: String, Decodable {
        case gapFill
        case multipleChoice
        case rewrite
        case sorting
        case labeling
        case errorCorrection
        case tableCompletion
        case paragraphWriting
        case speakingPrompt
        case freeResponse
    }

    struct AnswerEntry: Decodable {
        let itemId: String
        let answer: JSONValue?
        let acceptedAnswers: [String]?
        let sampleAnswers: [String]?
        let explanation: String?
        let errorType: String?
        let notes: String?
    }

    struct AnswerKeyTask: Decodable {
        let taskId: String
        let entries: [AnswerEntry]
        let teacherNotes: String?
    }
}

enum LessonContentNumber: Decodable {
    case integer(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .integer(value)
            return
        }
        self = .string(try container.decode(String.self))
    }
}

enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }
}
