import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var friendsFeed: [FeedEventResponse] = []
    @Published var popular: [PopularPlaceResponse] = []
    @Published var isLoading = false

    func refresh(using api: APIClient, signedIn: Bool) async throws {
        isLoading = true
        defer { isLoading = false }

        popular = try await api.popularFeed()
        if signedIn {
            friendsFeed = try await api.friendsFeed()
        } else {
            friendsFeed = []
        }
    }
}
