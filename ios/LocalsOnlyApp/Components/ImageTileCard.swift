import SwiftUI

struct ImageTileCard: View {
    let title: String
    let subtitle: String
    var imageURL: String? = nil
    var category: String = "food"
    var score: Double? = nil
    var badgeText: String? = nil

    private let imageAspect: CGFloat = 3.0 / 2.0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {

            ZStack(alignment: .bottomTrailing) {
                Color.coastalSand.opacity(0.06)
                    .aspectRatio(imageAspect, contentMode: .fit)
                    .overlay {
                        imageContent
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if let score {
                    Text(String(format: "%.1f", score))
                        .font(.system(.caption, design: .default, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(.ultraThinMaterial)
                        .background(Color.scoreColor(for: score).opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .padding(Spacing.xs)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.cardTitle)
                    .foregroundStyle(Color.coastalTextPrimary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.captionCopy)
                    .foregroundStyle(Color.coastalTextSecondary)
                    .lineLimit(1)

                if let badgeText {
                    Text(badgeText)
                        .font(.microLabel)
                        .foregroundStyle(Color.coastalSand)
                }
            }
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    PlaceholderHeroView(category: category)
                }
            }
        } else {
            PlaceholderHeroView(category: category)
        }
    }
}

extension ImageTileCard {
    func withAccessibility() -> some View {
        self.accessibilityElement(children: .combine)
            .accessibilityLabel("\(title), \(subtitle)\(score.map { ", score \(String(format: "%.1f", $0))" } ?? "")")
    }
}
