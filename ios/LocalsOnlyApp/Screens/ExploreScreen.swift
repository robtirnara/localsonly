import SwiftUI

struct ExploreScreen: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = ExploreViewModel()
    @State private var showingSuggestSheet = false
    @State private var showMap = false
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
            if showMap {
                MapExploreView()
                    .navigationTitle("Map")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: UUID.self) { placeID in
                        PlaceDetailScreen(placeID: placeID)
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showMap = false
                            } label: {
                                Image(systemName: "list.bullet")
                                    .foregroundStyle(Color.coastalAqua)
                            }
                        }
                    }
            } else {
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
                .navigationDestination(for: UUID.self) { placeID in
                    PlaceDetailScreen(placeID: placeID)
                }
                .navigationTitle("Explore")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showMap = true
                        } label: {
                            Image(systemName: "map")
                                .foregroundStyle(Color.coastalAqua)
                        }
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
                        .background(Color.coastalCoral)
                        .clipShape(Capsule())
                        .shadow(color: Color.coastalCoral.opacity(0.4), radius: 8, y: 4)
                    }
                    .padding(Spacing.lg)
                }
                .sheet(isPresented: $showingSuggestSheet) {
                    suggestSheet
                        .presentationDetents([.medium])
                        .presentationBackground(Color.coastalBackground)
                }
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
            TextField(searchMode == .items ? "Search items (e.g. matcha)" : "Search places", text: $vm.query)
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
        LazyVGrid(columns: gridColumns, spacing: Spacing.md) {
            ForEach(vm.filteredPlaces) { place in
                NavigationLink(value: place.id) {
                    ImageTileCard(
                        title: place.name,
                        subtitle: [place.category.capitalized, place.neighborhood, place.city].compactMap { $0 }.joined(separator: " · "),
                        imageURL: place.coverPhotoURL,
                        category: place.category
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        session.selectedPlace = place
                        session.selectedTab = .rate
                        session.showInfo("Place selected. Rate it now.")
                    } label: {
                        Label("Rate this place", systemImage: "slider.horizontal.3")
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
            switch categoryFilter {
            case "food": return cat == "food" || cat == "both"
            case "drink": return cat == "drink" || cat == "both"
            case "coffee": return cat.contains("coffee") || cat.contains("cafe")
            default: return true
            }
        }
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Trending in San Diego")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)
                .padding(.horizontal, Spacing.md)

            LazyVGrid(columns: gridColumns, spacing: Spacing.md) {
                ForEach(filteredTrending) { item in
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
