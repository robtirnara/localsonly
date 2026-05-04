import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var ratings: [RatingResponse] = []
    @Published var isLoading = false
    @Published var profile: UserProfileResponse?

    var averageScore: Double {
        guard !ratings.isEmpty else { return 0 }
        return ratings.map(\.score).reduce(0, +) / Double(ratings.count)
    }

    var topPrivacy: String {
        let grouped = Dictionary(grouping: ratings, by: \.privacy)
        return grouped.max(by: { $0.value.count < $1.value.count })?.key ?? "public"
    }

    var tasteSummary: String {
        let grouped = Dictionary(grouping: ratings, by: { ($0.itemCategory ?? "general").lowercased() })
        let sorted = grouped.sorted { $0.value.count > $1.value.count }.prefix(3).map { $0.key.capitalized }
        guard !sorted.isEmpty else { return "Start rating items to build your taste profile." }
        return "You love: " + sorted.joined(separator: ", ")
    }

    var rankingsByCategory: [(category: String, topItems: [RatingResponse])] {
        Dictionary(grouping: ratings, by: { ($0.itemCategory ?? "general").lowercased() })
            .map { category, categoryRatings in
                let sorted = categoryRatings.sorted { $0.score > $1.score }
                return (category.capitalized, Array(sorted.prefix(3)))
            }
            .sorted { $0.category < $1.category }
    }

    func refresh(using api: APIClient) async throws {
        isLoading = true
        defer { isLoading = false }
        async let profileTask = api.myProfile()
        async let ratingsTask = api.myRatings(sort: "createdAtDesc")
        profile = try await profileTask
        ratings = try await ratingsTask
    }

    func updateProfile(using api: APIClient, displayName: String, bio: String, avatarURL: String) async throws {
        profile = try await api.updateMyProfile(
            displayName: displayName,
            bio: bio,
            avatarURL: avatarURL
        )
    }

    func deleteRating(id: UUID, using api: APIClient) async throws {
        try await api.deleteRating(id: id)
        ratings.removeAll { $0.id == id }
    }

    func replaceRating(_ updated: RatingResponse) {
        if let idx = ratings.firstIndex(where: { $0.id == updated.id }) {
            ratings[idx] = updated
        }
    }
}
