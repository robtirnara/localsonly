import SwiftUI

struct PlaceDetailScreen: View {
    let placeID: UUID
    @EnvironmentObject private var session: SessionManager
    @State private var place: PlaceResponse?
    @State private var ratings: [PlaceRatingResponse] = []
    @State private var isLoading = true
    @State private var galleryPage = 0
    @State private var fullScreenPhotoURL: String?
    @State private var showRatingSheet = false
    @State private var showAddToListSheet = false
    @State private var lists: [ListResponse] = []
    @State private var cosignCounts: [UUID: (count: Int, byMe: Bool)] = [:]

    private var avgScore: Double {
        guard !ratings.isEmpty else { return 0 }
        return ratings.map(\.score).reduce(0, +) / Double(ratings.count)
    }

    private var photoURLs: [String] {
        var urls: [String] = []
        if let cover = place?.coverPhotoURL, !cover.isEmpty { urls.append(cover) }
        for r in ratings {
            if let url = r.photoURL, !url.isEmpty, !urls.contains(url) { urls.append(url) }
        }
        return urls
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if isLoading {
                    ImageTileShimmer()
                        .padding(Spacing.md)
                    ForEach(0..<2, id: \.self) { _ in
                        ImageTileShimmer()
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.sm)
                    }
                } else {
                    heroSection
                    contentSection
                }
            }
            .padding(.bottom, Spacing.tabBarScrollBottomInset)
        }
        .refreshable { await load() }
        .navigationTitle(place?.name ?? "Place")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: UserNavigationID.self) { nav in
            UserProfileScreen(userID: nav.id)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    Button {
                        Task { await session.toggleBookmark(placeID: placeID) }
                    } label: {
                        Image(systemName: session.bookmarkedPlaceIDs.contains(placeID) ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(session.bookmarkedPlaceIDs.contains(placeID) ? Color.coastalCoral : Color.coastalAqua)
                    }
                }
            }
        }
        .sheet(isPresented: $showRatingSheet) {
            InlineRatingSheet(placeID: placeID, placeName: place?.name ?? "", placeCategory: place?.category ?? "food") {
                Task { await load() }
            }
            .environmentObject(session)
            .presentationDetents([.large])
            .presentationBackground(Color.coastalBackground)
        }
        .sheet(isPresented: $showAddToListSheet) {
            AddToListSheet(placeID: placeID, placeName: place?.name ?? "")
                .environmentObject(session)
                .presentationDetents([.medium])
                .presentationBackground(Color.coastalBackground)
        }
        .fullScreenCover(item: Binding(
            get: { fullScreenPhotoURL.map { IdentifiableString(value: $0) } },
            set: { fullScreenPhotoURL = $0?.value }
        )) { item in
            FullScreenPhotoViewer(imageURL: item.value)
        }
        .task { await load() }
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            if photoURLs.isEmpty {
                PlaceholderHeroView(
                    category: place?.category ?? "food",
                    height: 260
                )
                .frame(maxWidth: .infinity)
            } else if photoURLs.count == 1 {
                singleHeroImage(photoURLs[0])
            } else {
                TabView(selection: $galleryPage) {
                    ForEach(Array(photoURLs.enumerated()), id: \.offset) { idx, urlStr in
                        if let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity, maxHeight: 260)
                                        .clipped()
                                        .onTapGesture { fullScreenPhotoURL = urlStr }
                                default:
                                    PlaceholderHeroView(
                                        category: place?.category ?? "food",
                                        height: 260
                                    )
                                }
                            }
                            .tag(idx)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 260)
            }

            LinearGradient(
                colors: [.clear, Color.coastalBackground.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(place?.name ?? "")
                    .font(.sectionTitle)
                    .foregroundStyle(Color.coastalTextPrimary)
                HStack(spacing: Spacing.xs) {
                    Text(place?.category.capitalized ?? "")
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalAqua)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.coastalAqua.opacity(0.15))
                        .clipShape(Capsule())
                    if let neighborhood = place?.neighborhood, !neighborhood.isEmpty {
                        Text(neighborhood)
                            .font(.captionCopy)
                            .foregroundStyle(Color.coastalTextSecondary)
                    }
                    Text(place?.city ?? "")
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.sm)
        }
    }

    @ViewBuilder
    private func singleHeroImage(_ urlStr: String) -> some View {
        if let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 260)
                        .clipped()
                        .onTapGesture { fullScreenPhotoURL = urlStr }
                default:
                    PlaceholderHeroView(
                        category: place?.category ?? "food",
                        height: 260
                    )
                }
            }
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(spacing: Spacing.md) {
            statsSection

            if ratings.isEmpty {
                EmptyStateView(
                    title: "No public ratings yet",
                    message: "Be the first to rate something here.",
                    icon: "star"
                )
            } else {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Ratings")
                        .font(.sectionTitle)
                        .foregroundStyle(Color.coastalTextPrimary)

                    ForEach(ratings) { rating in
                        ratingRow(rating)
                    }
                }
            }

            HStack(spacing: Spacing.sm) {
                PrimaryButton(title: "Rate this place") {
                    showRatingSheet = true
                }

                Button {
                    showAddToListSheet = true
                    Task {
                        do { lists = try await session.api.myLists() } catch {}
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus.rectangle.on.folder")
                        Text("Add to List")
                            .font(.cardTitle)
                    }
                    .foregroundStyle(Color.coastalAqua)
                    .padding(.vertical, Spacing.sm)
                    .padding(.horizontal, Spacing.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.coastalAqua.opacity(0.6), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            if let place {
                ShareLink(item: "Check out \(place.name) on localsonly! \(place.category.capitalized) in \(place.city)") {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                            .font(.cardTitle)
                    }
                    .foregroundStyle(Color.coastalAqua)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.coastalAqua.opacity(0.6), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private var statsSection: some View {
        HStack(spacing: Spacing.sm) {
            GlassCard {
                VStack(spacing: Spacing.xs) {
                    Text("Ratings")
                        .font(.microLabel)
                        .foregroundStyle(Color.coastalTextSecondary)
                    Text("\(ratings.count)")
                        .font(.cardTitle)
                        .foregroundStyle(Color.coastalAqua)
                }
                .frame(maxWidth: .infinity)
            }
            GlassCard {
                VStack(spacing: Spacing.xs) {
                    Text("Average")
                        .font(.microLabel)
                        .foregroundStyle(Color.coastalTextSecondary)
                    let avgColor: Color = ratings.isEmpty ? .coastalTextSecondary : .scoreColor(for: avgScore)
                    Text(ratings.isEmpty ? "-" : String(format: "%.1f", avgScore))
                        .font(.cardTitle)
                        .foregroundStyle(avgColor)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func ratingRow(_ rating: PlaceRatingResponse) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let photoURL = rating.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .onTapGesture { fullScreenPhotoURL = photoURL }
                        default:
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.coastalTextSecondary.opacity(0.08))
                                .frame(maxWidth: .infinity, maxHeight: 180)
                                .overlay { WavesLoadingView(size: 20) }
                        }
                    }
                } else {
                    PlaceholderHeroView(category: rating.itemCategory, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(rating.itemName)
                            .font(.cardTitle)
                            .foregroundStyle(Color.coastalTextPrimary)
                        NavigationLink(value: UserNavigationID(id: rating.userID)) {
                            Text(rating.userDisplayName)
                                .font(.captionCopy)
                                .foregroundStyle(Color.coastalAqua)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Text(String(format: "%.1f", rating.score))
                        .font(.sectionTitle)
                        .foregroundStyle(Color.scoreColor(for: rating.score))
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.scoreColor(for: rating.score).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                if !rating.notes.isEmpty {
                    Text(rating.notes)
                        .font(.bodyCopy)
                        .foregroundStyle(Color.coastalTextSecondary)
                }

                HStack {
                    Text(rating.itemCategory.capitalized)
                        .font(.microLabel)
                        .foregroundStyle(Color.coastalSand)

                    Spacer()

                    cosignButton(for: rating)

                    if let createdAt = rating.createdAt {
                        Text(createdAt.relativeString)
                            .font(.microLabel)
                            .foregroundStyle(Color.coastalTextSecondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cosignButton(for rating: PlaceRatingResponse) -> some View {
        let info = cosignCounts[rating.id]
        let count = info?.count ?? 0
        let byMe = info?.byMe ?? false

        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            Task {
                do {
                    if byMe {
                        try await session.api.removeCosign(ratingID: rating.id)
                        cosignCounts[rating.id] = (max(0, count - 1), false)
                    } else {
                        try await session.api.cosignRating(ratingID: rating.id)
                        cosignCounts[rating.id] = (count + 1, true)
                    }
                } catch {
                    session.showError(error.localizedDescription)
                }
            }
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: byMe ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.system(size: 12))
                if count > 0 {
                    Text("\(count)")
                        .font(.microLabel)
                }
            }
            .foregroundStyle(byMe ? Color.coastalAqua : Color.coastalTextSecondary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(byMe ? Color.coastalAqua.opacity(0.12) : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let placeTask = session.api.placeDetail(id: placeID)
            async let ratingsTask = session.api.placeRatings(id: placeID)
            place = try await placeTask
            ratings = try await ratingsTask

            for rating in ratings {
                if let cosignInfo = try? await session.api.getCosigns(ratingID: rating.id) {
                    cosignCounts[rating.id] = (cosignInfo.count, cosignInfo.cosignedByMe)
                }
            }
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}

struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

// MARK: - Inline Rating Sheet

struct InlineRatingSheet: View {
    let placeID: UUID
    let placeName: String
    let placeCategory: String
    var onSubmit: () -> Void

    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = RateViewModel()
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    GlassCard {
                        VStack(spacing: Spacing.md) {
                            TextField("What did you try?", text: $vm.itemName)
                                .foregroundStyle(Color.coastalTextPrimary)
                                .padding()
                                .background(Color.coastalCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            TextField("Category (e.g., matcha, burger)", text: $vm.itemCategory)
                                .foregroundStyle(Color.coastalTextPrimary)
                                .padding()
                                .background(Color.coastalCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            ScoreSlider(value: $vm.score)

                            TextField("What was the vibe?", text: $vm.notes, axis: .vertical)
                                .foregroundStyle(Color.coastalTextPrimary)
                                .lineLimit(3...5)
                                .padding()
                                .background(Color.coastalCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            HStack(spacing: Spacing.xs) {
                                ForEach(["public", "friends", "private"], id: \.self) { value in
                                    Button {
                                        vm.privacy = value
                                    } label: {
                                        Text(value.capitalized)
                                            .font(.captionCopy)
                                            .foregroundStyle(vm.privacy == value ? Color.coastalTextPrimary : Color.coastalAqua)
                                            .padding(.vertical, Spacing.xs)
                                            .frame(maxWidth: .infinity)
                                            .background(vm.privacy == value ? Color.coastalAqua.opacity(0.35) : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .stroke(Color.coastalAqua.opacity(0.6), lineWidth: 1)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            PrimaryButton(title: "Submit Rating", isLoading: vm.isSubmitting) {
                                Task { await submitRating() }
                            }
                            .disabled(vm.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Rate \(placeName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.coastalAqua)
                }
            }
        }
    }

    private func submitRating() async {
        do {
            _ = try await vm.submit(using: session.api, placeID: placeID)
            session.showSuccess("Rating submitted")
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onSubmit()
            dismiss()
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}

// MARK: - Add to List Sheet

struct AddToListSheet: View {
    let placeID: UUID
    let placeName: String
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var lists: [ListResponse] = []
    @State private var isLoading = true
    @State private var showCreateList = false
    @State private var newListName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if lists.isEmpty {
                    Text("No lists yet. Create one below.")
                        .font(.bodyCopy)
                        .foregroundStyle(Color.coastalTextSecondary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(lists) { list in
                                Button {
                                    Task { await addToList(list.id) }
                                } label: {
                                    GlassCard {
                                        HStack {
                                            Text(list.name)
                                                .font(.cardTitle)
                                                .foregroundStyle(Color.coastalTextPrimary)
                                            Spacer()
                                            Text("\(list.itemCount) places")
                                                .font(.captionCopy)
                                                .foregroundStyle(Color.coastalTextSecondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }

                if showCreateList {
                    HStack(spacing: Spacing.xs) {
                        TextField("New list name", text: $newListName)
                            .foregroundStyle(Color.coastalTextPrimary)
                            .padding()
                            .background(Color.coastalCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Button("Create") {
                            Task { await createAndAdd() }
                        }
                        .font(.captionCopy)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.coastalCoral)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, Spacing.md)
                } else {
                    Button {
                        showCreateList = true
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "plus")
                            Text("New List")
                        }
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalAqua)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.top, Spacing.md)
            .navigationTitle("Add to List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.coastalAqua)
                }
            }
        }
        .task {
            isLoading = true
            defer { isLoading = false }
            do { lists = try await session.api.myLists() } catch {}
        }
    }

    private func addToList(_ listID: UUID) async {
        do {
            try await session.api.addListItem(listID: listID, placeID: placeID)
            session.showSuccess("Added to list")
            dismiss()
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func createAndAdd() async {
        let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            let list = try await session.api.createList(name: name, description: nil, isPublic: true)
            try await session.api.addListItem(listID: list.id, placeID: placeID)
            session.showSuccess("Added to \(name)")
            dismiss()
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}
