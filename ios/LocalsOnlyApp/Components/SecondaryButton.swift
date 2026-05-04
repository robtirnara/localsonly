import SwiftUI

struct SecondaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.bodyCopy)
                .foregroundStyle(Color.coastalAqua)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.coastalAqua.opacity(0.6), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
