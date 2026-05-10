import SwiftUI

struct FeedScreen: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = FeedViewModel()
    @State private var showNotifications = false
    @State private var showFriends = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                    if vm.isLoading {
                        ForEach(0..<3, id: \.self) { _ in
                            ImageTileShimmer()
                                .padding(.horizontal, Spacing.md)
                        }
                    } else {
                        if !vm.friendsFeed.isEmpty {
                            sectionHeader("From friends")
                            ForEach(vm.friendsFeed) { event in
                                NavigationLink(value: event.placeID) {
                                    SocialFeedCard(event: event)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, Spacing.md)
                            }
                        }

                        sectionHeader("Popular near you")
                        if vm.popular.isEmpty {
                            EmptyStateView(
                                title: "No spots yet",
                                message: "Ratings from locals will populate this feed.",
                                icon: "leaf.circle"
                            )
                            .padding(.horizontal, Spacing.md)
                        } else {
                            ForEach(vm.popular) { place in
                                NavigationLink(value: place.placeID) {
                                    PopularSpotFeedCard(place: place)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, Spacing.md)
                            }
                        }
                    }
                }
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.md + Spacing.tabBarScrollBottomInset)
            }
            .background(Color.coastalSand)
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
                    HStack(spacing: 8) {
                        PalmTreeShape()
                            .fill(Color.coastalInk)
                            .frame(width: 26, height: 30)
                        Text("localsonly")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.coastalInk)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.md) {
                        Button {
                            showFriends = true
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.coastalInk)
                        }
                        .accessibilityLabel("Friends and messages")

                        Button {
                            showNotifications = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.coastalInk)
                                if session.unreadNotificationCount > 0 {
                                    Circle()
                                        .fill(Color.coastalCoral)
                                        .frame(width: 9, height: 9)
                                        .offset(x: 3, y: -3)
                                }
                            }
                        }
                        .accessibilityLabel("Notifications")
                    }
                }
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsScreen()
                    .environmentObject(session)
            }
            .sheet(isPresented: $showFriends) {
                FriendsScreen()
                    .environmentObject(session)
            }
        }
        .task {
            await loadFeed()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.coastalTextSecondary)
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.xs)
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
