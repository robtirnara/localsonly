import SwiftUI

struct StatePill: View {
    let text: String

    private var color: Color {
        switch text {
        case "verified_local": return .coastalAqua
        case "provisional_local": return .coastalStatusProvisional
        case "restricted", "under_review": return .coastalStatusRestricted
        default: return .coastalTextSecondary
        }
    }

    var body: some View {
        Text(text.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.microLabel)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(color.opacity(0.20))
            .clipShape(Capsule())
    }
}
