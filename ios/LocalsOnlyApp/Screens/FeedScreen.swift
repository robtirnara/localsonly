import SwiftUI

struct FeedScreen: View {
    enum Segment: String, CaseIterable {
        case popular = "Popular"
        case friends = "Friends"
        case forYou = "For You"
    }

    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = FeedViewModel()
    @State private var selectedSegment: Segment = .popular
    @State private var categoryFilter: String = "all"
    @State private var showNotifications = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Picker("Feed", selection: $selectedSegment) {
                        ForEach(Segment.allCases, id: \.self) { segment in
                            Text(segment.rawValue).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.md)

                    CategoryFilterStrip(selected: $categoryFilter)

                    if vm.isLoading {
                        ForEach(0..<3, id: \.self) { _ in
                            ImageTileShimmer()
                                .padding(.horizontal, Spacing.md)
                        }
                    } else if selectedSegment == .popular {
                        popularContent
                    } else if selectedSegment == .friends {
                        friendsContent
                    } else {
                        forYouContent
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
            .refreshable {
                await loadFeed()
            }
            .navigationDestination(for: UUID.self) { placeID in
                PlaceDetailScreen(placeID: placeID)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandLockupView(compact: true)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNotifications = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .foregroundStyle(Color.coastalAqua)
                            if session.unreadNotificationCount > 0 {
                                Circle()
                                    .fill(Color.coastalCoral)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsScreen()
                    .environmentObject(session)
            }
        }
        .task {
            await loadFeed()
        }
    }

    // MARK: - Popular

    private var filteredPopular: [PopularPlaceResponse] {
        guard categoryFilter != "all" else { return vm.popular }
        return vm.popular.filter { item in
            let cat = item.category.lowercased()
            switch categoryFilter {
            case "food": return cat == "food" || cat == "both"
            case "drink": return cat == "drink" || cat == "both"
            case "coffee": return cat.contains("coffee") || cat.contains("cafe")
            default: return true
            }
        }
    }

    private var categorizedPopular: [(key: String, items: [PopularPlaceResponse])] {
        let grouped = Dictionary(grouping: filteredPopular) { item -> String in
            let cat = item.category.lowercased()
            if cat.contains("coffee") || cat.contains("cafe") { return "Coffee Spots" }
            if cat == "drink" { return "Best Drinks" }
            if cat == "food" { return "Top Eats" }
            return "Local Favorites"
        }
        let order = ["Top Eats", "Best Drinks", "Coffee Spots", "Local Favorites"]
        return order.compactMap { key in
            guard let items = grouped[key], !items.isEmpty else { return nil }
            return (key: key, items: items)
        }
    }

    @ViewBuilder
    private var popularContent: some View {
        if filteredPopular.isEmpty {
            EmptyStateView(
                title: "No popular spots yet",
                message: "Public ratings will start shaping this list.",
                icon: "star"
            )
            .padding(.horizontal, Spacing.md)
        } else if categoryFilter == "all" {
            ForEach(categorizedPopular, id: \.key) { section in
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text(section.key)
                            .font(.sectionTitle)
                            .foregroundStyle(Color.coastalTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ForEach(section.items) { item in
                                NavigationLink(value: item.placeID) {
                                    ImageTileCard(
                                        title: item.placeName,
                                        subtitle: [item.category.capitalized, item.neighborhood].compactMap { $0 }.joined(separator: " · "),
                                        imageURL: item.coverPhotoURL,
                                        category: item.category,
                                        score: item.averageScore,
                                        badgeText: "\(item.ratingsCount) ratings"
                                    )
                                    .frame(width: 180)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }
            }
        } else {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)],
                      spacing: Spacing.md) {
                ForEach(filteredPopular) { item in
                    NavigationLink(value: item.placeID) {
                        ImageTileCard(
                            title: item.placeName,
                            subtitle: [item.category.capitalized, item.neighborhood].compactMap { $0 }.joined(separator: " · "),
                            imageURL: item.coverPhotoURL,
                            category: item.category,
                            score: item.averageScore,
                            badgeText: "\(item.ratingsCount) ratings"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Friends

    @ViewBuilder
    private var friendsContent: some View {
        if vm.friendsFeed.isEmpty {
            EmptyStateView(
                title: "No friend activity yet",
                message: "Add friends to see their local finds here.",
                icon: "person.2"
            )
            .padding(.horizontal, Spacing.md)
        } else {
            LazyVStack(spacing: Spacing.md) {
                ForEach(vm.friendsFeed) { event in
                    NavigationLink(value: event.placeID) {
                        FeedPhotoCard(
                            itemName: event.itemName,
                            placeName: event.placeName,
                            actorName: event.actorDisplayName,
                            score: event.score,
                            photoURL: event.photoURL,
                            timestamp: event.createdAt
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - For You

    @ViewBuilder
    private var forYouContent: some View {
        if vm.popular.isEmpty {
            EmptyStateView(
                title: "Discovering your spots",
                message: "Rate a few places and add friends to get personalized recommendations.",
                icon: "sparkles"
            )
            .padding(.horizontal, Spacing.md)
        } else {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if !vm.friendsFeed.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Color.coastalCoral)
                                Text("Friends rated \(vm.friendsFeed.count) new spots")
                                    .font(.cardTitle)
                                    .foregroundStyle(Color.coastalTextPrimary)
                            }
                            Text("Check the Friends tab to see what they've been trying.")
                                .font(.captionCopy)
                                .foregroundStyle(Color.coastalTextSecondary)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }

                Text("Spots You Might Like")
                    .font(.sectionTitle)
                    .foregroundStyle(Color.coastalTextPrimary)
                    .padding(.horizontal, Spacing.md)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)],
                          spacing: Spacing.md) {
                    ForEach(vm.popular.prefix(8)) { item in
                        NavigationLink(value: item.placeID) {
                            ImageTileCard(
                                title: item.placeName,
                                subtitle: [item.category.capitalized, item.neighborhood].compactMap { $0 }.joined(separator: " · "),
                                imageURL: item.coverPhotoURL,
                                category: item.category,
                                score: item.averageScore,
                                badgeText: "\(item.ratingsCount) ratings"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }

    private func loadFeed() async {
        do {
            try await vm.refresh(using: session.api, signedIn: session.signedIn)
            await session.refreshNotificationCount()
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}
