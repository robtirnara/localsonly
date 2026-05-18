import SwiftUI

/// `saved` canvas — header, filter pills, playlists carousel, stash-only search, bookmark rows.
struct SavedPlacesScreen: View {
    var embedded: Bool = false

    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var bookmarks: [BookmarkedPlaceResponse] = []
    @State private var isLoading = true
    @State private var stashFilter: StashFilter = .allSaved
    @State private var isSavedSearchActive = false
    @State private var savedSearchQuery = ""

    private enum StashFilter: String, CaseIterable {
        case allSaved = "All Saved"
        case wantToGo = "Want to Go"
        case collections = "Collections"
        case favorites = "Favorites"
    }

    private var showsCollections: Bool {
        stashFilter == .allSaved || stashFilter == .collections
    }

    private var showsBookmarks: Bool {
        stashFilter == .allSaved || stashFilter == .favorites
    }

    private var visibleBookmarks: [BookmarkedPlaceResponse] {
        bookmarks.filter { place in
            guard isSavedSearchActive else { return true }
            return place.matchesSavedStashSearch(savedSearchQuery)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SavedCanvasMetrics.sectionGap) {
                    filterPills
                        .padding(.top, Spacing.xxs)

                    if showsCollections && !isSavedSearchActive {
                        curatedPlaylistsSection
                    }

                    if showsBookmarks || isSavedSearchActive {
                        recentlySavedSection
                    } else if stashFilter == .wantToGo {
                        wantToGoEmptyState
                    } else if stashFilter == .collections {
                        collectionsOnlyHint
                    }
                }
                .padding(.horizontal, SavedCanvasMetrics.horizontalPadding)
                .padding(.bottom, embedded ? Spacing.tabBarScrollBottomInset : Spacing.md)
            }
            .scrollIndicators(.hidden)
            .background(Color.feedCanvasSand)
            .refreshable { await load() }
            .safeAreaInset(edge: .top, spacing: 0) {
                stashHeaderChrome
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .overlay(alignment: .topLeading) {
            if !embedded {
                Button("Done") { dismiss() }
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasOcean)
                    .padding(.leading, SavedCanvasMetrics.headerHorizontalPadding)
                    .padding(.top, 8)
            }
        }
        .task { await load() }
    }

    private var stashHeaderChrome: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 6) {
                PalmTreeShape()
                    .fill(Color.feedCanvasOcean)
                    .frame(width: 24, height: 28)

                HStack(spacing: 0) {
                    Text("localsonly")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.feedCanvasInk)
                        .textCase(.lowercase)
                    Text(".")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.feedCanvasSky)
                }

                Spacer(minLength: 8)

                headerIconButton(systemName: "magnifyingglass") {
                    if isSavedSearchActive {
                        closeSavedSearch()
                    } else {
                        isSavedSearchActive = true
                    }
                }
                .accessibilityLabel(isSavedSearchActive ? "Close stash search" : "Search your stash")

                headerIconButton(systemName: "plus.circle") {
                    session.selectedTab = .rate
                }
            }

            if isSavedSearchActive {
                SavedStashSearchField(text: $savedSearchQuery) {
                    closeSavedSearch()
                }
            } else {
                Text("Your Stash")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                    .tracking(-0.5)
            }
        }
        .padding(.horizontal, SavedCanvasMetrics.headerHorizontalPadding)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.feedCanvasSand.opacity(0.88))
        }
    }

    private func headerIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.feedCanvasOcean)
                .frame(width: 40, height: 40)
                .background(Color.feedCanvasCard)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StashFilter.allCases, id: \.self) { filter in
                    SavedFilterPill(title: filter.rawValue, isSelected: stashFilter == filter) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stashFilter = filter
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var curatedPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                Text("Curated Playlists")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                Spacer(minLength: 8)
                Button {} label: {
                    HStack(spacing: 2) {
                        Text("View all")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Color.feedCanvasSky)
                }
                .disabled(true)
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    SavedCollectionCarouselCard(
                        title: "Sunset Sips",
                        subtitle: "8 spots",
                        imageURL: "https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&q=80&w=400"
                    )
                    SavedCollectionCarouselCard(
                        title: "Post-Surf Bites",
                        subtitle: "12 spots • Private",
                        imageURL: "https://images.unsplash.com/photo-1565299507177-b0ac66763828?auto=format&fit=crop&q=80&w=400",
                        showsLock: true
                    )
                    SavedCollectionCarouselCard(isPlaceholder: true)
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, -SavedCanvasMetrics.horizontalPadding)
            .padding(.leading, SavedCanvasMetrics.horizontalPadding)
        }
    }

    private var recentlySavedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(isSavedSearchActive ? "Search results" : "Recently Saved")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                Rectangle()
                    .fill(Color.feedCanvasOcean.opacity(0.1))
                    .frame(height: 1)
            }
            .padding(.horizontal, 4)

            if isLoading {
                VStack(spacing: SavedCanvasMetrics.rowGap) {
                    ForEach(0..<3, id: \.self) { _ in savedRowShimmer }
                }
            } else if bookmarks.isEmpty {
                savedBookmarksEmptyState
            } else if visibleBookmarks.isEmpty {
                savedSearchNoResultsState
            } else {
                VStack(spacing: SavedCanvasMetrics.rowGap) {
                    ForEach(visibleBookmarks) { place in
                        ZStack(alignment: .topTrailing) {
                            Button {
                                session.presentPlaceDetail(place.id)
                            } label: {
                                SavedSpotRow(place: place)
                            }
                            .buttonStyle(.plain)

                            Button {
                                Task { await removeBookmark(place.id) }
                            } label: {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Color.feedCanvasSky)
                                    .padding(6)
                                    .background(.ultraThinMaterial)
                                    .background(Color.feedCanvasCard.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.borderless)
                            .padding(12)
                            .accessibilityLabel("Remove bookmark")
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await removeBookmark(place.id) }
                            } label: {
                                Label("Remove Bookmark", systemImage: "bookmark.slash")
                            }
                        }
                    }
                }
            }
        }
    }

    private var savedRowShimmer: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: SavedCanvasMetrics.thumbCorner, style: .continuous)
                .fill(Color.feedCanvasHeroPlaceholder)
                .frame(width: SavedCanvasMetrics.thumbSize, height: SavedCanvasMetrics.thumbSize)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(Color.feedCanvasHeroPlaceholder).frame(width: 120, height: 12)
                RoundedRectangle(cornerRadius: 4).fill(Color.feedCanvasHeroPlaceholder).frame(height: 18)
                RoundedRectangle(cornerRadius: 4).fill(Color.feedCanvasHeroPlaceholder).frame(width: 160, height: 14)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: SavedCanvasMetrics.cardCorner, style: .continuous))
    }

    private var savedSearchNoResultsState: some View {
        stashEmptyState(
            icon: "magnifyingglass",
            title: "No matches in your stash",
            message: "Try another name, neighborhood, or category."
        )
    }

    private var savedBookmarksEmptyState: some View {
        stashEmptyState(
            icon: "bookmark",
            title: "No saved places yet",
            message: "Tap the bookmark on any place to add it here."
        )
    }

    private var wantToGoEmptyState: some View {
        stashEmptyState(
            icon: "map",
            title: "Nothing queued",
            message: "Want-to-go lists will show here when supported."
        )
    }

    private func stashEmptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(Color.feedCanvasSky)
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
            Text(message)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasConcrete)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }

    private var collectionsOnlyHint: some View {
        Text("Playlists are curated boards — tap a card when lists are wired up.")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(Color.feedCanvasConcrete)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
    }

    private func closeSavedSearch() {
        isSavedSearchActive = false
        savedSearchQuery = ""
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            bookmarks = try await session.api.listBookmarks()
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func removeBookmark(_ placeID: UUID) async {
        do {
            try await session.api.removeBookmark(placeID: placeID)
            bookmarks.removeAll { $0.id == placeID }
            session.bookmarkedPlaceIDs.remove(placeID)
            session.showSuccess("Bookmark removed")
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}

// MARK: - Saved screen layout tokens + subviews (same file = always in app target)

private enum SavedCanvasMetrics {
    static let horizontalPadding: CGFloat = 20
    static let headerHorizontalPadding: CGFloat = 24
    static let sectionGap: CGFloat = 32
    static let rowGap: CGFloat = 16
    static let cardCorner: CGFloat = 28
    static let thumbSize: CGFloat = 96
    static let thumbCorner: CGFloat = 20
    static let collectionCardWidth: CGFloat = 168
    static let collectionOuterCorner: CGFloat = 24
    static let collectionImageCorner: CGFloat = 18
    static let beachyShadowOpacity: Double = 0.15
}

private struct SavedFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : Color.feedCanvasInk)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.feedCanvasOcean : Color.feedCanvasCard)
                .clipShape(Capsule())
                .overlay {
                    if !isSelected {
                        Capsule().stroke(Color.feedCanvasOcean.opacity(0.1), lineWidth: 1)
                    }
                }
                .shadow(
                    color: isSelected ? Color.feedCanvasOcean.opacity(0.2) : Color.black.opacity(0.05),
                    radius: isSelected ? 6 : 2,
                    y: isSelected ? 3 : 1
                )
        }
        .buttonStyle(.plain)
    }
}

