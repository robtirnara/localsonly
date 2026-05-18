import SwiftUI

/// `profile-2` canvas (`d296d42a-…`): public profile hero, stats, follow, taste match, top ranks, recent ratings.
struct UserProfileScreen: View {
    let userID: UUID

    @EnvironmentObject private var session: SessionManager
    @State private var profile: UserProfileResponse?
    @State private var ratings: [RatingResponse] = []
    @State private var myRatings: [RatingResponse] = []
    @State private var isFriend = false
    @State private var friendRequestSent = false
    @State private var isLoading = true

    private var usernameHandle: String {
        guard let name = profile?.displayName else { return "@local" }
        let slug = name.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .filter { $0.isLetter || $0.isNumber }
        return "@\(slug.isEmpty ? "local" : slug)"
    }

    private var categoryRanks: [PublicProfileCategoryRank] {
        let grouped = Dictionary(grouping: ratings, by: { ($0.itemCategory ?? "other").lowercased() })
        return grouped.map { key, items in
            let top = items.max(by: { $0.score < $1.score })
            return PublicProfileCategoryRank(
                id: key,
                category: items.first?.itemCategory ?? key.capitalized,
                ratingsCount: items.count,
                topPlaceName: top?.placeName ?? "—",
                topScore: top?.score ?? 0
            )
        }
        .sorted { $0.ratingsCount > $1.ratingsCount }
    }

    private var tasteMatchPercent: Int? {
        guard !myRatings.isEmpty, !ratings.isEmpty else { return nil }
        let myCats = Set(myRatings.map { ($0.itemCategory ?? "other").lowercased() })
        let theirCats = Set(ratings.map { ($0.itemCategory ?? "other").lowercased() })
        let overlap = myCats.intersection(theirCats)
        guard !overlap.isEmpty else { return nil }
        return min(99, Int((Double(overlap.count) / Double(max(myCats.count, 1))) * 100) + 40)
    }

