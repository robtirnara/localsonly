import PhotosUI
import SwiftUI

/// `profile` canvas (`5004d298-…`): centered hero, stats, ocean taste card, Recent Logs / Saved Lists tabs, 2-col grid.
private enum ProfileScreenMetrics {
    static let horizontalPadding: CGFloat = 24
    static let avatarSize: CGFloat = 112
    static let gridCorner: CGFloat = 24
    static let gridSpacing: CGFloat = 16
}

private enum ProfileContentTab: String, CaseIterable {
    case recentLogs = "Recent Logs"
    case savedLists = "Saved Lists"
}

struct ProfileScreen: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = ProfileViewModel()
    @State private var showingEditProfile = false
    @State private var showingAdmin = false
    @State private var showingFriends = false
    @State private var showingLists = false
    @State private var editDisplayName = ""
    @State private var editBio = ""
    @State private var editAvatarURL = ""
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var ratingToDelete: RatingResponse?
    @State private var ratingToEdit: RatingResponse?
    @State private var adminTapCount = 0
    @State private var showingSettings = false
    @State private var profileTab: ProfileContentTab = .recentLogs
    @State private var friendsCount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    profileHeroSection
                    statsRowCanvas
                    locationRow

                    if session.eligibilityState != "verified_local" {
                        EligibilityBanner(state: session.eligibilityState)
                            .padding(.top, Spacing.sm)
                    }

                    tasteProfileCard
                        .padding(.top, Spacing.lg)
                        .padding(.bottom, Spacing.lg)

                    profileTabStrip
                        .padding(.bottom, Spacing.md)

                    profileTabContent
                }
                .padding(.horizontal, ProfileScreenMetrics.horizontalPadding)
                .padding(.top, Spacing.xxs)
                .padding(.bottom, Spacing.md + Spacing.tabBarScrollBottomInset)
            }
            .background(Color.feedCanvasSand)
            .refreshable { await refresh() }
            .safeAreaInset(edge: .top, spacing: 0) {
                profileHeaderChrome
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showingEditProfile) {
            editProfileSheet
                .preferredColorScheme(.light)
                .presentationDetents([.medium])
                .presentationBackground(Color.coastalBackground)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsScreen()
                .environmentObject(session)
                .preferredColorScheme(.light)
        }
        .sheet(isPresented: $showingFriends) {
            FriendsScreen()
                .environmentObject(session)
                .preferredColorScheme(.light)
        }
        .sheet(isPresented: $showingAdmin) {
            AdminScreen()
                .environmentObject(session)
                .preferredColorScheme(.light)
        }
        .sheet(isPresented: $showingLists) {
            ListsScreen()
                .environmentObject(session)
                .preferredColorScheme(.light)
        }
        .sheet(item: $ratingToEdit) { rating in
            EditRatingSheet(rating: rating) {
                session.showSuccess("Rating updated")
                Task { await refresh() }
            }
            .environmentObject(session)
            .preferredColorScheme(.light)
            .presentationDetents([.large])
            .presentationBackground(Color.coastalBackground)
        }
        .alert("Delete Rating?", isPresented: .init(
            get: { ratingToDelete != nil },
            set: { if !$0 { ratingToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let rating = ratingToDelete {
                    Task {
                        do {
                            try await vm.deleteRating(id: rating.id, using: session.api)
                            session.showSuccess("Rating deleted")
                        } catch {
                            session.showError(error.localizedDescription)
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove your rating.")
        }
        .task {
            await refresh()
        }
    }

    // MARK: - Canvas chrome

    private var profileHeaderChrome: some View {
        HStack {
            Spacer()
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.feedCanvasOcean)
                    .frame(width: 40, height: 40)
                    .background(Color.feedCanvasCard)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, ProfileScreenMetrics.horizontalPadding)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.feedCanvasSand.opacity(0.92))
                .ignoresSafeArea(edges: .top)
        }
    }

    private var profileHeroSection: some View {
        VStack(spacing: 0) {
            Button {
                editDisplayName = vm.profile?.displayName ?? session.displayName
                editBio = vm.profile?.bio ?? ""
                editAvatarURL = vm.profile?.avatarURL ?? ""
                showingEditProfile = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    profileHeroAvatar
                        .overlay(Circle().stroke(Color.feedCanvasCard, lineWidth: 4))
                        .shadow(color: Color.black.opacity(0.12), radius: 12, y: 6)

                    if showsVerifiedBadge {
                        ZStack {
                            Circle()
                                .fill(Color.feedCanvasSky)
                                .frame(width: 32, height: 32)
                            Circle()
                                .stroke(Color.feedCanvasSand, lineWidth: 2)
                                .frame(width: 32, height: 32)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.feedCanvasOcean)
                        }
                        .offset(x: 4, y: 4)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)

            Text(displayNameLine)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .padding(.bottom, 4)
                .onTapGesture {
                    adminTapCount += 1
                    if adminTapCount >= 5 {
                        adminTapCount = 0
                        showingAdmin = true
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding(.top, 8)
    }

    private var showsVerifiedBadge: Bool {
        session.eligibilityState == "verified_local" || session.eligibilityState == "provisional_local"
    }

    private var displayNameLine: String {
        let raw = vm.profile?.displayName ?? session.displayName
        if raw.isEmpty { return "Local" }
        return raw
    }

    private var statsRowCanvas: some View {
        HStack(spacing: 32) {
            statColumn(value: "\(vm.ratings.count)", label: "Spots Logged")
            Rectangle()
                .fill(Color.gray.opacity(0.35))
                .frame(width: 1, height: 40)
            statColumn(
                value: vm.ratings.isEmpty ? "—" : String(format: "%.1f", vm.averageScore),
                label: "Avg Score"
            )
            Rectangle()
                .fill(Color.gray.opacity(0.35))
                .frame(width: 1, height: 40)
            Button {
                showingFriends = true
            } label: {
                statColumn(value: "\(friendsCount)", label: "Followers")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Spacing.md)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasConcrete)
        }
    }

    private var locationRow: some View {
        HStack(spacing: 4) {
            PalmTreeShape()
                .fill(Color.black)
                .frame(width: 16, height: 18)
            Text(locationLine)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasConcrete)
        }
        .padding(.bottom, Spacing.md)
    }

    private var locationLine: String {
        let city = vm.profile?.homeCity ?? "SanDiego"
        return city.replacingOccurrences(of: "SanDiego", with: "San Diego")
    }

    private var tasteProfileCard: some View {
        let rows = tasteCategoryRows
        let possessive = displayNameLine.split(separator: " ").first.map(String.init) ?? displayNameLine

        return ZStack(alignment: .bottomTrailing) {
            Image(systemName: "water.waves")
                .font(.system(size: 120))
                .foregroundStyle(Color.white.opacity(0.2))
                .rotationEffect(.degrees(12))
                .offset(x: 24, y: 24)

            VStack(alignment: .leading, spacing: 16) {
                Text("\(possessive)'s Taste Profile")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if rows.isEmpty {
                    Text("Rate a few spots to build your taste map.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.85))
                } else {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(row.name)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                Spacer()
                                Text(row.level)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.black.opacity(0.2))
                                    Capsule()
                                        .fill(Color.feedCanvasSky)
                                        .frame(width: max(8, geo.size.width * row.fill))
                                }
                            }
                            .frame(height: 12)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(Color.feedCanvasOcean)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
    }

    private var tasteCategoryRows: [(name: String, level: String, fill: CGFloat)] {
        let grouped = Dictionary(grouping: vm.ratings, by: { ($0.itemCategory ?? "general").lowercased() })
        return grouped.map { key, ratings in
            let avg = ratings.map(\.score).reduce(0, +) / Double(ratings.count)
            let level: String
            if avg >= 8.5 || ratings.count >= 8 { level = "Expert" }
            else if avg >= 7.0 || ratings.count >= 4 { level = "Lover" }
            else { level = "Regular" }
            let fill = CGFloat(min(1, avg / 10.0))
            return (key.capitalized, level, fill)
        }
        .sorted { $0.fill > $1.fill }
        .prefix(3)
        .map { $0 }
    }

    private var profileTabStrip: some View {
        HStack(spacing: 16) {
            ForEach(ProfileContentTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        profileTab = tab
                    }
                } label: {
                    VStack(spacing: 0) {
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(profileTab == tab ? Color.feedCanvasOcean : Color.feedCanvasConcrete)
                            .padding(.bottom, 8)
                        Rectangle()
                            .fill(profileTab == tab ? Color.feedCanvasSky : Color.clear)
                            .frame(height: 4)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.gray.opacity(0.25))
                .frame(height: 2)
        }
    }

    @ViewBuilder
    private var profileTabContent: some View {
        switch profileTab {
        case .recentLogs:
            recentLogsTab
        case .savedLists:
            savedListsTab
        }
    }

    @ViewBuilder
    private var recentLogsTab: some View {
        if vm.isLoading {
            ForEach(0..<4, id: \.self) { _ in
                ImageTileShimmer(heroAspectRatio: 1)
            }
        } else if vm.ratings.isEmpty {
            EmptyStateView(
                title: "No ratings yet",
                message: "Log your first spot to fill this grid.",
                icon: "star.bubble"
            )
            .padding(.vertical, Spacing.lg)
        } else {
            profileLogsGridCanvas
        }
    }

    private var savedListsTab: some View {
        VStack(spacing: Spacing.md) {
            savedListsRow(
                title: "Saved Spots",
                subtitle: "\(session.bookmarkedPlaceIDs.count) bookmarked",
                icon: "bookmark.fill"
            ) {
                session.selectedTab = .saved
            }
            savedListsRow(
                title: "Your Lists",
                subtitle: "Collections & playlists",
                icon: "list.bullet.rectangle"
            ) {
                showingLists = true
            }
            savedListsRow(
                title: "Invites",
                subtitle: "Share access",
                icon: "envelope.fill"
            ) {
                session.presentInviteFriends()
            }
        }
        .padding(.bottom, Spacing.lg)
    }

    private func savedListsRow(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.feedCanvasOcean)
                    .frame(width: 44, height: 44)
                    .background(Color.feedCanvasSky.opacity(0.25))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasInk)
                    Text(subtitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasConcrete)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.feedCanvasConcrete)
            }
            .padding(16)
            .background(Color.feedCanvasCard)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var profileLogsGridCanvas: some View {
        let columns = [
            GridItem(.flexible(), spacing: ProfileScreenMetrics.gridSpacing),
            GridItem(.flexible(), spacing: ProfileScreenMetrics.gridSpacing)
        ]
        return LazyVGrid(columns: columns, spacing: ProfileScreenMetrics.gridSpacing) {
            ForEach(vm.ratings) { rating in
                Button {
                    session.presentPlaceDetail(rating.placeID)
                } label: {
                    ZStack(alignment: .topTrailing) {
                        ratingThumbnail(rating)
                            .aspectRatio(1, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipped()

                        HStack(spacing: 4) {
                            Text(String(format: "%.1f", rating.score))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Image(systemName: "water.waves")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(Color.feedCanvasInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.feedCanvasCard.opacity(0.92))
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.06), radius: 2, y: 1)
                        .padding(8)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: ProfileScreenMetrics.gridCorner, style: .continuous))
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button { ratingToEdit = rating } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) { ratingToDelete = rating } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    ShareLink(
                        item: "\(rating.itemName ?? "Item") at \(rating.placeName ?? "Place") - \(String(format: "%.1f", rating.score))/10 on localsonly"
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }

            Button {
                session.selectedTab = .rate
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                    Text("Log New")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.feedCanvasOcean)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(Color.feedCanvasCard)
                .clipShape(RoundedRectangle(cornerRadius: ProfileScreenMetrics.gridCorner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ProfileScreenMetrics.gridCorner, style: .continuous)
                        .strokeBorder(Color.feedCanvasSky, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var profileHeroAvatar: some View {
        if let urlString = vm.profile?.avatarURL, !urlString.isEmpty, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: ProfileScreenMetrics.avatarSize, height: ProfileScreenMetrics.avatarSize)
                        .clipShape(Circle())
                default:
                    DefaultAvatarView(
                        variant: .forUser(vm.profile?.id ?? UUID()),
                        size: ProfileScreenMetrics.avatarSize
                    )
                }
            }
        } else {
            DefaultAvatarView(
                variant: .forUser(vm.profile?.id ?? UUID()),
                size: ProfileScreenMetrics.avatarSize
            )
        }
    }

    @ViewBuilder
    private func ratingThumbnail(_ rating: RatingResponse) -> some View {
        if let urlString = rating.photoURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Color.feedCanvasHeroPlaceholder
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundStyle(Color.feedCanvasOcean)
                        )
                }
            }
        } else {
            Color.feedCanvasHeroPlaceholder
                .overlay(
                    Image(systemName: "fork.knife")
                        .foregroundStyle(Color.feedCanvasOcean)
                )
        }
    }

    private var editProfileSheet: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Edit profile")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)

            HStack {
                Spacer()
                PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                    if !editAvatarURL.isEmpty, let url = URL(string: editAvatarURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 72, height: 72)
                                    .clipShape(Circle())
                                    .overlay(cameraOverlay)
                            default:
                                editAvatarPlaceholder
                            }
                        }
                    } else {
                        editAvatarPlaceholder
                    }
                }
                .onChange(of: avatarPickerItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            do {
                                let url = try await session.api.uploadImage(data: data)
                                editAvatarURL = url
                            } catch {
                                session.showError(error.localizedDescription)
                            }
                        }
                    }
                }
                Spacer()
            }

            TextField("Display name", text: $editDisplayName)
                .foregroundStyle(Color.coastalTextPrimary)
                .padding()
                .background(Color.coastalCard)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            TextField("Bio", text: $editBio, axis: .vertical)
                .foregroundStyle(Color.coastalTextPrimary)
                .lineLimit(2...4)
                .padding()
                .background(Color.coastalCard)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            PrimaryButton(title: "Save", isLoading: false) {
                Task {
                    do {
                        try await vm.updateProfile(
                            using: session.api,
                            displayName: editDisplayName,
                            bio: editBio,
                            avatarURL: editAvatarURL
                        )
                        session.showSuccess("Profile updated")
                        session.displayName = vm.profile?.displayName ?? session.displayName
                        showingEditProfile = false
                    } catch {
                        session.showError(error.localizedDescription)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
    }

    private var editAvatarPlaceholder: some View {
        DefaultAvatarView(
            variant: .forUser(vm.profile?.id ?? UUID()),
            size: 72
        )
        .overlay(cameraOverlay)
    }

    private var cameraOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "pencil.circle.fill")
                    .foregroundStyle(Color.coastalAqua)
                    .background(Circle().fill(Color.coastalCard).frame(width: 20, height: 20))
            }
        }
    }

    private func refresh() async {
        guard session.signedIn else { return }
        do {
            try await vm.refresh(using: session.api)
            friendsCount = (try? await session.api.friends())?.count ?? 0
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}

/// Frosted glass surface matching AIDesigner profile “taste map” card (white / blur / 20pt radius).
private struct ProfileFrostedCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.md + 4)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.02), lineWidth: 1)
                }
            }
            .shadow(color: Color.black.opacity(0.04), radius: 16, y: 8)
    }
}