private struct SavedCollectionCarouselCard: View {
    var title: String = ""
    var subtitle: String = ""
    var imageURL: String? = nil
    var showsLock: Bool = false
    var isPlaceholder: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if isPlaceholder {
                        RoundedRectangle(cornerRadius: SavedCanvasMetrics.collectionImageCorner, style: .continuous)
                            .fill(Color(hex: 0xE8F3F8))
                            .overlay {
                                Circle()
                                    .fill(Color.feedCanvasCard)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                                    .overlay {
                                        Image(systemName: "plus")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(Color.feedCanvasSky)
                                    }
                            }
                    } else if let imageURL, let url = URL(string: imageURL) {
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
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: SavedCanvasMetrics.collectionImageCorner, style: .continuous))
                .overlay {
                    if !isPlaceholder {
                        LinearGradient(
                            colors: [.clear, Color.feedCanvasOcean.opacity(0.6)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: SavedCanvasMetrics.collectionImageCorner, style: .continuous))
                    }
                }

                if showsLock {
                    Circle()
                        .fill(Color.feedCanvasSky)
                        .frame(width: 24, height: 24)
                        .overlay {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isPlaceholder ? "New Board" : title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isPlaceholder ? Color.feedCanvasOcean : Color.feedCanvasInk)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                if !isPlaceholder {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasOcean.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(width: SavedCanvasMetrics.collectionCardWidth, alignment: .topLeading)
        .background(isPlaceholder ? Color(hex: 0xE8F3F8) : Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: SavedCanvasMetrics.collectionOuterCorner, style: .continuous))
        .overlay {
            if isPlaceholder {
                RoundedRectangle(cornerRadius: SavedCanvasMetrics.collectionOuterCorner, style: .continuous)
                    .strokeBorder(Color.feedCanvasSky.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
            }
        }
        .shadow(color: Color.feedCanvasOcean.opacity(SavedCanvasMetrics.beachyShadowOpacity), radius: 12, x: 0, y: 8)
    }
}

