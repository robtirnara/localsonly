import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    var icon: String = "water.waves"
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(Color.coastalAqua)
                .accessibilityHidden(true)
            Text(title)
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.bodyCopy)
                .foregroundStyle(Color.coastalTextSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.cardTitle)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.coastalCoral)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .accessibilityElement(children: .combine)
    }
}
