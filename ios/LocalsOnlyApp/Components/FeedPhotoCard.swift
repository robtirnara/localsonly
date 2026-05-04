import SwiftUI

struct FeedPhotoCard: View {
    let itemName: String
    let placeName: String
    let actorName: String
    let score: Double
    var photoURL: String? = nil
    var category: String = "food"
    var timestamp: Date? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ZStack(alignment: .bottomTrailing) {
                Color.coastalSand.opacity(0.06)
                    .frame(height: 200)
                    .overlay {
                        imageContent
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text(String(format: "%.1f", score))
                    .font(.system(.subheadline, design: .default, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(.ultraThinMaterial)
                    .background(Color.scoreColor(for: score).opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(Spacing.sm)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(itemName)
                    .font(.cardTitle)
                    .foregroundStyle(Color.coastalTextPrimary)
                    .lineLimit(1)

                HStack(spacing: 0) {
                    Text(placeName)
                    Text(" · ")
                    Text(actorName)
                    if let timestamp {
                        Text(" · ")
                        Text(timestamp.relativeString)
                    }
                }
                .font(.captionCopy)
                .foregroundStyle(Color.coastalTextSecondary)
                .lineLimit(1)
            }
        }
    }

    var accessibilityDescription: String {
        "\(itemName) at \(placeName), rated \(String(format: "%.1f", score)) by \(actorName)"
    }

    @ViewBuilder
    private var imageContent: some View {
        if let photoURL, !photoURL.isEmpty, let url = URL(string: photoURL) {
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
