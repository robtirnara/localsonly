import SwiftUI

struct ExploreScreen: View {
    private enum ExploreSurface: String, CaseIterable {
        case list = "List"
        case map = "Map"
    }

    enum SearchMode: String, CaseIterable {
        case places = "Places"
        case items = "Items"
    }

    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = ExploreViewModel()
    @State private var showingSuggestSheet = false
    @State private var categoryFilter: String = "all"
    @State private var searchMode: SearchMode = .places
    @State private var itemResults: [ItemSearchResponse] = []
    @State private var neighborhoods: [NeighborhoodResponse] = []
    @State private var exploreSurface: ExploreSurface = .list
    @State private var itemSearchTask: Task<Void, Never>?
    @State private var didCompleteItemSearch = false
    @State private var searchChromeVisible = false
    @State private var emphasizeTrending = false

    private let listHorizontalPadding: CGFloat = 16
    private let listRowSpacing: CGFloat = 16

    var body: some View {
        NavigationStack {
            Group {
                if exploreSurface == .map {
                    ZStack(alignment: .top) {
                        MapExploreView()
                            .ignoresSafeArea(edges: .bottom)
                        exploreMapHeaderChrome
                    }
                } else {
                    ScrollView {
                        contentBody
                            .padding(.horizontal, listHorizontalPadding)
                            .padding(.top, Spacing.xxs)
                            .padding(.bottom, Spacing.md + Spacing.tabBarScrollBottomInset)
                    }
                    .scrollIndicators(.hidden)
                    .background(Color.feedCanvasSand)
                    .safeAreaInset(edge: .top, spacing: 0) {
                        exploreListHeaderChrome
                    }
                }
            }
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $showingSuggestSheet) {
                    suggestSheet
                        .presentationDetents([.medium])
                        .presentationBackground(Color.coastalBackground)
                }
        }
        .task {
            await loadTopPlaces()
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

    private var showsSearchChrome: Bool {
        searchChromeVisible
            || !vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || vm.hasSearched
    }

    private var exploreSurfacePicker: some View {
        Picker("", selection: $exploreSurface) {
            ForEach(ExploreSurface.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .tint(Color.feedCanvasOcean)
    }

    private var exploreOverflowMenu: some View {
        Menu {
            Button("Find dishes (trending)") {
                searchMode = .items
                searchChromeVisible = true
            }
            Button("Search places") {
                searchMode = .places
                searchChromeVisible = true
            }
            Button("Suggest a place") {
                showingSuggestSheet = true
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.feedCanvasOcean)
                .frame(width: 40, height: 40)
                .background(Color.feedCanvasCard)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        }
        .accessibilityLabel("More explore options")
    }

    private var showTopLocalsDefault: Bool {
        !vm.hasSearched
            && vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && searchMode == .places
    }

    private var contentBody: some View {
        VStack(spacing: listRowSpacing) {
            if vm.isLoadingTopPlaces && vm.topPlaces.isEmpty {
                ForEach(0..<4, id: \.self) { _ in
                    ImageTileShimmer()
                }
            } else if vm.isLoading && vm.hasSearched {
                ForEach(0..<4, id: \.self) { _ in
                    ImageTileShimmer()
                }
            } else if searchMode == .items && !itemResults.isEmpty {
                itemResultsGrid
            } else if searchMode == .places && !vm.places.isEmpty {
                if !vm.neighborhoodFilters.isEmpty {
                    neighborhoodPills
                }
                searchResultsGrid
            } else if vm.hasSearched && searchMode == .places && vm.places.isEmpty {
                EmptyStateView(
                    title: "No results found",
                    message: "Try a different search or add a new place.",
                    icon: "magnifyingglass"
                )
            } else if searchMode == .items && didCompleteItemSearch && itemResults.isEmpty && !vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                EmptyStateView(
                    title: "No results found",
                    message: "Try a different item like \"matcha\" or \"taco\".",
                    icon: "magnifyingglass"
                )
            } else if emphasizeTrending && !vm.filteredTrendingItems.isEmpty {
                trendingSection
            } else if showTopLocalsDefault && !vm.filteredTopPlaces(category: categoryFilter).isEmpty {
                topLocalsRankedSection
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
                    message: "Browse top-ranked spots, open the map, or search from the menu.",
                    icon: "magnifyingglass"
                )
            }
        }
    }

    /// Canvas header: `Top Ranks 🌴`, category pills; List | Map + overflow kept for app IA.
    private var exploreListHeaderChrome: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text("Top Ranks 🌴")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                    .tracking(-0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 8)

                exploreSurfacePicker
                    .frame(maxWidth: 128)

                exploreOverflowMenu
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)

            if showsSearchChrome {
                searchBar
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
            }

