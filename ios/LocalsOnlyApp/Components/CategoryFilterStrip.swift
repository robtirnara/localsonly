import SwiftUI

/// Horizontal category chips aligned with the reference “Ranks” screen (Top Eats, Surf Coffee, …).
struct CategoryFilterStrip: View {
    @Binding var selected: String

    private let filters: [(id: String, label: String)] = [
        ("all", "✨ All"),
        ("food", "🍔 Top Eats"),
        ("coffee", "☕️ Surf Coffee"),
        ("drink", "🍹 Tiki Bars"),
        ("seafood", "🐟 Seafood"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(filters, id: \.id) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selected = filter.id
                        }
                    } label: {
                        Text(filter.label)
                            .font(.system(size: 13, weight: selected == filter.id ? .bold : .semibold))
                            .foregroundStyle(selected == filter.id ? Color.white : Color.coastalTextSecondary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selected == filter.id ? Color.coastalInk : Color.white)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange.opacity(selected == filter.id ? 0 : 0.08), lineWidth: 1)
                            )
                            .shadow(color: selected == filter.id ? Color.coastalInk.opacity(0.2) : .clear, radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }
}
