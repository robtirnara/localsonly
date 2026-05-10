import SwiftUI

struct ExploreScreen: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = ExploreViewModel()
    @State private var showingSuggestSheet = false
    @State private var categoryFilter: String = "all"
    @State private var searchMode: SearchMode = .places
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
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        searchBar

                        Picker("Search mode", selection: $searchMode) {
                            ForEach(SearchMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, Spacing.md)

                        CategoryFilterStrip(selected: $categoryFilter)

                        if !vm.neighborhoodFilters.isEmpty && !vm.places.isEmpty {
                            neighborhoodPills
                        }

                        if vm.isLoading {
                            LazyVGrid(columns: gridColumns, spacing: Spacing.md) {
                                ForEach(0..<4, id: \.self) { _ in
                                    ImageTileShimmer()
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        } else if searchMode == .items && !itemResults.isEmpty {
                            itemResultsGrid
                        } else if searchMode == .places && !vm.places.isEmpty {
                            searchResultsGrid
                        } else if vm.hasSearched || (searchMode == .items && !itemResults.isEmpty) {
                            EmptyStateView(
                                title: "No results found",
                                message: searchMode == .items
                                    ? "Try a different item like \"matcha\" or \"taco\"."
                                    : "Try a different search or add a new place.",
                                icon: "magnifyingglass"
                            )
                            .padding(.horizontal, Spacing.md)
                        } else {
                            if !neighborhoods.isEmpty {
                                neighborhoodsGrid
                            }

                            if !filteredTrending.isEmpty {
                                trendingSection
                            } else if neighborhoods.isEmpty {
                                EmptyStateView(
                                    title: "Find your local spots",
                                    message: "Search by place name or item to discover the best spots.",
                                    icon: "magnifyingglass"
                                )
                                .padding(.horizontal, Spacing.md)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }
                .background(Color.coastalSand)
                .navigationDestination(for: UUID.self) { placeID in
                    PlaceDetailScreen(placeID: placeID)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 8) {
                            PalmTreeShape()
                                .fill(Color.coastalInk)
                                .frame(width: 26, height: 30)
                            Text("localsonly")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.coastalInk)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            session.selectedTab = .map
                        } label: {
                            Image(systemName: "map.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.coastalAqua)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                        }
                        .accessibilityLabel("Open map")
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        showingSuggestSheet = true
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                            Text("Add Place")
                                .font(.captionCopy)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.coastalInk)
                        .clipShape(Capsule())
                        .shadow(color: Color.coastalInk.opacity(0.35), radius: 12, y: 6)
                    }
                    .padding(Spacing.lg)
                }
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

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.xs) {
            TextField(searchMode == .items ? "Search items (e.g. matcha)" : "Search tacos, coffee, vibey spots…", text: $vm.query)
                .foregroundStyle(Color.coastalTextPrimary)
                .onSubmit {
                    if searchMode == .items {
                        Task { await runItemSearch() }
                    } else {
                        Task { await runSearch() }
                    }
                }
                .padding()
                .background(Color.coastalCard)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                if searchMode == .items {
                    Task { await runItemSearch() }
                } else {
                    Task { await runSearch() }
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.coastalAqua)
                    .frame(width: 44, height: 44)
                    .background(Color.coastalCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Neighborhood Pills

    private var neighborhoodPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(vm.neighborhoodFilters, id: \.self) { hood in
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
                NavigationLink(value: item.placeID) {
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(item.itemName)
                                    .font(.cardTitle)
                                    .foregroundStyle(Color.coastalTextPrimary)
                                Text("\(item.placeName) · \(item.category.capitalized)")
                                    .font(.captionCopy)
                                    .foregroundStyle(Color.coastalTextSecondary)
                                if let hood = item.neighborhood {
                                    Text(hood)
                                        .font(.microLabel)
                                        .foregroundStyle(Color.coastalSand)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                                Text(String(format: "%.1f", item.averageScore))
                                    .font(.sectionTitle)
                                    .foregroundStyle(Color.scoreColor(for: item.averageScore))
                                Text("\(item.ratingsCount) ratings")
                                    .font(.microLabel)
                                    .foregroundStyle(Color.coastalTextSecondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Trending

    private var filteredTrending: [PopularPlaceResponse] {
        guard categoryFilter != "all" else { return vm.trending }
        return vm.trending.filter { item in
            let cat = item.category.lowercased()
            let name = item.placeName.lowercased()
            switch categoryFilter {
            case "food": return cat == "food" || cat == "both"
            case "drink": return cat == "drink" || cat == "both"
            case "coffee": return cat.contains("coffee") || cat.contains("cafe")
            case "seafood":
                return name.contains("fish") || name.contains("poke") || name.contains("seafood")
                    || name.contains("sushi") || cat.contains("seafood")
            default: return true
            }
        }
    }

    private var rankedTrending: [PopularPlaceResponse] {
        filteredTrending.sorted { $0.averageScore > $1.averageScore }
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.coastalCoral)
                    Text("Trending nearby")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.coastalInk)
                }
                Spacer()
                Text("Updated Today")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.coastalTextSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, Spacing.md)

            LazyVStack(spacing: Spacing.sm) {
                ForEach(Array(rankedTrending.enumerated()), id: \.element.id) { index, item in
                    ExploreRankRowPopular(rank: index + 1, item: item)
                }
            }
            .padding(.horizontal, Spacing.md)
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
            try await vm.loadTrending(using: session.api)
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

private struct ExploreRankRowPopular: View {
    let rank: Int
    let item: PopularPlaceResponse

    var body: some View {
        NavigationLink(value: item.placeID) {
            HStack(alignment: .center, spacing: 12) {
                rankGlyph
                thumbnail
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(item.placeName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.coastalInk)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        scorePill(item.averageScore)
                    }
                    Text(metaLine)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.coastalTextSecondary)
                    Text("“\(pullQuote)”")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.coastalTextPrimary.opacity(0.88))
                        .lineLimit(2)
                }
            }
            .padding(12)
            .background(Color.coastalCard)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.orange.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.coastalInk.opacity(0.04), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var metaLine: String {
        [item.neighborhood, flair(item.category)].compactMap { $0 }.joined(separator: " · ")
    }

    private func flair(_ cat: String) -> String {
        switch cat.lowercased() {
        case "food": return "🍽 Local eats"
        case "drink": return "🍹 Drinks"
        case "both": return "Food & drink"
        default:
            if cat.lowercased().contains("coffee") { return "☕️ Coffee" }
            return cat.capitalized
        }
    }

    private var pullQuote: String {
        let avg = String(format: "%.1f", item.averageScore)
        return "Held at \(avg) across \(item.ratingsCount) ratings."
    }

    @ViewBuilder
    private var rankGlyph: some View {
        if rank <= 3 {
            Text("#\(rank)")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Color.white)
                .frame(width: 48, height: 48)
                .background(rankAccent)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        } else {
            Text("\(rank)")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(Color.coastalTextSecondary.opacity(0.55))
                .frame(width: 22)
        }
    }

    private var rankAccent: Color {
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
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.coastalInk)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
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
        .frame(width: rank <= 3 ? 96 : 72, height: rank <= 3 ? 96 : 72)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