            rankCategoryStrip
                .padding(.top, showsSearchChrome ? 8 : 12)
        }
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.feedCanvasSand.opacity(0.92))
                .ignoresSafeArea(edges: .top)
        }
    }

    private var exploreMapHeaderChrome: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text("Top Ranks 🌴")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 8)

                exploreSurfacePicker
                    .frame(maxWidth: 128)

                exploreOverflowMenu
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(Color.feedCanvasSand.opacity(0.92))
                    .ignoresSafeArea(edges: .top)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.feedCanvasConcrete)

                TextField(searchMode == .items ? "Tacos, matcha, pancakes…" : "Search place name…", text: $vm.query)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
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
            .padding(.vertical, 12)
            .background(Color.feedCanvasCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    searchMode = searchMode == .places ? .items : .places
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.feedCanvasConcrete)
                    .frame(width: 44, height: 44)
                    .background(Color.feedCanvasCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                    )
            }
            .accessibilityLabel("Toggle search mode")
        }
        .padding(.bottom, 4)
    }

    private var rankCategoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                topLocalsCategoryButton(id: "all", label: "All Spots")
                topLocalsCategoryButton(id: "food", label: "Tacos 🌮")
                topLocalsCategoryButton(id: "coffee", label: "Coffee ☕️")
                topLocalsCategoryButton(id: "drink", label: "Margs 🍹")
                topLocalsCategoryButton(id: "seafood", label: "Seafood 🐟")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    private func topLocalsCategoryButton(id: String, label: String) -> some View {
        let isSelected = categoryFilter == id
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                categoryFilter = id
                emphasizeTrending = false
            }
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : Color.feedCanvasConcrete)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.feedCanvasOcean : Color.feedCanvasCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(isSelected ? 0 : 0.05), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(isSelected ? 0.12 : 0.05),
                    radius: isSelected ? 6 : 2,
                    y: isSelected ? 3 : 1
                )
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

    private var topLocalsRankedSection: some View {
        LazyVStack(spacing: listRowSpacing) {
            ForEach(Array(vm.filteredTopPlaces(category: categoryFilter).enumerated()), id: \.element.placeID) { index, place in
                TopLocalPlaceRankRow(rank: index + 1, place: place)
            }

            ExploreHiddenGemsCard {
                emphasizeTrending = true
                searchChromeVisible = false
                vm.query = ""
                vm.hasSearched = false
                Task { await loadTrending() }
            }
            .padding(.top, 8)
        }
    }

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
    }

    // MARK: - Item Results Grid

    private var itemResultsGrid: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(itemResults) { item in
                ExploreItemRankRow(rank: nil, item: item)
            }
        }
    }

    // MARK: - Trending

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: listRowSpacing) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.feedCanvasOcean)
                        .font(.system(size: 20, weight: .bold))
                    Text("Trending nearby")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasInk)
                }
                Spacer()
                Text("Updated Today")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasConcrete)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 4)
                    .background(Color.feedCanvasSky.opacity(0.2))
                    .clipShape(Capsule())
            }

            LazyVStack(spacing: listRowSpacing) {
                ForEach(Array(vm.filteredTrendingItems.enumerated()), id: \.element.id) { index, item in
                    ExploreItemRankRow(rank: index + 1, item: item)
                }
            }
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

    private func loadTopPlaces() async {
        do {
            try await vm.loadTopPlaces(using: session.api)
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func runSearch() async {
        do {
            try await vm.search(using: session.api)
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func loadTrending() async {
        do {
            let dishFilter: String? = categoryFilter == "all" ? nil : categoryFilter
            try await vm.loadTrending(using: session.api, dishFilter: dishFilter)
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func loadNeighborhoods() async {
        do {
            neighborhoods = try await session.api.listNeighborhoods()
        } catch {}
    }

    private func debounceItemSearch() {
        itemSearchTask?.cancel()
        let q = vm.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            itemResults = []
            didCompleteItemSearch = false
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
            didCompleteItemSearch = true
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}

private struct ExploreItemRankRow: View {
    let rank: Int?
    let item: ItemSearchResponse
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        Button {
            session.presentPlaceDetail(item.placeID)
        } label: {
            ZStack(alignment: .leading) {
                if rank == 1 {
                    Color.feedCanvasSky
                        .frame(width: 8)
                }

                HStack(alignment: .center, spacing: 16) {
                    itemThumbnail

                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.itemName)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.feedCanvasInk)
                            .lineLimit(2)

                        Text(item.placeName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.feedCanvasConcrete)
                            .padding(.top, 2)
                            .padding(.bottom, 8)

                        HStack {
                            ExploreScorePill(score: item.averageScore)
                            Spacer(minLength: 8)
                            Text("\(item.ratingsCount) ratings")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.feedCanvasConcrete)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.leading, rank == 1 ? 16 : 8)
                .padding(.trailing, 24)
                .padding(.vertical, 8)
            }
            .background(Color.feedCanvasCard)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var itemThumbnail: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let urlString = item.coverPhotoURL, let url = URL(string: urlString) {
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
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            if let rank {
                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
                    .padding(4)
            }
        }
    }
}

private struct ExploreRankSearchRow: View {
    let rank: Int
    let place: PlaceResponse
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        Button {
            session.presentPlaceDetail(place.id)
        } label: {
            HStack(alignment: .center, spacing: 16) {
                ZStack(alignment: .topLeading) {
                    thumbnail
                    Text("#\(rank)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        .padding(3)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasInk)
                        .lineLimit(2)
                    Text(place.neighborhood ?? place.city)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasConcrete)
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.feedCanvasCard)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var thumbnail: some View {
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
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
