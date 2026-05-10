import PhotosUI
import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = ProfileViewModel()
    @State private var showingEditProfile = false
    @State private var showingAdmin = false
    @State private var showingFriends = false
    @State private var showingSaved = false
    @State private var showingLists = false
    @State private var showingInvites = false
    @State private var editDisplayName = ""
    @State private var editBio = ""
    @State private var editAvatarURL = ""
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var ratingToDelete: RatingResponse?
    @State private var ratingToEdit: RatingResponse?
    @State private var adminTapCount = 0
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @State private var profileMainTab = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    coverBanner
                    EligibilityBanner(state: session.eligibilityState)
                    profileHeader
                    statsRow

                    Picker("", selection: $profileMainTab) {
                        Text("Logs").tag(0)
                        Text("Map").tag(1)
                        Text("Saved").tag(2)
                    }
                    .pickerStyle(.segmented)

                    if profileMainTab == 0 {
                        actionsGrid
                        tasteProfileCard
                        rankingsSection

                        if vm.isLoading {
                            ForEach(0..<2, id: \.self) { _ in
                                LoadingShimmer()
                            }
                        } else if vm.ratings.isEmpty {
                            EmptyStateView(
                                title: "No ratings yet",
                                message: "Share your first local review to start building your profile.",
                                icon: "star.bubble"
                            )
                        } else {
                            profileLogsGrid
                            ratingsSection
                        }
                    } else if profileMainTab == 1 {
                        MapExploreView()
                            .frame(height: 440)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.gray.opacity(0.12), lineWidth: 1)
                            )
                    } else {
                        SavedPlacesScreen(embedded: true)
                    }

                    appearancePicker

                    Button("Sign Out") {
                        session.signOut()
                    }
                    .font(.bodyCopy)
                    .foregroundStyle(Color.coastalStatusRestricted)
                    .padding(.top, Spacing.sm)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .refreshable { await refresh() }
            .navigationTitle("")
            .navigationDestination(for: UserNavigationID.self) { nav in
                UserProfileScreen(userID: nav.id)
            }
            .navigationDestination(for: UUID.self) { placeID in
                PlaceDetailScreen(placeID: placeID)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(profileHandle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.coastalTextPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.sm) {
                        Button {
                            showingFriends = true
                        } label: {
                            Image(systemName: "person.2")
                                .foregroundStyle(Color.coastalAqua)
                        }
                        Button {
                            adminTapCount += 1
                            if adminTapCount >= 5 {
                                adminTapCount = 0
                                showingAdmin = true
                            }
                        } label: {
                            Text("v1.0")
                                .font(.microLabel)
                                .foregroundStyle(Color.coastalTextSecondary)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showingEditProfile) {
            editProfileSheet
                .preferredColorScheme(.light)
                .presentationDetents([.medium])
                .presentationBackground(Color.coastalBackground)
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
        .sheet(isPresented: $showingSaved) {
            SavedPlacesScreen()
                .environmentObject(session)
                .preferredColorScheme(.light)
        }
        .sheet(isPresented: $showingLists) {
            ListsScreen()
                .environmentObject(session)
                .preferredColorScheme(.light)
        }
        .sheet(isPresented: $showingInvites) {
            InviteScreen()
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

    private var profileHandle: String {
        let raw = vm.profile?.displayName ?? session.displayName
        let slug = raw
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
        return "@\(slug.isEmpty ? "local" : slug)"
    }

    private var coverBanner: some View {
        ZStack(alignment: .top) {
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80")) { phase in
                switch phase {
                case .success(let img):
                    img
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    LinearGradient(
                        colors: [Color.coastalAqua.opacity(0.45), Color.coastalSand],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(height: 200)
            .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.55), Color.clear, Color.black.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 36,
                bottomTrailingRadius: 36,
                topTrailingRadius: 0
            )
        )
        .padding(.horizontal, -Spacing.md)
    }

    private var profileHeader: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    profileHeroAvatar
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        .offset(y: -36)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(vm.profile?.displayName ?? (session.displayName.isEmpty ? "Local" : session.displayName))
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(Color.coastalTextPrimary)
                        Text(vm.profile?.bio.isEmpty == false ? (vm.profile?.bio ?? "") : "No bio yet.")
                            .font(.captionCopy)
                            .foregroundStyle(Color.coastalTextSecondary)
                            .lineLimit(3)
                    }
                    Spacer(minLength: 8)
                    Button("Edit Profile") {
                        editDisplayName = vm.profile?.displayName ?? session.displayName
                        editBio = vm.profile?.bio ?? ""
                        editAvatarURL = vm.profile?.avatarURL ?? ""
                        showingEditProfile = true
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.coastalTextPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.gray.opacity(0.25), lineWidth: 1))
                }
                StatePill(text: session.eligibilityState)
                Text("Member in \(vm.profile?.homeCity ?? "SanDiego")")
                    .font(.captionCopy)
                    .foregroundStyle(Color.coastalTextSecondary)
            }
        }
        .offset(y: -52)
        .padding(.bottom, -40)
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
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                default:
                    DefaultAvatarView(
                        variant: .forUser(vm.profile?.id ?? UUID()),
                        size: 96
                    )
                }
            }
        } else {
            DefaultAvatarView(
                variant: .forUser(vm.profile?.id ?? UUID()),
                size: 96
            )
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let urlString = vm.profile?.avatarURL, !urlString.isEmpty, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 58, height: 58)
                        .clipShape(Circle())
                default:
                    initialsAvatar
                }
            }
        } else {
            initialsAvatar
        }
    }

    private var initialsAvatar: some View {
        DefaultAvatarView(
            variant: .forUser(vm.profile?.id ?? UUID()),
            size: 58
        )
    }

    private var appearancePicker: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "moon.sun")
                        .foregroundStyle(Color.coastalAqua)
                    Text("Appearance")
                        .font(.cardTitle)
                        .foregroundStyle(Color.coastalTextPrimary)
                }
                Picker("", selection: $appearanceMode) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var actionsGrid: some View {
        HStack(spacing: Spacing.sm) {
            actionButton(icon: "list.bullet.rectangle", title: "Lists", count: nil) {
                showingLists = true
            }
            actionButton(icon: "envelope.fill", title: "Invites", count: nil) {
                showingInvites = true
            }
        }
    }

    private func actionButton(icon: String, title: String, count: Int?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            GlassCard {
                VStack(spacing: Spacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.coastalAqua)
                    Text(title)
                        .font(.microLabel)
                        .foregroundStyle(Color.coastalTextPrimary)
                    if let count {
                        Text("\(count)")
                            .font(.microLabel)
                            .foregroundStyle(Color.coastalTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    private var tasteProfileCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Taste Profile")
                    .font(.cardTitle)
                    .foregroundStyle(Color.coastalTextPrimary)
                Text(vm.tasteSummary)
                    .font(.bodyCopy)
                    .foregroundStyle(Color.coastalTextSecondary)

                if !vm.ratings.isEmpty {
                    tasteDistribution
                }
            }
        }
    }

    private var tasteDistribution: some View {
        let grouped = Dictionary(grouping: vm.ratings, by: { ($0.itemCategory ?? "general").lowercased() })
        let sorted = grouped.sorted { $0.value.count > $1.value.count }.prefix(5)
        let maxCount = sorted.first?.value.count ?? 1

        return VStack(spacing: Spacing.xs) {
            ForEach(Array(sorted), id: \.key) { category, ratings in
                HStack(spacing: Spacing.xs) {
                    Text(category.capitalized)
                        .font(.microLabel)
                        .foregroundStyle(Color.coastalTextSecondary)
                        .frame(width: 70, alignment: .trailing)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.coastalAqua.opacity(0.6))
                            .frame(width: geo.size.width * CGFloat(ratings.count) / CGFloat(maxCount))
                    }
                    .frame(height: 12)
                    Text("\(ratings.count)")
                        .font(.microLabel)
                        .foregroundStyle(Color.coastalTextSecondary)
                        .frame(width: 24)
                }
            }
        }
        .padding(.top, Spacing.xs)
    }

    private var friendsRow: some View {
        Button {
            showingFriends = true
        } label: {
            GlassCard {
                HStack {
                    Image(systemName: "person.2")
                        .foregroundStyle(Color.coastalAqua)
                    Text("Friends")
                        .font(.cardTitle)
                        .foregroundStyle(Color.coastalTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalTextSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var rankingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("My Rankings")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)

            if vm.rankingsByCategory.isEmpty {
                Text("Rate a few items to unlock category rankings.")
                    .font(.captionCopy)
                    .foregroundStyle(Color.coastalTextSecondary)
            } else {
                ForEach(vm.rankingsByCategory, id: \.category) { ranking in
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(ranking.category)
                                .font(.cardTitle)
                                .foregroundStyle(Color.coastalTextPrimary)
                            ForEach(Array(ranking.topItems.enumerated()), id: \.element.id) { idx, item in
                                HStack {
                                    Text("#\(idx + 1)")
                                        .font(.captionCopy)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.coastalAqua)
                                        .frame(width: 24)
                                    Text("\(item.itemName ?? "Item") at \(item.placeName ?? "Place")")
                                        .font(.captionCopy)
                                        .foregroundStyle(Color.coastalTextSecondary)
                                    Spacer()
                                    scoreIcon(for: item.score)
                                    Text(String(format: "%.1f", item.score))
                                        .font(.captionCopy)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.scoreColor(for: item.score))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func scoreIcon(for score: Double) -> some View {
        let icon: String
        switch score {
        case 9.0...: icon = "flame.fill"
        case 7.5..<9.0: icon = "hand.thumbsup.fill"
        case 6.0..<7.5: icon = "face.smiling"
        default: icon = "hand.thumbsdown"
        }
        return Image(systemName: icon)
            .font(.system(size: 10))
            .foregroundStyle(Color.scoreColor(for: score))
    }

    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("My Ratings")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)

            ForEach(vm.ratings) { rating in
                RatingCard(
                    title: "\(rating.itemName ?? "Item") at \(rating.placeName ?? "Place")",
                    subtitle: rating.notes,
                    scoreText: String(format: "%.1f", rating.score),
                    privacy: rating.privacy,
                    photoURL: rating.photoURL,
                    score: rating.score,
                    timestamp: rating.createdAt,
                    itemCategory: rating.itemCategory
                )
                .contextMenu {
                    Button {
                        ratingToEdit = rating
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        ratingToDelete = rating
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    ShareLink(item: "\(rating.itemName ?? "Item") at \(rating.placeName ?? "Place") - \(String(format: "%.1f", rating.score))/10 on localsonly") {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: Spacing.sm) {
            profileStatPill(
                value: "\(vm.ratings.count)",
                label: "Spots Logged",
                accent: Color.coastalCoral
            )
            profileStatPill(
                value: "—",
                label: "Followers",
                accent: Color.coastalAqua
            )
            profileStatPill(
                value: "\(session.bookmarkedPlaceIDs.count)",
                label: "Saved",
                accent: Color.coastalInk
            )
        }
    }

    private func profileStatPill(value: String, label: String, accent: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.coastalTextSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Color.coastalCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.orange.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.coastalCoral.opacity(0.05), radius: 12, y: 4)
    }

    private var profileLogsGrid: some View {
        let cols = [
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6)
        ]
        return LazyVGrid(columns: cols, spacing: 6) {
            ForEach(vm.ratings) { rating in
                NavigationLink(value: rating.placeID) {
                    ZStack(alignment: .bottomTrailing) {
                        ratingThumbnail(rating)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                        Text(String(format: "%.1f", rating.score))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.coastalInk.opacity(0.82))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .padding(8)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        ratingToEdit = rating
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        ratingToDelete = rating
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Button {
                session.selectedTab = .rate
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.coastalAqua)
                    Text("Log Spot")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.coastalAqua)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(Color.coastalFoam.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.coastalAqua.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func ratingThumbnail(_ rating: RatingResponse) -> some View {
        if let urlString = rating.photoURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
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
        } catch {
            session.showError(error.localizedDescription)
        }
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
