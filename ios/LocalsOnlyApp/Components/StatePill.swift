import SwiftUI

struct StatePill: View {
    let text: String

    private var label: String {
        text.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var foreground: Color {
        switch text {
        case "verified_local": return Color.feedCanvasOcean
        case "provisional_local": return Color.feedCanvasOcean
        case "restricted", "under_review": return Color.coastalStatusRestricted
        default: return Color.feedCanvasConcrete
        }
    }

    private var background: Color {
        switch text {
        case "verified_local": return Color.feedCanvasSky.opacity(0.25)
        case "provisional_local": return Color.feedCanvasSky.opacity(0.2)
        case "restricted", "under_review": return Color.coastalStatusRestricted.opacity(0.15)
        default: return Color.feedCanvasSky.opacity(0.12)
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(background)
            .clipShape(Capsule())
    }
}
