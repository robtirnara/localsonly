import SwiftUI

struct SavedPlacesScreen: View {
    /// When `true`, the screen is shown as a root tab (no Done dismiss button).
    var embedded: Bool = false

    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var bookmarks: [BookmarkedPlaceResponse] = []
    @State private var isLoading = true

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    LazyVGrid(columns: gridColumns, spacing: Spacing.md) {
                        ForEach(0..<4, id: \.self) { _ in ImageTileShimmer() }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, embedded ? Spacing.tabBarScrollBottomInset : 0)
                } else if bookmarks.isEmpty {
                    EmptyStateView(
                        title: "No saved places",
                        message: "Tap the bookmark icon on any place to save it for later.",
                        icon: "bookmark"
                    )
                    .padding(.top, Spacing.xl)
                    .padding(.bottom, embedded ? Spacing.tabBarScrollBottomInset : 0)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: Spacing.md) {
                        ForEach(bookmarks) { place in
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
                                Button(role: .destructive) {
                                    Task { await removeBookmark(place.id) }
                                } label: {
                                    Label("Remove Bookmark", systemImage: "bookmark.slash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.sm + (embedded ? Spacing.tabBarScrollBottomInset : 0))
                }
            }
            .background(Color.coastalBackground)
            .refreshable { await load() }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { placeID in
                PlaceDetailScreen(placeID: placeID)
            }
            .toolbar {
                if !embedded {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { dismiss() }
                            .foregroundStyle(Color.coastalAqua)
                    }
                }
            }
        }
        .task { await load() }
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
