import SwiftUI

/// `user-feed` canvas: main column `px-4 gap-6`; top spacing comes from the fixed header inset. Bottom breathing room
/// is handled with `Spacing` plus `tabBarScrollBottomInset` (FAB overlap beyond `safeAreaInset`).
private enum FeedScreenMetrics {
    static let horizontalPadding: CGFloat = 16
    static let sectionGap: CGFloat = 24
}

struct FeedScreen: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = FeedViewModel()
    @State private var showNotifications = false
    @State private var showFriends = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: FeedScreenMetrics.sectionGap) {
                    if vm.isLoading {
                        ForEach(0..<3, id: \.self) { _ in
                            ImageTileShimmer(heroAspectRatio: 4.0 / 5.0)
                        }
                    } else {
                        if !vm.friendsFeed.isEmpty {
                            FeedSectionHeader(title: "From friends")
                            ForEach(vm.friendsFeed) { event in
                                Button {
                                    session.presentPlaceDetail(event.placeID)
                                } label: {
                                    SocialFeedCard(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if vm.popular.isEmpty {
                            EmptyStateView(
                                title: "No spots yet",
                                message: "Ratings from locals will populate this feed.",
                                icon: "leaf.circle"
                            )
                        } else {
                            ForEach(vm.popular) { place in
                                Button {
                                    session.presentPlaceDetail(place.placeID)
                                } label: {
                                    PopularSpotFeedCard(place: place)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, FeedScreenMetrics.horizontalPadding)
                .padding(.top, Spacing.xxs)
                .padding(.bottom, Spacing.md + Spacing.tabBarScrollBottomInset)
            }
            .background(Color.feedCanvasSand)
            .refreshable {
                await loadFeed()
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                feedHeaderChrome
            }
            .toolbar(.hidden, for: .navigationBar)
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

    /// Canvas: `bg-sand/90 backdrop-blur-md`, `pb-4 px-6`, palm + `localsonly` + bell on `bg-card` circle (`w-10 h-10`).
    private var feedHeaderChrome: some View {
        HStack(alignment: .center, spacing: 8) {
            PalmTreeShape()
                .fill(Color.black)
                .frame(width: 28, height: 32)
            Text("localsonly")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .accessibilityHint("Long press for friends and messages")
                .contextMenu {
                    Button {
                        showFriends = true
                    } label: {
                        Label("Friends and messages", systemImage: "paperplane.fill")
                    }
                }
            Spacer(minLength: 0)
            Button {
                showNotifications = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.feedCanvasOcean)
                        .frame(width: 40, height: 40)
                        .background(Color.feedCanvasCard)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                    if session.unreadNotificationCount > 0 {
                        Circle()
                            .fill(Color.coastalCoral)
                            .frame(width: 9, height: 9)
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.feedCanvasSand.opacity(0.88))
                .ignoresSafeArea(edges: .top)
        }
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
