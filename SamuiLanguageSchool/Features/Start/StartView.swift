//
//  StartView.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 30.04.2026.
//

import SwiftUI

struct StartView: View {
    var onStartLearning: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            SLSColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                VStack(spacing: SLSSpacing.lg) {
                    currentThemeCard
                    levelCard
                    roleCard
                    Spacer(minLength: 90)
                }
                .padding(.horizontal, SLSSpacing.lg)
                .padding(.top, SLSSpacing.xl)
            }

            SLSPrimaryButton(title: "Start Learning", action: onStartLearning)
                .padding(.horizontal, SLSSpacing.lg)
                .padding(.bottom, 34)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SLSIconCircle(systemName: "book")
                Spacer()
                Circle()
                    .fill(SLSColors.brandMuted)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.22), lineWidth: 6)
                    }
            }
            .padding(.top, 70)

            Spacer()

            Text("Welcome back!")
                .font(SLSTypography.heroTitle)
                .foregroundStyle(.white)
                .padding(.bottom, 14)

            Text("Continue your learning journey")
                .font(SLSTypography.heroSubtitle)
                .foregroundStyle(.white.opacity(0.92))
                .padding(.bottom, 45)
        }
        .padding(.horizontal, SLSSpacing.lg)
        .frame(maxWidth: .infinity, minHeight: 292, alignment: .leading)
        .background(SLSColors.brand)
        .ignoresSafeArea(edges: .top)
    }

    private var currentThemeCard: some View {
        SLSCard {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Current Theme")
                        .font(SLSTypography.cardTitle)
                        .foregroundStyle(SLSColors.textPrimary)
                    Spacer()
                    SLSPill(title: "Active", foreground: SLSColors.brand, background: SLSColors.brandSoft)
                }

                Text("Past Simple Tense")
                    .font(SLSTypography.body)
                    .foregroundStyle(Color(hex: 0x344054))

                HStack(spacing: SLSSpacing.sm) {
                    SLSProgressBar(value: 0.65)
                    Text("65%")
                        .font(SLSTypography.body)
                        .foregroundStyle(SLSColors.textSecondary)
                }
            }
        }
    }

    private var levelCard: some View {
        SLSCard {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your Level")
                    .font(SLSTypography.caption)
                    .foregroundStyle(SLSColors.textSecondary)

                HStack(alignment: .firstTextBaseline) {
                    Text("Intermediate")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(SLSColors.textPrimary)
                    Spacer()
                    Text("B1")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(SLSColors.textTertiary)
                }
            }
        }
    }

    private var roleCard: some View {
        SLSCard {
            VStack(alignment: .leading, spacing: SLSSpacing.lg) {
                Text("Your Role")
                    .font(SLSTypography.caption)
                    .foregroundStyle(SLSColors.textSecondary)

                HStack(spacing: SLSSpacing.md) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(SLSColors.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(SLSColors.lavenderSoft)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Student")
                            .font(SLSTypography.bodyStrong)
                            .foregroundStyle(SLSColors.textPrimary)
                        Text("General English Course")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(SLSColors.textSecondary)
                    }
                }
            }
        }
    }
}

#Preview {
    StartView {}
}
