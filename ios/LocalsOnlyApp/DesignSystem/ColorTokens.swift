import SwiftUI

extension Color {
    /// Canvas tab bar / shell tint `#fffaf5` (warm cream; pairs with sand `#FFF6ED`).
    static let coastalTabBar = Color(hex: 0xFFFAF5)
    static let coastalBackground = Color(hex: 0xFFF6ED)
    static let coastalCard = Color(hex: 0xFFFCF9)

    static let vintageInk = Color(hex: 0x0F172A)
    static let coastalAqua = Color(hex: 0x0EA5E9)
    static let coastalCoral = Color(hex: 0xF97316)
    static let coastalSand = Color(hex: 0xFFF6ED)
    /// Light surf tint used for chips and highlights (matches design foam panels).
    static let coastalFoam = Color(hex: 0xE0F2FE)

    static let coastalTextPrimary = Color(hex: 0x0F172A)
    static let coastalTextSecondary = Color(hex: 0x6B7280)

    /// Primary ink / FAB background (slate-900).
    static let coastalInk = Color.vintageInk

    static let coastalStatusProvisional = Color(hex: 0xD69E2E)
    static let coastalStatusRestricted = Color(hex: 0xFC8181)
    static let coastalStatusSuccess = Color(hex: 0x48BB78)

    static func scoreColor(for score: Double) -> Color {
        switch score {
        case ..<4.0: return Color(hex: 0xFC8181)
        case 4.0..<6.0: return Color(hex: 0xED8936)
        case 6.0..<7.5: return Color(hex: 0xECC94B)
        case 7.5..<9.0: return .coastalAqua
        default: return Color(hex: 0x48BB78)
        }
    }

    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
