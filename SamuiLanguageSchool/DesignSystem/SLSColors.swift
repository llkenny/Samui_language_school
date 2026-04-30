//
//  SLSColors.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 30.04.2026.
//

import SwiftUI

enum SLSColors {
    static let brand = Color(hex: 0x2F80FF)
    static let brandStrong = Color(hex: 0x1764F5)
    static let brandSoft = Color(hex: 0xDBEAFE)
    static let brandMuted = Color(hex: 0x9BB9F4)

    static let purple = Color(hex: 0x9A20FF)
    static let purpleSoft = Color(hex: 0xF0D9FF)
    static let purpleSurface = Color(hex: 0xFBF5FF)

    static let background = Color(hex: 0xF7F8FA)
    static let surface = Color.white
    static let textPrimary = Color(hex: 0x111827)
    static let textSecondary = Color(hex: 0x667085)
    static let textTertiary = Color(hex: 0x98A2B3)
    static let border = Color(hex: 0xE3E5EA)
    static let separator = Color(hex: 0xE5E7EB)
    static let disabledFill = Color(hex: 0xE4E6EB)
    static let blueSurface = Color(hex: 0xEEF6FF)
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
