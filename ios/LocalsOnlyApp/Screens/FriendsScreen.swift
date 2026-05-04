import SwiftUI

struct FriendsScreen: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var friends: [FriendResponse] = []
    @State private var pendingRequests: [FriendResponse] = []
    @State private var searchQuery = ""
    @State private var searchResults: [UserSearchResponse] = []
    @State private var isLoading = false
    @State private var isSearching = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedTab) {
                    Text("Friends").tag(0)
                    Text("Find People").tag(1)
                    if !pendingRequests.isEmpty {
                        Text("Pending (\(pendingRequests.count))").tag(2)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)

                ScrollView {
                    if selectedTab == 0 {
                        friendsList
                    } else if selectedTab == 1 {
                        searchSection
                    } else {
                        pendingSection
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.coastalAqua)
                }
            }
            .navigationDestination(for: UserNavigationID.self) { nav in
                UserProfileScreen(userID: nav.id)
            }
        }
        .task {
            await loadData()
        }
    }

    private var friendsList: some View {
        VStack(spacing: Spacing.sm) {
            if isLoading {
                ForEach(0..<3, id: \.self) { _ in LoadingShimmer() }
            } else if friends.isEmpty {
                EmptyStateView(
                    title: "No friends yet",
                    message: "Search for people to connect with.",
                    icon: "person.2"
                )
            } else {
                ForEach(friends) { friend in
                    NavigationLink(value: UserNavigationID(id: friend.userID)) {
                        friendRow(name: friend.displayName, avatar: friend.avatarURL, city: friend.homeCity, userID: friend.userID)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }

    private var searchSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                TextField("Search by name", text: $searchQuery)
                    .foregroundStyle(Color.coastalTextPrimary)
                    .onSubmit { Task { await searchUsers() } }
                    .padding()
                    .background(Color.coastalCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    Task { await searchUsers() }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.coastalAqua)
                        .frame(width: 44, height: 44)
                        .background(Color.coastalCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            if isSearching {
                ProgressView().padding()
            } else if searchResults.isEmpty && !searchQuery.isEmpty {
                EmptyStateView(title: "No users found", message: "Try a different name.", icon: "person.slash")
            } else {
                ForEach(searchResults) { user in
                    GlassCard {
                        HStack {
                            userAvatar(name: user.displayName, url: user.avatarURL, userID: user.id)
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(user.displayName)
                                    .font(.cardTitle)
                                    .foregroundStyle(Color.coastalTextPrimary)
                                Text(user.homeCity)
                                    .font(.captionCopy)
                                    .foregroundStyle(Color.coastalTextSecondary)
                            }
                            Spacer()
                            if isFriend(user.id) {
                                Text("Friends")
                                    .font(.microLabel)
                                    .foregroundStyle(Color.coastalStatusSuccess)
                            } else {
                                Button("Add") {
                                    Task { await addFriend(userID: user.id) }
                                }
                                .font(.captionCopy)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.coastalAqua)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }

    private var pendingSection: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(pendingRequests) { req in
                GlassCard {
                    HStack {
                        userAvatar(name: req.displayName, url: req.avatarURL, userID: req.userID)
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(req.displayName)
                                .font(.cardTitle)
                                .foregroundStyle(Color.coastalTextPrimary)
                            Text("Wants to be friends")
                                .font(.captionCopy)
                                .foregroundStyle(Color.coastalTextSecondary)
                        }
                        Spacer()
                        Button("Accept") {
                            Task { await acceptRequest(userID: req.userID) }
                        }
                        .font(.captionCopy)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.coastalStatusSuccess)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }

    private func friendRow(name: String, avatar: String?, city: String, userID: UUID) -> some View {
        GlassCard {
            HStack {
                userAvatar(name: name, url: avatar, userID: userID)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(name)
                        .font(.cardTitle)
                        .foregroundStyle(Color.coastalTextPrimary)
                    Text(city)
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.captionCopy)
                    .foregroundStyle(Color.coastalTextSecondary)
            }
        }
    }

    private func userAvatar(name: String, url: String?, userID: UUID) -> some View {
        Group {
            if let url, !url.isEmpty, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40).clipShape(Circle())
                    } else {
                        DefaultAvatarView(variant: .forUser(userID), size: 40)
                    }
                }
            } else {
                DefaultAvatarView(variant: .forUser(userID), size: 40)
            }
        }
    }

    private func isFriend(_ userID: UUID) -> Bool {
        friends.contains { $0.userID == userID }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let friendsTask = session.api.friends()
            async let pendingTask = session.api.pendingFriendRequests()
            friends = try await friendsTask
            pendingRequests = try await pendingTask
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func searchUsers() async {
        isSearching = true
        defer { isSearching = false }
        do {
            searchResults = try await session.api.searchUsers(query: searchQuery)
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func addFriend(userID: UUID) async {
        do {
            try await session.api.sendFriendRequest(userID: userID)
            session.showSuccess("Friend request sent")
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func acceptRequest(userID: UUID) async {
        do {
            try await session.api.acceptFriendRequest(userID: userID)
            session.showSuccess("Friend request accepted")
            pendingRequests.removeAll { $0.userID == userID }
            await loadData()
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}
