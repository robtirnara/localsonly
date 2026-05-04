import SwiftUI

struct PlaceCard: View {
    let title: String
    let subtitle: String
    var trailingText: String? = nil
    var trailingScore: Double? = nil
    var badgeText: String? = nil
    var category: String? = nil

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: Spacing.sm) {
                if let category {
                    CategoryIconView(category: category, size: 36)
                        .foregroundStyle(Color.coastalSand)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.cardTitle)
                        .foregroundStyle(Color.coastalTextPrimary)
                    Text(subtitle)
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalTextSecondary)
                    if let badgeText {
                        Text(badgeText)
                            .font(.microLabel)
                            .foregroundStyle(Color.coastalSand)
                    }
                }
                Spacer()
                if let trailingText {
                    if let score = trailingScore {
                        Text(trailingText)
                            .font(.sectionTitle)
                            .foregroundStyle(Color.scoreColor(for: score))
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(Color.scoreColor(for: score).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        Text(trailingText)
                            .font(.microLabel)
                            .foregroundStyle(Color.coastalAqua)
                    }
                }
            }
        }
    }
}
