import SwiftUI

struct ExploreScreen: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = ExploreViewModel()
    @State private var showingSuggestSheet = false
    @State private var categoryFilter: String = "food"
    @State private var searchMode: SearchMode = .items
    @State private var itemResults: [ItemSearchResponse] = []
    @State private var neighborhoods: [NeighborhoodResponse] = []

    enum SearchMode: String, CaseIterable {
        case places = "Places"
        case items = "Items"
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.coastalSand
                    .ignoresSafeArea()

                ScrollView {
                    contentBody
                        .padding(.top, 148)
                        .padding(.bottom, Spacing.lg + Spacing.tabBarScrollBottomInset)
                }
                .scrollIndicators(.hidden)

                ranksHeader
            }
                .navigationDestination(for: UUID.self) { placeID in
                    PlaceDetailScreen(placeID: placeID)
                }
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $showingSuggestSheet) {
                    suggestSheet
                        .presentationDetents([.medium])
                        .presentationBackground(Color.coastalBackground)
                }
        }
        .task {
            await loadTrending()
            await loadNeighborhoods()
        }
        .onChange(of: categoryFilter) { _, _ in
            Task { await loadTrending() }
        }
        .onChange(of: vm.query) { _, newValue in
            if searchMode == .places {
                vm.debounceSearch(using: session.api)
            } else {
                debounceItemSearch()
            }
        }
        .onChange(of: searchMode) { _, _ in
            if !vm.query.isEmpty {
                if searchMode == .places {
                    Task { try? await vm.search(using: session.api) }
                } else {
                    Task { await runItemSearch() }
                }
            }
        }
    }

    private var contentBody: some View {
        VStack(spacing: Spacing.md) {
            if vm.isLoading {
                LazyVGrid(columns: gridColumns, spacing: Spacing.md) {
                    ForEach(0..<4, id: \.self) { _ in
                        ImageTileShimmer()
                    }
                }
                .padding(.horizontal, 20)
            } else if searchMode == .items && !itemResults.isEmpty {
                itemResultsGrid
            } else if searchMode == .places && !vm.places.isEmpty {
                if !vm.neighborhoodFilters.isEmpty {
                    neighborhoodPills
                }
                searchResultsGrid
            } else if vm.hasSearched || (searchMode == .items && !itemResults.isEmpty) {
                EmptyStateView(
                    title: "No results found",
                    message: searchMode == .items
                        ? "Try a different item like \"matcha\" or \"taco\"."
                        : "Try a different search or add a new place.",
                    icon: "magnifyingglass"
                )
                .padding(.horizontal, 20)
            } else if !vm.filteredTrendingItems.isEmpty {
                VStack(spacing: Spacing.sm) {
                    if !vm.trendingNeighborhoodFilters.isEmpty {
                        trendingNeighborhoodPills
                    }
                    trendingSection
                }
            } else {
                EmptyStateView(
                    title: "Find your local spots",
                    message: "Search dishes, drinks, or switch to Places to find a venue.",
                    icon: "magnifyingglass"
                )
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, Spacing.md)
    }

    private var ranksHeader: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.md) {
                HStack {
                    HStack(spacing: Spacing.xs) {
                        PalmTreeShape()
                            .fill(Color.coastalInk)
                            .frame(width: 24, height: 28)
                        Text("The Local List")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .tracking(-0.6)
                            .foregroundStyle(Color.coastalInk)
                    }

                    Spacer()

                    Button {
                        session.selectedTab = .map
                    } label: {
                        Image(systemName: "map")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.coastalAqua)
                            .frame(width: 40, height: 40)
                            .background(Color.coastalFoam)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
                    }
                    .accessibilityLabel("Open map")
                }
                .padding(.leading, 4)

                searchBar
            }
            .padding(.top, 14)
            .padding(.horizontal, 20)
            .padding(.bottom, Spacing.md)
            .background(Color.coastalSand.opacity(0.95))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.orange.opacity(0.05))
                    .frame(height: 2)
            }

            rankCategoryStrip
                .background(Color.coastalSand.opacity(0.95))
                .shadow(color: .black.opacity(0.02), radius: 10, y: 4)
        }
        .background(Color.coastalSand.opacity(0.95))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.gray.opacity(0.75))

                TextField(searchMode == .items ? "Tacos, matcha, pancakes…" : "Search place name…", text: $vm.query)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.coastalTextPrimary)
                    .onSubmit {
                        if searchMode == .items {
                            Task { await runItemSearch() }
                        } else {
                            Task { await runSearch() }
                        }
                    }
            }
            .padding(.leading, Spacing.md)
            .padding(.trailing, Spacing.sm)
            .padding(.vertical, 13)
            .background(Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.03), radius: 1, y: 1)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    searchMode = searchMode == .places ? .items : .places
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.gray.opacity(0.85))
                    .frame(width: 48, height: 46)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.gray.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
            }
            .accessibilityLabel("Toggle search mode")
        }
    }

    private var rankCategoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                categoryButton(id: "food", icon: "fork.knife", title: "Top Eats")
                categoryButton(id: "coffee", icon: "cup.and.saucer.fill", title: "Surf Coffee")
                categoryButton(id: "drink", icon: "wineglass.fill", title: "Tiki Bars")
                categoryButton(id: "seafood", icon: "fish.fill", title: "Seafood")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, Spacing.sm)
        }
    }

    private func categoryButton(id: String, icon: String, title: String) -> some View {
        let isSelected = categoryFilter == id
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                categoryFilter = id
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isSelected ? Color.white : Color.gray.opacity(0.82))
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.coastalInk : Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.gray.opacity(isSelected ? 0 : 0.10), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.coastalInk.opacity(0.20) : .black.opacity(0.04), radius: isSelected ? 6 : 3, y: isSelected ? 3 : 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Neighborhood Pills

    private var neighborhoodPills: some View {
        neighborhoodPillsScroll(filters: vm.neighborhoodFilters)
    }

    private var trendingNeighborhoodPills: some View {
        neighborhoodPillsScroll(filters: vm.trendingNeighborhoodFilters)
    }

    private func neighborhoodPillsScroll(filters: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(filters, id: \.self) { hood in
                    Button {
                        vm.selectedNeighborhood = vm.selectedNeighborhood == hood ? nil : hood
                    } label: {
                        Text(hood)
                            .font(.captionCopy)
                            .foregroundStyle(vm.selectedNeighborhood == hood ? .white : Color.coastalAqua)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(vm.selectedNeighborhood == hood ? Color.coastalAqua : Color.coastalAqua.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Neighborhoods Grid

    private var neighborhoodsGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Neighborhoods")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)
                .padding(.horizontal, Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(neighborhoods, id: \.neighborhood) { hood in
                        Button {
                            vm.query = ""
                            vm.selectedNeighborhood = hood.neighborhood
                            Task {
                                vm.places = try await session.api.searchPlaces(query: "")
                                vm.hasSearched = true
                                vm.selectedNeighborhood = hood.neighborhood
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                ZStack(alignment: .bottomLeading) {
                                    if let coverURL = hood.coverPhotoURL, let url = URL(string: coverURL) {
                                        AsyncImage(url: url) { phase in
                                            if case .success(let image) = phase {
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } else {
                                                PlaceholderHeroView(category: "general", height: 80)
                                            }
                                        }
                                    } else {
                                        PlaceholderHeroView(category: "general", height: 80)
                                    }
                                }
                                .frame(width: 140, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                Text(hood.neighborhood)
                                    .font(.cardTitle)
                                    .foregroundStyle(Color.coastalTextPrimary)
                                    .lineLimit(1)
                                Text("\(hood.placeCount) places")
                                    .font(.microLabel)
                                    .foregroundStyle(Color.coastalTextSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }

    // MARK: - Search Results Grid

    private var searchResultsGrid: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(Array(vm.filteredPlaces.enumerated()), id: \.element.id) { index, place in
                ExploreRankSearchRow(rank: index + 1, place: place)
                    .contextMenu {
                        Button {
                            session.selectedPlace = place
                            session.selectedTab = .rate
                            session.showInfo("Place selected. Log your visit.")
                        } label: {
                            Label("Rate this place", systemImage: "plus.circle")
                        }
                        Button {
                            Task { await session.toggleBookmark(placeID: place.id) }
                        } label: {
                            Label(
                                session.bookmarkedPlaceIDs.contains(place.id) ? "Remove Bookmark" : "Save Place",
                                systemImage: session.bookmarkedPlaceIDs.contains(place.id) ? "bookmark.slash" : "bookmark"
                            )
                        }
                    }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Item Results Grid

    private var itemResultsGrid: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(itemResults) { item in
                ExploreItemRankRow(rank: nil, item: item)
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Trending

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.coastalCoral)
                        .font(.system(size: 20, weight: .bold))
                    Text("Trending nearby")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.coastalInk)
                }
                Spacer()
                Text("Updated Today")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.gray.opacity(0.75))
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.10))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, Spacing.xs)

            LazyVStack(spacing: Spacing.md) {
                ForEach(Array(vm.filteredTrendingItems.enumerated()), id: \.element.id) { index, item in
                    ExploreItemRankRow(rank: index + 1, item: item)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Suggest Sheet

    private var suggestSheet: some View {
        VStack(spacing: Spacing.md) {
            Text("Suggest a place")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)

            TextField("Place name", text: $vm.suggestName)
                .foregroundStyle(Color.coastalTextPrimary)
                .padding()
                .background(Color.coastalCard)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            TextField("Neighborhood (optional)", text: $vm.suggestNeighborhood)
                .foregroundStyle(Color.coastalTextPrimary)
                .padding()
                .background(Color.coastalCard)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Picker("Category", selection: $vm.suggestCategory) {
                Text("food").tag("food")
                Text("drink").tag("drink")
                Text("both").tag("both")
            }
            .pickerStyle(.segmented)

            PrimaryButton(title: "Create place", isLoading: vm.isSuggesting) {
                Task {
                    do {
                        let place = try await vm.suggestPlace(using: session.api)
                        session.selectedPlace = place
                        session.showSuccess("Created \(place.name)")
                        showingSuggestSheet = false
                    } catch {
                        session.showError(error.localizedDescription)
                    }
                }
            }
        }
        .padding(Spacing.lg)
    }

    // MARK: - Helpers

    private func runSearch() async {
        do {
            try await vm.search(using: session.api)
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func loadTrending() async {
        do {
            try await vm.loadTrending(using: session.api, dishFilter: categoryFilter)
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func loadNeighborhoods() async {
        do {
            neighborhoods = try await session.api.listNeighborhoods()
        } catch {}
    }

    @State private var itemSearchTask: Task<Void, Never>?

    private func debounceItemSearch() {
        itemSearchTask?.cancel()
        let q = vm.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            itemResults = []
            return
        }
        itemSearchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await runItemSearch()
        }
    }

    private func runItemSearch() async {
        let q = vm.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        do {
            itemResults = try await session.api.searchByItem(query: q)
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}

private struct ExploreItemRankRow: View {
    /// When non-nil, shows Local List rank styling (badges for top 3).
    let rank: Int?
    let item: ItemSearchResponse

    var body: some View {
        NavigationLink(value: item.placeID) {
            ZStack(alignment: .topLeading) {
                HStack(alignment: .center, spacing: Spacing.md) {
                    if let rank, rank > 3 {
                        Text("\(rank)")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.gray.opacity(0.72))
                            .frame(width: 24)
                            .padding(.trailing, -Spacing.xs)
                    }

                    thumbnail

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top, spacing: Spacing.xs) {
                            Text(item.itemName)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.coastalInk)
                                .lineSpacing(0)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                            Spacer(minLength: Spacing.xs)
                            scorePill(item.averageScore)
                        }

                        Text(item.placeName)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.gray.opacity(0.72))
                            .padding(.top, 2)

                        Text(locationLine)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.gray.opacity(0.65))
                            .padding(.top, 2)

                        Text("\"\(pullQuote)\"")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.gray.opacity(0.88))
                            .lineSpacing(2)
                            .lineLimit(2)
                            .padding(.top, Spacing.xs)
                    }
                }
                .padding(Spacing.sm)

                if let rank, rank <= 3 {
                    Text("#\(rank)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .frame(width: 48, height: 48, alignment: .bottomTrailing)
                        .padding(.trailing, Spacing.xs)
                        .padding(.bottom, Spacing.xs)
                        .background(rankAccent(rank))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.14), radius: 4, y: 2)
                        .offset(x: -16, y: -16)
                        .zIndex(1)
                }
            }
            .background(Color.coastalCard)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.orange.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.coastalInk.opacity(0.04), radius: 20, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var locationLine: String {
        item.neighborhood ?? "Nearby"
    }

    private var pullQuote: String {
        let avg = String(format: "%.1f", item.averageScore)
        return "\(avg) from \(item.ratingsCount) local ratings · \(item.placeName)."
    }

    private func rankAccent(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 0.96, green: 0.82, blue: 0.25)
        case 2: return Color(red: 0.78, green: 0.78, blue: 0.78)
        default: return Color.coastalCoral
        }
    }

    private func scorePill(_ score: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.yellow.opacity(0.95))
            Text(String(format: "%.1f", score))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.coastalInk)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }

    private var thumbnail: some View {
        Group {
            if let urlString = item.coverPhotoURL, let u = URL(string: urlString) {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Color.coastalFoam
                            .overlay(Image(systemName: "fork.knife").foregroundStyle(Color.coastalAqua))
                    }
                }
            } else {
                Color.coastalFoam
                    .overlay(Image(systemName: "fork.knife").foregroundStyle(Color.coastalAqua))
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }
}

private struct ExploreRankSearchRow: View {
    let rank: Int
    let place: PlaceResponse

    var body: some View {
        NavigationLink(value: place.id) {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.coastalTextSecondary)
                    .frame(width: 22, alignment: .center)
                thumbnail
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.coastalTextPrimary)
                    Text(place.neighborhood ?? place.city)
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalTextSecondary)
                }
                Spacer(minLength: 8)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.coastalCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.orange.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var thumbnail: some View {
        Group {
            if let urlString = place.coverPhotoURL, let u = URL(string: urlString) {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Color.coastalFoam
                    }
                }
            } else {
                Color.coastalFoam
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
