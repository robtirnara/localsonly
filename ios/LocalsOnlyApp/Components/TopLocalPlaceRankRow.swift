import SwiftUI

// MARK: - `explore-2` canvas parity (Top Locals Spots HTML)

private enum ExploreCanvasMetrics {
    static let cardCorner: CGFloat = 28
    static let thumbSize: CGFloat = 96
    static let thumbCorner: CGFloat = 20
    static let rankBadgeSize: CGFloat = 28
    static let rankOneStripeWidth: CGFloat = 8
}

/// Score chip: `bg-sky/20 text-ocean` + waves icon.
struct ExploreScorePill: View {
    let score: Double

    var body: some View {
        HStack(spacing: 6) {
            Text(String(format: "%.1f", score))
                .font(.system(size: 14, weight: .bold, design: .rounded))
            Image(systemName: "water.waves")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(Color.feedCanvasOcean)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.feedCanvasSky.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// CTA block: `bg-sky/20 rounded-[32px]` hidden-gems promo from canvas.
struct ExploreHiddenGemsCard: View {
    var onDiscover: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.feedCanvasOcean)
                .padding(.bottom, 8)

            Text("Looking for hidden gems?")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .padding(.bottom, 4)

            Text("Check out spots with high ratings but low review counts.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.feedCanvasOcean)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            Button(action: onDiscover) {
                Text("Discover Locals Only Spots")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasOcean)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.feedCanvasCard)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.feedCanvasSky.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}

/// Ranked place row (`rounded-[28px]`, optional `#1` sky stripe, thumb badge, score pill).
struct TopLocalPlaceRankRow: View {
    let rank: Int
    let place: PopularPlaceResponse
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        Button {
            session.presentPlaceDetail(place.placeID)
        } label: {
            ZStack(alignment: .leading) {
                if rank == 1 {
                    Color.feedCanvasSky
                        .frame(width: ExploreCanvasMetrics.rankOneStripeWidth)
                }

                HStack(alignment: .center, spacing: 16) {
                    thumbnail

                    VStack(alignment: .leading, spacing: 0) {
                        Text(place.placeName)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.feedCanvasInk)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(place.neighborhood ?? "San Diego")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.feedCanvasConcrete)
                            .padding(.top, 2)
                            .padding(.bottom, 8)

                        HStack {
                            ExploreScorePill(score: place.averageScore)
                            Spacer(minLength: 8)
                            Text("\(place.ratingsCount) reviews")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.feedCanvasConcrete)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.leading, rank == 1 ? ExploreCanvasMetrics.rankOneStripeWidth + 8 : 8)
                .padding(.trailing, 24)
                .padding(.vertical, 8)
            }
            .background(Color.feedCanvasCard)
            .clipShape(RoundedRectangle(cornerRadius: ExploreCanvasMetrics.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ExploreCanvasMetrics.cardCorner, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var thumbnail: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let urlString = place.coverPhotoURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Color.feedCanvasHeroPlaceholder
                        }
                    }
                } else {
                    Color.feedCanvasHeroPlaceholder
                }
            }
            .frame(width: ExploreCanvasMetrics.thumbSize, height: ExploreCanvasMetrics.thumbSize)
            .clipShape(RoundedRectangle(cornerRadius: ExploreCanvasMetrics.thumbCorner, style: .continuous))

            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: ExploreCanvasMetrics.rankBadgeSize, height: ExploreCanvasMetrics.rankBadgeSize)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
                .padding(4)
        }
    }
}
