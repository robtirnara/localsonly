import SwiftUI

enum ToastType {
    case success, error, info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .success: return .coastalStatusSuccess
        case .error: return .coastalCoral
        case .info: return .coastalAqua
        }
    }
}

struct ToastView: View {
    let message: String
    var type: ToastType = .info

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: type.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(type.accentColor)
            Text(message)
                .font(.captionCopy)
                .foregroundStyle(Color.coastalTextPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
        .overlay(
            Capsule()
                .stroke(type.accentColor.opacity(0.3), lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.xl)
    }
}
