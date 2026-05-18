import Foundation

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var places: [PlaceResponse] = []
    /// City-wide ranked places (Top Locals list / map pin source).
    @Published var topPlaces: [PopularPlaceResponse] = []
    @Published var trendingItems: [ItemSearchResponse] = []
    @Published var isLoading = false
    @Published var hasSearched = false
    @Published var selectedNeighborhood: String?

    @Published var suggestName: String = ""
    @Published var suggestNeighborhood: String = ""
    @Published var suggestCategory: String = "food"
    @Published var isSuggesting = false
    @Published var isLoadingTopPlaces = false

    private var debounceTask: Task<Void, Never>?

    var neighborhoodFilters: [String] {
        let hoods = places.compactMap(\.neighborhood).filter { !$0.isEmpty }
        return Array(Set(hoods)).sorted()
    }

    /// Neighborhoods present in the current dish trending list (for pills when browsing trending).
    var trendingNeighborhoodFilters: [String] {
        let hoods = trendingItems.compactMap(\.neighborhood).filter { !$0.isEmpty }
        return Array(Set(hoods)).sorted()
    }

    var filteredPlaces: [PlaceResponse] {
        guard let hood = selectedNeighborhood else { return places }
        return places.filter { $0.neighborhood == hood }
    }

    var filteredTrendingItems: [ItemSearchResponse] {
        guard let hood = selectedNeighborhood else { return trendingItems }
        return trendingItems.filter { $0.neighborhood == hood }
    }

    /// Top Locals category strip: `all`, `food`, `coffee`, `drink`, `seafood`.
    func filteredTopPlaces(category: String) -> [PopularPlaceResponse] {
        switch category {
        case "all":
            return topPlaces
        case "coffee", "food", "seafood":
            return topPlaces.filter { $0.category == "food" || $0.category == "both" }
        case "drink":
            return topPlaces.filter { $0.category == "drink" || $0.category == "both" }
        default:
            return topPlaces
        }
    }

    func loadTopPlaces(using api: APIClient) async throws {
        isLoadingTopPlaces = true
        defer { isLoadingTopPlaces = false }
        topPlaces = try await api.popularFeed()
    }

    func search(using api: APIClient) async throws {
        isLoading = true
        hasSearched = true
        defer { isLoading = false }
        places = try await api.searchPlaces(query: query)
        selectedNeighborhood = nil
    }

    func debounceSearch(using api: APIClient) {
        debounceTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            hasSearched = false
            places = []
            selectedNeighborhood = nil
            return
        }
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            try? await search(using: api)
        }
    }

    func loadTrending(using api: APIClient, dishFilter: String? = nil) async throws {
        trendingItems = try await api.popularItemsFeed(filter: dishFilter)
    }

    func suggestPlace(using api: APIClient) async throws -> PlaceResponse {
        isSuggesting = true
        defer { isSuggesting = false }

        let place = try await api.suggestPlace(
            name: suggestName,
            neighborhood: suggestNeighborhood.isEmpty ? nil : suggestNeighborhood,
            category: suggestCategory,
            city: "SanDiego"
        )
        query = place.name
        places = try await api.searchPlaces(query: place.name)
        hasSearched = true
        return place
    }
}