struct EditRatingSheet: View {
    let rating: RatingResponse
    var onSave: () -> Void

    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var itemName: String = ""
    @State private var itemCategory: String = ""
    @State private var score: Double = 5.0
    @State private var notes: String = ""
    @State private var privacy: String = "public"
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    GlassCard {
                        VStack(spacing: Spacing.md) {
                            TextField("Item name", text: $itemName)
                                .foregroundStyle(Color.coastalTextPrimary)
                                .padding()
                                .background(Color.coastalCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            TextField("Category", text: $itemCategory)
                                .foregroundStyle(Color.coastalTextPrimary)
                                .padding()
                                .background(Color.coastalCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            ScoreSlider(value: $score)

                            TextField("Notes", text: $notes, axis: .vertical)
                                .foregroundStyle(Color.coastalTextPrimary)
                                .lineLimit(3...5)
                                .padding()
                                .background(Color.coastalCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            HStack(spacing: Spacing.xs) {
                                ForEach(["public", "friends", "private"], id: \.self) { value in
                                    Button {
                                        privacy = value
                                    } label: {
                                        Text(value.capitalized)
                                            .font(.captionCopy)
                                            .foregroundStyle(privacy == value ? Color.coastalTextPrimary : Color.coastalAqua)
                                            .padding(.vertical, Spacing.xs)
                                            .frame(maxWidth: .infinity)
                                            .background(privacy == value ? Color.coastalAqua.opacity(0.35) : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .stroke(Color.coastalAqua.opacity(0.6), lineWidth: 1)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            PrimaryButton(title: "Save Changes", isLoading: isSaving) {
                                Task { await save() }
                            }
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Rating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.coastalAqua)
                }
            }
        }
        .onAppear {
            itemName = rating.itemName ?? ""
            itemCategory = rating.itemCategory ?? ""
            score = rating.score
            notes = rating.notes
            privacy = rating.privacy
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await session.api.updateRating(
                id: rating.id,
                score: score,
                itemName: itemName,
                itemCategory: itemCategory,
                notes: notes,
                privacy: privacy,
                photoURL: nil
            )
            onSave()
            dismiss()
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}
