//
//  PracticeView.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 30.04.2026.
//

import SwiftUI

struct PracticeView: View {
    var onBack: () -> Void
    @State private var selectedAnswer: String?

    private let answers = ["go", "went", "goes", "going"]

    var body: some View {
        ZStack(alignment: .bottom) {
            SLSColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                practiceHeader

                VStack(alignment: .leading, spacing: 30) {
                    SLSPill(title: "Question 1")

                    questionText

                    VStack(spacing: SLSSpacing.md) {
                        ForEach(answers, id: \.self) { answer in
                            AnswerOptionButton(
                                title: answer,
                                isSelected: selectedAnswer == answer
                            ) {
                                selectedAnswer = answer
                            }
                        }
                    }

                    Spacer(minLength: 110)
                }
                .padding(.horizontal, SLSSpacing.lg)
                .padding(.top, 40)
            }

            Button(action: {}) {
                Text("Check Answer")
                    .font(SLSTypography.button)
                    .foregroundStyle(selectedAnswer == nil ? SLSColors.textTertiary : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 68)
                    .background(selectedAnswer == nil ? SLSColors.disabledFill : SLSColors.brand)
                    .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(selectedAnswer == nil)
            .padding(.horizontal, SLSSpacing.lg)
            .padding(.bottom, 34)
        }
        .navigationBarBackButtonHidden()
    }

    private var practiceHeader: some View {
        VStack(spacing: 0) {
            SLSTopBar(title: "Practice", backAction: onBack, showsSeparator: false)

            HStack(spacing: SLSSpacing.md) {
                SLSProgressBar(value: 0.2)
                Text("1/5")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(SLSColors.textSecondary)
            }
            .padding(.horizontal, SLSSpacing.lg)
            .padding(.top, 4)
            .padding(.bottom, 26)
        }
        .background(SLSColors.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(SLSColors.separator)
                .frame(height: 1)
        }
    }

    private var questionText: some View {
        Text("I \(Text("___").foregroundStyle(SLSColors.brand)) to the cinema last\nnight.")
            .font(SLSTypography.question)
            .foregroundStyle(SLSColors.textPrimary)
            .lineSpacing(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct AnswerOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(SLSTypography.bodyStrong)
                    .foregroundStyle(SLSColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 22)
            .frame(height: 74)
            .background(SLSColors.surface)
            .overlay {
                RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous)
                    .stroke(isSelected ? SLSColors.brand : SLSColors.border, lineWidth: isSelected ? 3 : 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PracticeView(onBack: {})
}
