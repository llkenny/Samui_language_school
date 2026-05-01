//
//  SamuiLanguageSchoolTests.swift
//  SamuiLanguageSchoolTests
//
//  Created by max on 30.04.2026.
//

import Testing
@testable import SamuiLanguageSchool

struct SamuiLanguageSchoolTests {

    @Test func difficultyGuideTitleListUsesActivityNumbers() async throws {
        let titles = [
            "Activity 2 - Articles across a paragraph",
            "Activity 3 - Abstract nouns: a, the, or zero article",
            "Activity 4 - Generic the or zero article"
        ]

        #expect(
            DifficultyGuideTitleFormatter.listText(for: titles) ==
            """
            2 - Articles across a paragraph
            3 - Abstract nouns: a, the, or zero article
            4 - Generic the or zero article
            """
        )
    }

    @Test func difficultyGuideTitleFormatterLeavesNonActivityTitlesUnchanged() async throws {
        #expect(
            DifficultyGuideTitleFormatter.formattedTitle("Try It A - Article tracking") ==
            "Try It A - Article tracking"
        )
    }

    @MainActor
    @Test func practiceEvaluatorMatchesExactAnswerWithNormalization() async throws {
        let evaluation = PracticeAnswerEvaluator.evaluate(
            response: "  the. ",
            for: Self.taskItem(id: "item-1"),
            answerKey: Self.answerKey(entries: [
                Self.answerEntry(itemId: "item-1", answer: .string("The"))
            ])
        )

        #expect(evaluation.state == .correct)
    }

    @MainActor
    @Test func practiceEvaluatorAcceptsZeroArticleSynonyms() async throws {
        let evaluation = PracticeAnswerEvaluator.evaluate(
            response: "no article",
            for: Self.taskItem(id: "item-1"),
            answerKey: Self.answerKey(entries: [
                Self.answerEntry(itemId: "item-1", answer: .string("zero article"))
            ])
        )

        #expect(evaluation.state == .correct)
    }

    @MainActor
    @Test func practiceEvaluatorUsesAcceptedAnswers() async throws {
        let evaluation = PracticeAnswerEvaluator.evaluate(
            response: "an answer",
            for: Self.taskItem(id: "item-1"),
            answerKey: Self.answerKey(entries: [
                Self.answerEntry(
                    itemId: "item-1",
                    answer: nil,
                    acceptedAnswers: ["a response", "an answer"]
                )
            ])
        )

        #expect(evaluation.state == .correct)
    }

    @MainActor
    @Test func practiceEvaluatorExtractsObjectCorrection() async throws {
        let evaluation = PracticeAnswerEvaluator.evaluate(
            response: "the Netherlands",
            for: Self.taskItem(id: "item-1", type: .errorCorrection),
            answerKey: Self.answerKey(entries: [
                Self.answerEntry(
                    itemId: "item-1",
                    answer: .object([
                        "error": .string("Netherlands"),
                        "correction": .string("the Netherlands")
                    ])
                )
            ])
        )

        #expect(evaluation.state == .correct)
        #expect(evaluation.expectedAnswer == "Error: Netherlands\nCorrection: the Netherlands")
    }

    @MainActor
    @Test func practiceEvaluatorMatchesSortingCategoryByAnswerArray() async throws {
        let evaluation = PracticeAnswerEvaluator.evaluate(
            response: "As long as",
            for: Self.taskItem(
                id: "item-2",
                type: .sorting,
                number: .integer(2),
                categories: ["Unless", "As long as"]
            ),
            answerKey: Self.answerKey(entries: [
                Self.answerEntry(itemId: "category-unless", answer: .array([.number(1), .number(3)])),
                Self.answerEntry(itemId: "category-as-long-as", answer: .array([.number(2), .number(4)]))
            ])
        )

        #expect(evaluation.state == .correct)
        #expect(evaluation.expectedAnswer == "As long as")
    }

    @MainActor
    @Test func practiceEvaluatorMarksTeacherAssessedItemReviewed() async throws {
        let evaluation = PracticeAnswerEvaluator.evaluate(
            response: "My open response",
            for: Self.taskItem(id: "item-1", type: .freeResponse),
            answerKey: Self.answerKey(entries: [], teacherNotes: "Teacher-assessed.")
        )

        #expect(evaluation.state == .reviewed)
        #expect(!evaluation.isGradable)
        #expect(evaluation.notes == "Teacher-assessed.")
    }

    @MainActor
    @Test func practiceTaskResolverUsesRequestedTaskWhenValid() async throws {
        let lesson = Self.lesson(tasks: [
            Self.practiceTask(id: "first-task"),
            Self.practiceTask(id: "second-task")
        ])

        #expect(
            PracticeTaskResolver.selectedTask(in: lesson, requestedTaskID: "second-task")?.id ==
            "second-task"
        )
    }

    @MainActor
    @Test func practiceTaskResolverFallsBackToFirstTask() async throws {
        let lesson = Self.lesson(tasks: [
            Self.practiceTask(id: "first-task"),
            Self.practiceTask(id: "second-task")
        ])

        #expect(
            PracticeTaskResolver.selectedTask(in: lesson, requestedTaskID: "missing-task")?.id ==
            "first-task"
        )
    }

    private static func taskItem(
        id: String,
        type: LessonContentModel.TaskItemType = .gapFill,
        number: LessonContentNumber? = nil,
        categories: [String]? = nil
    ) -> LessonContentModel.TaskItem {
        LessonContentModel.TaskItem(
            id: id,
            type: type,
            number: number,
            prompt: "Prompt",
            context: nil,
            answerType: nil,
            options: nil,
            targetForm: nil,
            targetForms: nil,
            categories: categories,
            text: nil,
            original: nil,
            newSubject: nil,
            checklist: nil
        )
    }

    private static func answerKey(
        taskId: String = "task",
        entries: [LessonContentModel.AnswerEntry],
        teacherNotes: String? = nil
    ) -> LessonContentModel.AnswerKeyTask {
        LessonContentModel.AnswerKeyTask(
            taskId: taskId,
            entries: entries,
            teacherNotes: teacherNotes
        )
    }

    private static func answerEntry(
        itemId: String,
        answer: JSONValue?,
        acceptedAnswers: [String]? = nil
    ) -> LessonContentModel.AnswerEntry {
        LessonContentModel.AnswerEntry(
            itemId: itemId,
            answer: answer,
            acceptedAnswers: acceptedAnswers,
            sampleAnswers: nil,
            explanation: nil,
            errorType: nil,
            notes: nil
        )
    }

    private static func lesson(tasks: [LessonContentModel.PracticeTask]) -> LessonContentModel {
        LessonContentModel(
            id: "lesson",
            title: "Lesson",
            level: LessonContentModel.Level(code: "A1", label: "A1", descriptor: nil),
            subtitle: "Subtitle",
            estimatedMinutes: LessonContentModel.EstimatedMinutes(min: 1, max: 2),
            tags: [],
            source: LessonContentModel.Source(fileName: "file.pdf", pageCount: 1, extractionMethod: nil),
            screenSummary: LessonContentModel.ScreenSummary(
                themeTitle: "Theme",
                levelLabel: "A1",
                lessonBadge: "Lesson",
                shortDescription: "Description",
                estimatedReadTimeLabel: "1 min",
                primaryPracticeLabel: nil,
                progressLabel: nil
            ),
            learningPath: [],
            objectives: [],
            difficultyGuide: [],
            review: nil,
            theorySections: [
                LessonContentModel.TheorySection(
                    id: "section",
                    title: "Section",
                    order: 1,
                    contentBlocks: [],
                    tryItTaskIds: []
                )
            ],
            practiceTasks: tasks,
            answerKey: [],
            selfAssessment: nil
        )
    }

    private static func practiceTask(id: String) -> LessonContentModel.PracticeTask {
        LessonContentModel.PracticeTask(
            id: id,
            title: "Task",
            sourceLabel: nil,
            kind: .tryIt,
            mode: .practice,
            difficulty: nil,
            estimatedMinutes: nil,
            instructions: "Instructions",
            stimulus: nil,
            supportingPrompts: nil,
            items: []
        )
    }
}