    private var tasteMatchCategories: [String] {
        let myCats = Set(myRatings.map { ($0.itemCategory ?? "other").capitalized })
        let theirCats = Set(ratings.map { ($0.itemCategory ?? "other").capitalized })
        return Array(myCats.intersection(theirCats)).sorted().prefix(2).map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                sheetDragHandle
                headerChrome
                    .padding(.bottom, PublicProfileMetrics.sectionGap)

                if isLoading {
                    loadingBody
                } else if let profile {
                    profileHero(profile)
                        .padding(.bottom, PublicProfileMetrics.sectionGap)

                    if let tasteMatchPercent, !tasteMatchCategories.isEmpty {
                        tasteMatchCard(percent: tasteMatchPercent, categories: tasteMatchCategories)
                            .padding(.bottom, PublicProfileMetrics.sectionGap)
                    }

                    if !categoryRanks.isEmpty {
                        topRanksSection
                            .padding(.bottom, PublicProfileMetrics.sectionGap)
                    }

                    recentRatingsSection
                }
            }
            .padding(.horizontal, PublicProfileMetrics.screenGutter)
            .padding(.bottom, PublicProfileMetrics.scrollBottomInset)
        }
        .scrollIndicators(.hidden)
        .background(Color.feedCanvasSand)
        .task { await load() }
    }

    // MARK: - Chrome

    private var sheetDragHandle: some View {
        Capsule()
            .fill(Color.feedCanvasConcrete.opacity(0.35))
            .frame(width: 40, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 8)
    }

    private var headerChrome: some View {
        HStack {
            Button {
                session.dismissDetailSheet()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.feedCanvasInk)
                    .frame(width: 40, height: 40)
                    .background(Color.feedCanvasCard)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()

            Text(usernameHandle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            Menu {
                Button("Report user", role: .destructive) {}
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.feedCanvasInk)
                    .frame(width: 40, height: 40)
                    .background(Color.feedCanvasCard)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
            }
        }
    }

    // MARK: - Hero

    private func profileHero(_ profile: UserProfileResponse) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    avatarView(profile)
                    if !ratings.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.feedCanvasSand)
                            .background(Circle().fill(Color.feedCanvasOcean).padding(2))
                            .offset(x: 4, y: 4)
                    }
                }

                Text(profile.displayName)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)

                if !ratings.isEmpty {
                    HStack(spacing: 6) {
                        PalmTreeShape()
                            .fill(Color.feedCanvasOcean)
                            .frame(width: 14, height: 16)
                        Text("Verified Local")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .textCase(.uppercase)
                            .tracking(0.8)
                    }
                    .foregroundStyle(Color.feedCanvasOcean)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.feedCanvasSky.opacity(0.2))
                    .clipShape(Capsule())
                }

                if !profile.bio.isEmpty {
                    Text(profile.bio)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasInk.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 280)
                } else if !profile.homeCity.isEmpty {
                    Text(profile.homeCity)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasConcrete)
                }

                statsRow

                followButton(displayName: profile.displayName)
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func avatarView(_ profile: UserProfileResponse) -> some View {
        Group {
            if let urlString = profile.avatarURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        DefaultAvatarView(variant: .forUser(userID), size: PublicProfileMetrics.avatarSize)
                    }
                }
            } else {
                DefaultAvatarView(variant: .forUser(userID), size: PublicProfileMetrics.avatarSize)
            }
        }
        .frame(width: PublicProfileMetrics.avatarSize, height: PublicProfileMetrics.avatarSize)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.feedCanvasCard, lineWidth: 4))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statColumn(value: "\(ratings.count)", label: "Ratings")
            divider
            statColumn(value: isFriend ? "1" : "0", label: "Followers")
            divider
            statColumn(value: "0", label: "Following")
        }
        .padding(.vertical, 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.feedCanvasInk.opacity(0.1))
            .frame(width: 1, height: 32)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private func followButton(displayName: String) -> some View {
        Button {
            Task { await toggleFriend() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isFriend ? "checkmark" : "person.badge.plus")
                    .font(.system(size: 18, weight: .semibold))
                Text(followButtonTitle(firstName: displayName.components(separatedBy: " ").first ?? displayName))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color.feedCanvasSand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isFriend ? Color.feedCanvasOcean.opacity(0.7) : Color.feedCanvasInk)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(friendRequestSent && !isFriend)
    }

    private func followButtonTitle(firstName: String) -> String {
        if isFriend { return "Friends" }
        if friendRequestSent { return "Request Sent" }
        return "Follow \(firstName)"
    }

    // MARK: - Taste match

    private func tasteMatchCard(percent: Int, categories: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Taste Match")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                Spacer()
                Text("\(percent)%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasOcean)
            }

            Text("You and \(profile?.displayName.components(separatedBy: " ").first ?? "them") have similar tastes in \(categories.joined(separator: " and "))!")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: -10) {
                ForEach(Array(categories.enumerated()), id: \.offset) { index, cat in
                    Circle()
                        .fill(Color.feedCanvasSky.opacity(0.35))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: categoryIcon(cat))
                                .font(.system(size: 16))
                                .foregroundStyle(Color.feedCanvasOcean)
                        }
                        .overlay(Circle().stroke(Color.feedCanvasSand, lineWidth: 2))
                        .zIndex(Double(categories.count - index))
                }
                if ratings.count > categories.count {
                    Circle()
                        .fill(Color.feedCanvasSky)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Text("+\(max(0, ratings.count - categories.count))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .overlay(Circle().stroke(Color.feedCanvasSand, lineWidth: 2))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.feedCanvasCard.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.feedCanvasCard.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Top ranks

    private var topRanksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(profile?.displayName.components(separatedBy: " ").first ?? "Their")'s Top Ranks")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(categoryRanks.prefix(6)) { rank in
                        PublicProfileCategoryCard(rank: rank)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal, -PublicProfileMetrics.screenGutter)
            .padding(.leading, PublicProfileMetrics.screenGutter)
        }
    }

    // MARK: - Recent ratings

    private var recentRatingsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Recent Ratings")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .padding(.top, 8)

            if ratings.isEmpty {
                Text("No public ratings yet.")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasConcrete)
            } else {
                ForEach(Array(ratings.prefix(12).enumerated()), id: \.element.id) { index, rating in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.feedCanvasInk.opacity(0.05))
                            .frame(height: 1)
                    }
                    PublicProfileRatingRow(rating: rating) {
                        session.presentPlaceDetail(rating.placeID)
                    }
                }
            }
        }
        .padding(.horizontal, PublicProfileMetrics.recentCardInset)
        .padding(.vertical, PublicProfileMetrics.recentCardInset + 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.feedCanvasCard)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: PublicProfileMetrics.recentTopRadius,
                bottomLeadingRadius: PublicProfileMetrics.recentBottomRadius,
                bottomTrailingRadius: PublicProfileMetrics.recentBottomRadius,
                topTrailingRadius: PublicProfileMetrics.recentTopRadius
            )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: -4)
    }

    private var loadingBody: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.feedCanvasHeroPlaceholder)
                .frame(width: 112, height: 112)
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.feedCanvasHeroPlaceholder)
                .frame(height: 120)
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.feedCanvasHeroPlaceholder)
                .frame(height: 200)
        }
    }

    // MARK: - Data

    private func categoryIcon(_ category: String) -> String {
        let c = category.lowercased()
        if c.contains("coffee") { return "cup.and.saucer.fill" }
        if c.contains("taco") || c.contains("mex") || c.contains("burger") { return "fork.knife" }
        if c.contains("drink") || c.contains("marg") { return "wineglass.fill" }
        return "star.fill"
    }

    private func toggleFriend() async {
        guard !isFriend, !friendRequestSent else { return }
        do {
            try await session.api.sendFriendRequest(userID: userID)
            friendRequestSent = true
            session.showSuccess("Friend request sent")
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let profileTask = session.api.userProfile(id: userID)
            async let ratingsTask = session.api.userRatings(id: userID)
            async let myRatingsTask = session.api.myRatings()
            async let friendsTask = session.api.friends()
            profile = try await profileTask
            ratings = try await ratingsTask
            myRatings = (try? await myRatingsTask) ?? []
            let friends = (try? await friendsTask) ?? []
            isFriend = friends.contains { $0.userID == userID && $0.status == "accepted" }
            friendRequestSent = friends.contains { $0.userID == userID && $0.status == "pending" }
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}

// MARK: - Canvas components (same file)

private enum PublicProfileMetrics {
    static let screenGutter: CGFloat = 20
    static let sectionGap: CGFloat = 32
    static let avatarSize: CGFloat = 112
    static let scrollBottomInset: CGFloat = 32
    static let recentTopRadius: CGFloat = 40
    static let recentBottomRadius: CGFloat = 32
    static let recentCardInset: CGFloat = 24
}

private struct PublicProfileCategoryRank: Identifiable {
    let id: String
    let category: String
    let ratingsCount: Int
    let topPlaceName: String
    let topScore: Double
}

private struct PublicProfileCategoryCard: View {
    let rank: PublicProfileCategoryRank

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: categoryIcon)
                .font(.system(size: 20))
                .foregroundStyle(Color.feedCanvasOcean)
                .frame(width: 40, height: 40)
                .background(Color.feedCanvasSky.opacity(0.2))
                .clipShape(Circle())
                .padding(.bottom, 12)

            Text(displayCategory)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .lineLimit(1)

            Text("\(rank.ratingsCount) spots rated")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk.opacity(0.5))
                .padding(.top, 4)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text("#1 Spot")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk.opacity(0.4))
                    .textCase(.uppercase)
                Text(rank.topPlaceName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                    .lineLimit(2)
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.feedCanvasInk.opacity(0.05))
                    .frame(height: 1)
            }
        }
        .padding(16)
        .frame(width: 140, alignment: .leading)
        .background(Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
    }

    private var displayCategory: String {
        rank.category.capitalized
    }

    private var categoryIcon: String {
        let c = rank.category.lowercased()
        if c.contains("coffee") || c.contains("latte") { return "cup.and.saucer.fill" }
        if c.contains("burger") || c.contains("taco") { return "fork.knife" }
        if c.contains("marg") || c.contains("drink") { return "wineglass.fill" }
        return "star.fill"
    }
}

private struct PublicProfileRatingRow: View {
    let rating: RatingResponse
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                thumbnail
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rating.placeName ?? "Place")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.feedCanvasInk)
                                .multilineTextAlignment(.leading)
                            Text(subtitle)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.feedCanvasInk.opacity(0.5))
                        }
                        Spacer(minLength: 8)
                        scoreChip
                    }
                    if !rating.notes.isEmpty {
                        Text("\"\(rating.notes)\"")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.feedCanvasInk.opacity(0.8))
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var subtitle: String {
        let item = rating.itemName ?? (rating.itemCategory ?? "Rating").capitalized
        return "\(item)"
    }

    private var scoreChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: 0xFACC15))
            Text(String(format: "%.1f", rating.score))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.feedCanvasSand)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var thumbnail: some View {
        Group {
            if let urlStr = rating.photoURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.feedCanvasHeroPlaceholder
                    }
                }
            } else {
                Color.feedCanvasHeroPlaceholder
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
