# Agent Instructions

These instructions are for coding agents working in this repository.

## Project Intent

Build an iOS app for home practice in a language school. The core user flow is:

1. Home screen with the current theme, student level, and role.
2. Theory screen with lesson explanation and examples.
3. Practice screen with one question and multiple answer variants.

The current codebase is still the default SwiftUI + SwiftData project scaffold. Treat the screenshots and `Readme.md` as the desired product direction.

## Working Rules

- Prefer SwiftUI-native layout and navigation.
- Keep the app usable on modern iPhone sizes first.
- Keep views small and focused once the starter `ContentView` is replaced.
- Do not introduce networking, authentication, analytics, or third-party dependencies unless the task explicitly requires them.
- Do not remove SwiftData setup casually. If persistence is not needed for a task, static in-memory sample data is acceptable.
- Preserve user changes in the working tree. Inspect `git status --short` before editing.

## Suggested Architecture

Use a simple feature structure as the app grows:

```text
SamuiLanguageSchool/
  App/
  Models/
  Data/
  Features/
    Home/
    Theory/
    Practice/
  DesignSystem/
```

Good first models:

- `CourseTheme`
- `StudentLevel`
- `UserRole`
- `Lesson`
- `TheorySection`
- `PracticeQuestion`
- `PracticeSession`

Good first views:

- `HomeView`
- `TheoryView`
- `PracticeView`
- `PrimaryButton`
- `ProgressBar`
- `AnswerOptionRow`

## UI Guidelines

- Match the provided design direction: bright blue primary actions, white cards, light gray app background, rounded panels, and large readable text.
- Use SF Symbols for icons.
- Keep buttons at comfortable touch sizes.
- Avoid dense desktop-style layouts.
- Avoid decorative complexity until the core learning flow works.
- Make disabled, selected, correct, and incorrect answer states visually distinct.
- Keep bottom call-to-action buttons away from the home indicator using safe-area handling.

## Implementation Preferences

- Start with static sample lesson content before persistence.
- Use `NavigationStack` for the Home -> Theory -> Practice flow.
- Keep state for the practice flow local until it needs to be shared or persisted.
- Use value types for lesson and question models unless SwiftData persistence is specifically needed.
- Add SwiftUI previews for new reusable views and major screens.
- Use dependency injection for sample content where it keeps previews and tests simple.

## Testing

Use Swift Testing for model and state tests. Prioritize:

- A practice session starts at question 1.
- Selecting an answer enables checking.
- Checking a correct answer records success.
- Checking a wrong answer records failure.
- Moving to the next question advances progress.
- Completing the final question ends the session.

Use UI tests only for stable high-level flows, such as launching the app and reaching the practice screen.

## Commands

List project schemes:

```sh
xcodebuild -list -project SamuiLanguageSchool.xcodeproj
```

Build:

```sh
xcodebuild -scheme SamuiLanguageSchool -project SamuiLanguageSchool.xcodeproj build
```

Test:

```sh
xcodebuild -scheme SamuiLanguageSchool -project SamuiLanguageSchool.xcodeproj test
```

When simulator selection is needed, add an explicit destination:

```sh
xcodebuild -scheme SamuiLanguageSchool -project SamuiLanguageSchool.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Documentation

Update `Readme.md` when product scope, setup steps, supported iOS version, or the main app flow changes.
