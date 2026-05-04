import SwiftUI

struct UserProfileScreen: View {
    let userID: UUID
    @EnvironmentObject private var session: SessionManager
    @State private var profile: UserProfileResponse?
    @State private var ratings: [RatingResponse] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if isLoading {
                    ForEach(0..<3, id: \.self) { _ in LoadingShimmer() }
                } else {
                    headerSection

                    if ratings.isEmpty {
                        EmptyStateView(
                            title: "No public ratings",
                            message: "This user hasn't shared any public ratings yet.",
                            icon: "star"
                        )
                    } else {
                        statsSection

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Public Ratings")
                                .font(.sectionTitle)
                                .foregroundStyle(Color.coastalTextPrimary)

                            ForEach(ratings) { rating in
                                NavigationLink(value: rating.placeID) {
                                    RatingCard(
                                        title: "\(rating.itemName ?? "Item") at \(rating.placeName ?? "Place")",
                                        subtitle: rating.notes,
                                        scoreText: String(format: "%.1f", rating.score),
                                        privacy: rating.privacy,
                                        photoURL: rating.photoURL,
                                        score: rating.score,
                                        timestamp: rating.createdAt,
                                        itemCategory: rating.itemCategory
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    addFriendButton
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .navigationTitle(profile?.displayName ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: UUID.self) { placeID in
            PlaceDetailScreen(placeID: placeID)
        }
        .task { await load() }
    }

    private var headerSection: some View {
        GlassCard {
            HStack(spacing: Spacing.md) {
                avatarView
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(profile?.displayName ?? "Local")
                        .font(.sectionTitle)
                        .foregroundStyle(Color.coastalTextPrimary)
                    if let bio = profile?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.captionCopy)
                            .foregroundStyle(Color.coastalTextSecondary)
                            .lineLimit(3)
                    }
                    Text(profile?.homeCity ?? "")
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalSand)
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let urlString = profile?.avatarURL, !urlString.isEmpty, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 58, height: 58).clipShape(Circle())
                } else {
                    initialsAvatar
                }
            }
        } else {
            initialsAvatar
        }
    }

    private var initialsAvatar: some View {
        DefaultAvatarView(
            variant: .forUser(userID),
            size: 58
        )
    }

    private var statsSection: some View {
        HStack(spacing: Spacing.sm) {
            GlassCard {
                VStack(spacing: Spacing.xs) {
                    Text("Ratings").font(.microLabel).foregroundStyle(Color.coastalTextSecondary)
                    Text("\(ratings.count)").font(.cardTitle).foregroundStyle(Color.coastalAqua)
                }.frame(maxWidth: .infinity)
            }
            GlassCard {
                let avg = ratings.isEmpty ? 0 : ratings.map(\.score).reduce(0, +) / Double(ratings.count)
                let avgColor: Color = ratings.isEmpty ? .coastalTextSecondary : .scoreColor(for: avg)
                VStack(spacing: Spacing.xs) {
                    Text("Average").font(.microLabel).foregroundStyle(Color.coastalTextSecondary)
                    Text(ratings.isEmpty ? "-" : String(format: "%.1f", avg))
                        .font(.cardTitle)
                        .foregroundStyle(avgColor)
                }.frame(maxWidth: .infinity)
            }
        }
    }

    private var addFriendButton: some View {
        SecondaryButton(title: "Add Friend") {
            Task {
                do {
                    try await session.api.sendFriendRequest(userID: userID)
                    session.showSuccess("Friend request sent")
                } catch {
                    session.showError(error.localizedDescription)
                }
            }
        }
        .padding(.top, Spacing.sm)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let profileTask = session.api.userProfile(id: userID)
            async let ratingsTask = session.api.userRatings(id: userID)
            profile = try await profileTask
            ratings = try await ratingsTask
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}