private struct SavedSpotRow: View {
    let place: BookmarkedPlaceResponse

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            thumbnail
            VStack(alignment: .leading, spacing: 0) {
                Text(categoryLine.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasSky)
                    .tracking(0.6)
                    .padding(.bottom, 2)
                Text(place.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.feedCanvasSky)
                    Text(savedMeta)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasOcean)
                }
                .padding(.top, 4)
                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.feedCanvasSky)
                    Text("In your stash")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasOcean)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.feedCanvasSand)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.top, 8)
            }
            .padding(.vertical, 4)
            .padding(.trailing, 36)
        }
        .padding(12)
        .background(Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: SavedCanvasMetrics.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SavedCanvasMetrics.cardCorner, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.feedCanvasOcean.opacity(SavedCanvasMetrics.beachyShadowOpacity), radius: 12, x: 0, y: 8)
    }

    private var categoryLine: String {
        [place.category.capitalized, place.neighborhood ?? place.city]
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }

    private var savedMeta: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Saved \(formatter.localizedString(for: place.savedAt, relativeTo: Date()))"
    }

    @ViewBuilder
    private var thumbnail: some View {
        Group {
            if let urlString = place.coverPhotoURL, let url = URL(string: urlString) {
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
        .frame(width: SavedCanvasMetrics.thumbSize, height: SavedCanvasMetrics.thumbSize)
        .clipShape(RoundedRectangle(cornerRadius: SavedCanvasMetrics.thumbCorner, style: .continuous))
    }
}

private struct SavedStashSearchField: View {
    @Binding var text: String
    var onCancel: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.feedCanvasConcrete)
                TextField("Search your stash", text: $text)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                if !text.isEmpty {
                    Button { text = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.feedCanvasConcrete)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.feedCanvasCard)
            .clipShape(Capsule())
            .overlay { Capsule().stroke(Color.feedCanvasOcean.opacity(0.12), lineWidth: 1) }

            Button("Cancel", action: onCancel)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasOcean)
        }
        .onAppear { isFocused = true }
    }
}

private extension BookmarkedPlaceResponse {
    func matchesSavedStashSearch(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return true }
        let haystack = [name, category, neighborhood, city]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        return haystack.contains(needle)
    }
}
