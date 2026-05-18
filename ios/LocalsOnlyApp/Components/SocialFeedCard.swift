import SwiftUI

// MARK: - `user-feed` canvas parity (get_canvas Social Feed HTML)

private enum FeedCanvasMetrics {
    static let cardCorner: CGFloat = 32
    static let cardPadding: CGFloat = 20
    static let heroCorner: CGFloat = 16
    static let avatarSize: CGFloat = 48
    static let toolbarIconCircle: CGFloat = 40
}

/// Five “wave” segments matching canvas `ph-waves` row (score is 0…10 across five slots).
private struct FeedWavesRow: View {
    let score: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: "water.waves")
                    .font(.system(size: 17))
                    .foregroundStyle(segmentStyle(index: index))
            }
        }
    }

    private func segmentStyle(index: Int) -> Color {
        let span = 10.0 / 5.0
        let start = Double(index) * span
        let t = min(1, max(0, (score - start) / span))
        if t >= 0.92 { return Color.feedCanvasOcean }
        if t >= 0.08 { return Color.feedCanvasOcean.opacity(0.55) }
        return Color.feedCanvasOcean.opacity(0.22)
    }
}

private struct FeedScoreBadge: View {
    let score: Double

    var body: some View {
        HStack(spacing: 8) {
            Text(String(format: "%.1f", score))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
            FeedWavesRow(score: score)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.feedCanvasCard.opacity(0.9))
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
    }
}

private struct FeedTimePill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(Color.feedCanvasOcean)
            .tracking(0.4)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.feedCanvasSky.opacity(0.2))
            .clipShape(Capsule())
    }
}

/// Social feed article card (`user-feed`: header → 4:5 hero + bottom score badge → body → actions).
struct SocialFeedCard: View {
    let event: FeedEventResponse

    private var headerTime: String {
        event.createdAt.relativeString
    }

    private var bodyCopy: String {
        "\(event.itemName) at \(event.placeName) — \(String(format: "%.1f", event.score))/10 on localsonly."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                DefaultAvatarView(variant: .forUser(event.actorUserID), size: FeedCanvasMetrics.avatarSize)
                    .overlay(Circle().stroke(Color.feedCanvasSky, lineWidth: 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.actorDisplayName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasInk)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 13, weight: .bold))
                        Text(event.placeName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color.feedCanvasConcrete)
                }

                Spacer(minLength: 8)

                FeedTimePill(text: headerTime)
            }
            .padding(.bottom, 16)

            ZStack(alignment: .bottomLeading) {
                FeedHeroPhoto(
                    photoURL: event.photoURL,
                    category: "food",
                    cornerRadius: FeedCanvasMetrics.heroCorner,
                    aspectRatio: 4.0 / 5.0
                )

                FeedScoreBadge(score: event.score)
                    .padding(16)
            }
            .padding(.bottom, 16)

            Text(bodyCopy)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.feedCanvasDivider)
                    .frame(height: 1)
                HStack(spacing: 24) {
                    Label {
                        Text("24")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    } icon: {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 22))
                    }
                    .foregroundStyle(Color.feedCanvasOcean)

                    Label {
                        Text("5")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    } icon: {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 22))
                    }
                    .foregroundStyle(Color.feedCanvasConcrete)

                    Spacer(minLength: 0)

                    Image(systemName: "bookmark")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.feedCanvasConcrete)
                }
                .padding(.top, 16)
            }
        }
        .padding(FeedCanvasMetrics.cardPadding)
        .background(Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: FeedCanvasMetrics.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FeedCanvasMetrics.cardCorner, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
    }
}

struct PopularSpotFeedCard: View {
    let place: PopularPlaceResponse

    private var subline: String {
        let cat = place.category.capitalized
        if let n = place.neighborhood, !n.isEmpty {
            return "\(cat) · \(n)"
        }
        return "\(cat) · \(place.ratingsCount) ratings"
    }

    private var bodyCopy: String {
        "\(place.placeName): \(place.ratingsCount) ratings, \(String(format: "%.1f", place.averageScore)) avg — \(place.category.capitalized) on localsonly."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.feedCanvasCard)
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.feedCanvasOcean)
                }
                .frame(width: FeedCanvasMetrics.avatarSize, height: FeedCanvasMetrics.avatarSize)
                .overlay(Circle().stroke(Color.feedCanvasSky, lineWidth: 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.placeName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasInk)
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 13, weight: .bold))
                        Text(subline)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color.feedCanvasConcrete)
                }

                Spacer(minLength: 8)

                FeedTimePill(text: "Trending")
            }
            .padding(.bottom, 16)

            ZStack(alignment: .bottomLeading) {
                FeedHeroPhoto(
                    photoURL: place.coverPhotoURL,
                    category: place.category,
                    cornerRadius: FeedCanvasMetrics.heroCorner,
                    aspectRatio: 4.0 / 5.0
                )

                FeedScoreBadge(score: place.averageScore)
                    .padding(16)
            }
            .padding(.bottom, 16)

            Text(bodyCopy)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.feedCanvasDivider)
                    .frame(height: 1)
                HStack(spacing: 24) {
                    Label {
                        Text("11")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    } icon: {
                        Image(systemName: "heart")
                            .font(.system(size: 22))
                    }
                    .foregroundStyle(Color.feedCanvasConcrete)

                    Label {
                        Text("2")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    } icon: {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 22))
                    }
                    .foregroundStyle(Color.feedCanvasConcrete)

                    Spacer(minLength: 0)

                    Image(systemName: "bookmark")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.feedCanvasConcrete)
                }
                .padding(.top, 16)
            }
        }
        .padding(FeedCanvasMetrics.cardPadding)
        .background(Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: FeedCanvasMetrics.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FeedCanvasMetrics.cardCorner, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
    }
}
