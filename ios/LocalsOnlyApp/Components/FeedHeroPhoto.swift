import SwiftUI

// MARK: - Fixed-aspect feed hero (AIDesigner reference: 3:2, object-fit cover, uniform frames)

/// Every feed photo uses the same 3:2 frame with center crop so mixed aspect ratios and formats look consistent.
struct FeedHeroPhoto: View {
    let photoURL: String?
    var category: String = "food"
    var cornerRadius: CGFloat = 12
    /// Canvas `user-feed` uses `aspect-[4/5]`; explore-style tiles keep the default 3:2.
    var aspectRatio: CGFloat = 3.0 / 2.0

    var body: some View {
        Color.feedCanvasHeroPlaceholder
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                resolvedImage
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }

    @ViewBuilder
    private var resolvedImage: some View {
        if let photoURL, !photoURL.isEmpty, let url = URL(string: photoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                case .failure:
                    PlaceholderHeroView(category: category)
                case .empty:
                    PlaceholderHeroView(category: category)
                @unknown default:
                    PlaceholderHeroView(category: category)
                }
            }
        } else {
            PlaceholderHeroView(category: category)
        }
    }
}

struct FeedSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: Spacing.sm + 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasConcrete)
                .textCase(.uppercase)
                .tracking(1.8)
            Rectangle()
                .fill(Color.feedCanvasInk.opacity(0.05))
                .frame(height: 1)
        }
        .padding(.top, Spacing.xxs)
        .padding(.bottom, Spacing.xs)
    }
}
