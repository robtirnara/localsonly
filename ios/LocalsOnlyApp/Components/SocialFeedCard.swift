import SwiftUI

/// Social feed article card (reference: warm card, spot pill, dashed actions).
struct SocialFeedCard: View {
    let event: FeedEventResponse

    private var metaLine: String {
        "\(event.createdAt.relativeString) · \(event.placeName)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center) {
                DefaultAvatarView(variant: .forUser(event.actorUserID), size: 40)
                    .overlay(Circle().stroke(Color.coastalAqua, lineWidth: 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.actorDisplayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.coastalInk)
                    Text(metaLine)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.coastalTextSecondary)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.coastalTextSecondary.opacity(0.5))
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 12))
                Text(event.placeName)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Color.coastalAqua)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.coastalFoam)
            .clipShape(Capsule())

            ZStack(alignment: .topTrailing) {
                photoArea
                    .frame(height: 256)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                    )

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.yellow.opacity(0.95))
                    Text(String(format: "%.1f", event.score))
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Color.coastalInk)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.92))
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(12)
            }

            Text(event.itemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.coastalInk)

            Text("Rated \(event.itemName.lowercased()) at \(event.placeName).")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.coastalTextSecondary.opacity(0.95))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Spacing.sm) {
                vibeChip("Post-Surf", icon: "water.waves", tint: Color.orange.opacity(0.12), fg: Color.coastalCoral)
                vibeChip("Outdoor", icon: "sun.max.fill", tint: Color.blue.opacity(0.1), fg: Color.blue)
            }

            dashedDivider

            HStack {
                HStack(spacing: Spacing.md) {
                    Label("24", systemImage: "heart")
                        .font(.system(size: 14, weight: .medium))
                    Label("3", systemImage: "bubble.right")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Color.coastalTextSecondary)
                Spacer()
                Image(systemName: "bookmark")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.coastalTextSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.coastalCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.orange.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.coastalCoral.opacity(0.08), radius: 20, y: 10)
    }

    private var dashedDivider: some View {
        Rectangle()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            .foregroundStyle(Color.gray.opacity(0.2))
            .frame(height: 1)
            .padding(.vertical, 4)
    }

    private func vibeChip(_ title: String, icon: String, tint: Color, fg: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(title)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var photoArea: some View {
        if let photoURL = event.photoURL, !photoURL.isEmpty, let url = URL(string: photoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    PlaceholderHeroView(category: "food", height: 256)
                }
            }
        } else {
            PlaceholderHeroView(category: "food", height: 256)
        }
    }
}

struct PopularSpotFeedCard: View {
    let place: PopularPlaceResponse

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.coastalCoral)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Popular near you")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.coastalInk)
                    Text("Trending · \(place.ratingsCount) ratings")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.coastalTextSecondary)
                }
                Spacer()
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                Text(place.placeName)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Color.coastalAqua)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.coastalFoam)
            .clipShape(Capsule())

            ZStack(alignment: .topTrailing) {
                cover
                    .frame(height: 256)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.yellow.opacity(0.95))
                    Text(String(format: "%.1f", place.averageScore))
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Color.coastalInk)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.92))
                .clipShape(Capsule())
                .padding(12)
            }

            Text(place.placeName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.coastalInk)

            Text("\(place.category.capitalized) · community signal on localsonly.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.coastalTextSecondary)
                .lineSpacing(3)

            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .foregroundStyle(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.vertical, 4)

            HStack {
                Spacer()
                Image(systemName: "bookmark")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.coastalTextSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.coastalCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.orange.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.coastalCoral.opacity(0.08), radius: 20, y: 10)
    }

    @ViewBuilder
    private var cover: some View {
        if let urlString = place.coverPhotoURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    PlaceholderHeroView(category: place.category, height: 256)
                }
            }
        } else {
            PlaceholderHeroView(category: place.category, height: 256)
        }
    }
}
