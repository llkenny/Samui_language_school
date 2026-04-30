# Samui Language School

Samui Language School is an iOS app for language-school students to practice at home between lessons. The app is intended to guide a student through a short learning flow:

1. Review the current learning context: active theme, level, and role.
2. Read the theory for the selected lesson.
3. Complete practice questions with one prompt and multiple answer variants.

The initial design direction is based on three screens:

- Home: current theme progress, student level, role, and a primary "Start Learning" action.
- Theory: lesson summary, grammar explanation, examples, and a fixed "Start Practice" action.
- Practice: question progress, one fill-in-the-blank prompt, multiple answer options, and a disabled/enabled check-answer action.

## Project Status

This repository currently contains a fresh SwiftUI iOS project scaffold. The app still uses the default SwiftData sample `Item` model and starter `ContentView`, so the learning flow described above is the product target rather than the implemented state.

## Tech Stack

- SwiftUI for the app UI
- SwiftData for local persistence
- Swift Testing for unit tests
- XCTest UI tests
- Xcode project: `SamuiLanguageSchool.xcodeproj`
- App target: `SamuiLanguageSchool`
- Bundle identifier: `my.SamuiLanguageSchool`
- Current project version: `1`
- Marketing version: `1.0`
- Deployment target in the project file: iOS `26.4`

## Repository Layout

```text
SamuiLanguageSchool/
  SamuiLanguageSchoolApp.swift   App entry point and SwiftData container setup
  ContentView.swift              Current starter UI
  Item.swift                     Current starter SwiftData model
  Assets.xcassets/               App icons, accent color, and image assets
SamuiLanguageSchoolTests/        Unit tests using Swift Testing
SamuiLanguageSchoolUITests/      UI tests using XCTest
SamuiLanguageSchool.xcodeproj/   Xcode project
```

## Product Model

The core domain should center on lessons and practice sessions:

- Theme: the active topic, for example "Past Simple Tense".
- Level: the student's course level, for example B1 Intermediate.
- Role: the user's school role, initially Student.
- Lesson: theory content, estimated reading time, explanation sections, and examples.
- Practice question: prompt text, answer choices, correct answer, explanation, and progress.
- Practice session: current question index, selected answer, score, and completion state.

## Intended Navigation

```text
Home
  Start Learning
    Theory
      Start Practice
        Practice Question
```

Keep the first implementation simple and deterministic. Static sample lesson data is enough before adding persistence, remote content, accounts, or teacher/admin workflows.

## Local Development

Open the project in Xcode:

```sh
open SamuiLanguageSchool.xcodeproj
```

Build from the command line:

```sh
xcodebuild -scheme SamuiLanguageSchool -project SamuiLanguageSchool.xcodeproj build
```

Run tests from the command line:

```sh
xcodebuild -scheme SamuiLanguageSchool -project SamuiLanguageSchool.xcodeproj test
```

If simulator selection is required, add a destination, for example:

```sh
xcodebuild -scheme SamuiLanguageSchool -project SamuiLanguageSchool.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## UI Direction

- Use a clean, card-based learning interface with strong blue primary actions.
- Keep typography large and readable for mobile study sessions.
- Use progress indicators on the home and practice screens.
- Keep the theory screen scrollable with a persistent bottom action.
- Keep practice answers as large tappable rows.
- Disable "Check Answer" until an answer is selected.
- Provide clear correct/incorrect feedback after checking an answer.

## Near-Term Implementation Plan

1. Replace the default SwiftData sample UI with static lesson data.
2. Create separate SwiftUI views for Home, Theory, and Practice.
3. Add lightweight models for lesson content and practice questions.
4. Implement answer selection, check-answer state, and question progress.
5. Add previews for each screen.
6. Add unit tests for practice-session state and scoring.
