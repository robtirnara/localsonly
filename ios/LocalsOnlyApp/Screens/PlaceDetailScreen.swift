import SwiftUI

/// `spot-detail` canvas (`3bb06f06-…`): hero + overlapping info card, ranked tastes, local chatter, sticky **Rate a Taste**.
struct PlaceDetailScreen: View {
    let placeID: UUID

    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var place: PlaceResponse?
    @State private var ratings: [PlaceRatingResponse] = []
    @State private var isLoading = true
    @State private var galleryPage = 0
    @State private var fullScreenPhotoURL: String?
    @State private var showRatingSheet = false
    @State private var showAddToListSheet = false
    @State private var cosignCounts: [UUID: (count: Int, byMe: Bool)] = [:]
    @State private var prefillItemName = ""

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

    private var rankedTastes: [RankedTasteAggregate] {
        let grouped = Dictionary(grouping: ratings, by: { $0.itemName.lowercased() })
        return grouped.map { _, items in
            let sorted = items.sorted { $0.score > $1.score }
            let first = sorted[0]
            let avg = items.map(\.score).reduce(0, +) / Double(items.count)
            let note = sorted.first(where: { !$0.notes.isEmpty })?.notes
            let photo = sorted.first(where: { $0.photoURL != nil })?.photoURL
            return RankedTasteAggregate(
                id: first.itemName,
                itemName: first.itemName,
                avgScore: avg,
                ratingsCount: items.count,
                sampleNote: note,
                photoURL: photo
            )
        }
        .sorted { $0.avgScore > $1.avgScore }
    }

    private var raterDisplayNames: [String] {
        Array(Set(ratings.map(\.userDisplayName))).sorted()
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        sheetDragHandle
                        ZStack(alignment: .top) {
                            heroSection
                            mainCard
                                .padding(.top, PlaceDetailMetrics.heroOverlapTop)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .background(Color.feedCanvasSand)

                stickyRateCTA
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .refreshable { await load() }
        }
        .sheet(isPresented: $showRatingSheet) {
            InlineRatingSheet(
                placeID: placeID,
                placeName: place?.name ?? "",
                placeCategory: place?.category ?? "food",
                prefillItemName: prefillItemName
            ) {
                prefillItemName = ""
                Task { await load() }
            }
            .environmentObject(session)
            .presentationDetents([.large])
            .presentationBackground(Color.feedCanvasSand)
        }
        .sheet(isPresented: $showAddToListSheet) {
            AddToListSheet(placeID: placeID, placeName: place?.name ?? "")
                .environmentObject(session)
                .presentationDetents([.medium])
                .presentationBackground(Color.feedCanvasSand)
        }
        .fullScreenCover(item: Binding(
            get: { fullScreenPhotoURL.map { IdentifiableString(value: $0) } },
            set: { fullScreenPhotoURL = $0?.value }
        )) { item in
            FullScreenPhotoViewer(imageURL: item.value)
        }
        .task { await load() }
    }

    private var sheetDragHandle: some View {
        Capsule()
            .fill(Color.feedCanvasConcrete.opacity(0.35))
            .frame(width: 40, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        ZStack(alignment: .top) {
            Group {
                if isLoading {
                    Color.feedCanvasHeroPlaceholder
                } else if photoURLs.isEmpty {
                    PlaceholderHeroView(category: place?.category ?? "food", height: PlaceDetailMetrics.heroHeight)
                } else if photoURLs.count == 1 {
                    heroImage(photoURLs[0])
                } else {
                    TabView(selection: $galleryPage) {
                        ForEach(Array(photoURLs.enumerated()), id: \.offset) { idx, url in
                            heroImage(url).tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                }
            }
            .frame(height: PlaceDetailMetrics.heroHeight)
            .frame(maxWidth: .infinity)
            .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.5), .clear, Color.black.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: PlaceDetailMetrics.heroHeight)

            HStack {
                Button {
                    session.dismissDetailSheet()
                } label: {
                    heroChromeButton(icon: "chevron.down")
                }
                .accessibilityLabel("Close")

                Spacer()

                if let place {
                    ShareLink(item: shareText(for: place)) {
                        heroChromeButton(icon: "square.and.arrow.up")
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    Task { await session.toggleBookmark(placeID: placeID) }
                } label: {
                    heroChromeButton(
                        icon: session.bookmarkedPlaceIDs.contains(placeID) ? "bookmark.fill" : "bookmark"
                    )
                }
                .accessibilityLabel("Bookmark")
                .contextMenu {
                    Button {
                        showAddToListSheet = true
                    } label: {
                        Label("Add to List", systemImage: "folder.badge.plus")
                    }
                }
            }
            .padding(.horizontal, PlaceDetailMetrics.screenGutter)
            .padding(.top, PlaceDetailMetrics.chromeTopPadding)
        }
    }

    private func heroChromeButton(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.2))
            .clipShape(Circle())
    }

    @ViewBuilder
    private func heroImage(_ urlStr: String) -> some View {
        if let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: PlaceDetailMetrics.heroHeight)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .onTapGesture { fullScreenPhotoURL = urlStr }
                } else {
                    Color.feedCanvasHeroPlaceholder
                }
            }
        }
    }

    // MARK: - Main card

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.feedCanvasHeroPlaceholder)
                        .frame(height: 88)
                        .padding(.bottom, 12)
                }
            } else if let place {
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(place.name)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.feedCanvasInk)
                            .lineLimit(3)
                            .padding(.trailing, 56)

                        metaLine(for: place)
                            .padding(.top, 8)

                        ratingSocialRow
                            .padding(.top, 20)
                            .padding(.bottom, 24)

                        rankedTastesSection

                        localChatterSection
                            .padding(.top, 28)
                    }

                    if !ratings.isEmpty && avgScore >= 7.5 {
                        localFavBadge
                            .offset(y: -16)
                    }
                }
            }
        }
        .padding(.horizontal, PlaceDetailMetrics.cardHorizontalPadding)
        .padding(.top, 32)
        .padding(.bottom, PlaceDetailMetrics.cardBottomPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.feedCanvasCard)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: PlaceDetailMetrics.cardTopRadius,
                bottomLeadingRadius: PlaceDetailMetrics.cardBottomRadius,
                bottomTrailingRadius: PlaceDetailMetrics.cardBottomRadius,
                topTrailingRadius: PlaceDetailMetrics.cardTopRadius
            )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal, PlaceDetailMetrics.screenGutter)
        .padding(.bottom, PlaceDetailMetrics.scrollBottomInset)
    }

    private var localFavBadge: some View {
        HStack(spacing: 4) {
            PalmTreeShape()
                .fill(Color.white)
                .frame(width: 14, height: 16)
            Text("Local Fav")
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.feedCanvasOcean)
        .clipShape(Capsule())
        .shadow(color: Color.feedCanvasOcean.opacity(0.25), radius: 6, y: 3)
    }

    private func metaLine(for place: PlaceResponse) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(place.category.capitalized)
            dotSeparator
            Text(locationLabel(for: place))
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .foregroundStyle(Color.feedCanvasOcean)
        .lineLimit(2)
    }

    private var dotSeparator: some View {
        Circle()
            .fill(Color.feedCanvasSky)
            .frame(width: 4, height: 4)
    }

    private func locationLabel(for place: PlaceResponse) -> String {
        if let neighborhood = place.neighborhood, !neighborhood.isEmpty {
            return "\(neighborhood), \(place.city)"
        }
        return place.city
    }

    private var ratingSocialRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.feedCanvasSky)
                Text(ratings.isEmpty ? "—" : String(format: "%.1f", avgScore))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasOcean)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.feedCanvasSand)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.feedCanvasOcean.opacity(0.08), lineWidth: 1)
            )

            if !raterDisplayNames.isEmpty {
                HStack(spacing: 12) {
                    HStack(spacing: -10) {
                        ForEach(Array(raterDisplayNames.prefix(3).enumerated()), id: \.offset) { _, name in
                            raterAvatar(initials: initials(from: name))
                        }
                        if raterDisplayNames.count > 3 {
                            Text("+\(raterDisplayNames.count - 3)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.feedCanvasSky)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.feedCanvasCard, lineWidth: 2))
                        }
                    }
                    Text(friendsRatedCopy)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasConcrete)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }

            Rectangle()
                .fill(Color.feedCanvasOcean.opacity(0.08))
                .frame(height: 1)
        }
    }

    private var chatterRatings: [PlaceRatingResponse] {
        ratings
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            .prefix(8)
            .map { $0 }
    }

    private var friendsRatedCopy: String {
        let names = raterDisplayNames
        guard let first = names.first else { return "" }
        let others = max(0, names.count - 1)
        if others == 0 { return "\(first) rated" }
        return "\(first) and \(others) friends rated"
    }

    private func raterAvatar(initials: String) -> some View {
        Text(initials)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(Color.feedCanvasOcean)
            .frame(width: 32, height: 32)
            .background(Color.feedCanvasSand)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.feedCanvasCard, lineWidth: 2))
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    // MARK: - Top ranked tastes

    @ViewBuilder
    private var rankedTastesSection: some View {
        HStack(alignment: .bottom) {
            Text("Top Ranked Tastes")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
            Spacer()
            if rankedTastes.count > 3 {
                Button("See all") {}
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasOcean)
                    .disabled(true)
            }
        }
        .padding(.bottom, 16)

        if rankedTastes.isEmpty {
            Text("No tastes ranked yet — be the first.")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasConcrete)
        } else {
            VStack(spacing: 12) {
                ForEach(rankedTastes.prefix(6)) { taste in
                    RankedTasteRow(taste: taste) {
                        prefillItemName = taste.itemName
                        showRatingSheet = true
                    }
                }
            }
        }
    }

    // MARK: - Local chatter

    @ViewBuilder
    private var localChatterSection: some View {
        HStack(spacing: 8) {
            Text("Local Chatter")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.feedCanvasSky)
        }
        .padding(.bottom, 16)

        if ratings.isEmpty {
            Text("No reviews yet.")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasConcrete)
        } else {
            VStack(spacing: 16) {
                ForEach(chatterRatings) { rating in
                    LocalChatterCard(
                        rating: rating,
                        cosignCount: cosignCounts[rating.id]?.count ?? 0,
                        cosignedByMe: cosignCounts[rating.id]?.byMe ?? false,
                        onCosign: { toggleCosign(for: rating) }
                    )
                }
            }
        }
    }

    private var stickyRateCTA: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.feedCanvasCard.opacity(0), Color.feedCanvasCard, Color.feedCanvasCard],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)

            Button {
                prefillItemName = ""
                showRatingSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 20, weight: .bold))
                    Text("Rate a Taste")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.feedCanvasOcean)
                .clipShape(Capsule())
                .shadow(color: Color.feedCanvasOcean.opacity(0.3), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, PlaceDetailMetrics.screenGutter)
            .padding(.bottom, PlaceDetailMetrics.ctaBottomPadding)
            .background(Color.feedCanvasCard)
        }
    }

    private func shareText(for place: PlaceResponse) -> String {
        "Check out \(place.name) on localsonly! \(place.category.capitalized) in \(place.city)"
    }

    private func toggleCosign(for rating: PlaceRatingResponse) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let info = cosignCounts[rating.id]
        let count = info?.count ?? 0
        let byMe = info?.byMe ?? false
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

// MARK: - Canvas layout (same file as screen)

private enum PlaceDetailMetrics {
    static let heroHeight: CGFloat = 300
    static let heroOverlapTop: CGFloat = 232
    /// Inset of the floating card from screen edges (sand visible on sides).
    static let screenGutter: CGFloat = 20
    static let chromeTopPadding: CGFloat = 8
    static let cardHorizontalPadding: CGFloat = 20
    static let cardTopRadius: CGFloat = 32
    static let cardBottomRadius: CGFloat = 28
    static let cardBottomPadding: CGFloat = 28
    /// Space for sticky CTA only (sheet sits above tab bar).
    static let scrollBottomInset: CGFloat = 88
    static let ctaBottomPadding: CGFloat = 12
}

private struct RankedTasteAggregate: Identifiable {
    let id: String
    let itemName: String
    let avgScore: Double
    let ratingsCount: Int
    let sampleNote: String?
    let photoURL: String?
}

private struct RankedTasteRow: View {
    let taste: RankedTasteAggregate
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            tasteThumb
            VStack(alignment: .leading, spacing: 4) {
                Text(taste.itemName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.feedCanvasSky)
                        Text(String(format: "%.1f", taste.avgScore))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.feedCanvasOcean)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.feedCanvasCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.feedCanvasOcean.opacity(0.08), lineWidth: 1)
                    )
                    Text("\(taste.ratingsCount) ratings")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasConcrete)
                }
                if let note = taste.sampleNote, !note.isEmpty {
                    Text("\"\(note)\"")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasOcean)
                        .lineLimit(2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.feedCanvasSky.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            Spacer(minLength: 0)
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.feedCanvasOcean)
                    .frame(width: 40, height: 40)
                    .background(Color.feedCanvasCard)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.feedCanvasOcean.opacity(0.1), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rate \(taste.itemName)")
        }
        .padding(12)
        .background(Color.feedCanvasSand.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.feedCanvasOcean.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var tasteThumb: some View {
        Group {
            if let urlStr = taste.photoURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.feedCanvasHeroPlaceholder
                    }
                }
            } else {
                Color.feedCanvasHeroPlaceholder
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct LocalChatterCard: View {
    @EnvironmentObject private var session: SessionManager
    let rating: PlaceRatingResponse
    let cosignCount: Int
    let cosignedByMe: Bool
    var onCosign: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(initials(from: rating.userDisplayName))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasOcean)
                    .frame(width: 40, height: 40)
                    .background(Color.feedCanvasSand)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Button {
                        session.presentUserProfile(rating.userID)
                    } label: {
                        Text(rating.userDisplayName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.feedCanvasInk)
                    }
                    .buttonStyle(.plain)
                    HStack(spacing: 4) {
                        Text(rating.itemName)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.feedCanvasConcrete)
                        if let createdAt = rating.createdAt {
                            Text("• \(createdAt.relativeString)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.feedCanvasConcrete)
                        }
                    }
                }
                Spacer()
                PalmTreeShape()
                    .fill(Color.feedCanvasSky)
                    .frame(width: 18, height: 20)
            }

            if !rating.notes.isEmpty {
                Text("\"\(rating.notes)\"")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Rated \(rating.itemName) \(String(format: "%.1f", rating.score))")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasConcrete)
            }

            Button(action: onCosign) {
                HStack(spacing: 4) {
                    Text("👍")
                    Text(cosignCount > 0 ? "\(cosignCount) Locals agree" : "Cosign")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.feedCanvasOcean)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.feedCanvasCard)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.feedCanvasOcean.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.feedCanvasSand.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.feedCanvasOcean.opacity(0.08), lineWidth: 1)
        )
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        return String(parts.prefix(2).compactMap(\.first)).uppercased()
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
    var prefillItemName: String = ""
    var onSubmit: () -> Void

    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = RateViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    TextField("What did you try?", text: $vm.itemName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasInk)
                        .padding()
                        .background(Color.feedCanvasCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    TextField("Category (e.g., matcha, burger)", text: $vm.itemCategory)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasInk)
                        .padding()
                        .background(Color.feedCanvasCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    ScoreSlider(value: $vm.score)

                    TextField("What was the vibe?", text: $vm.notes, axis: .vertical)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasInk)
                        .lineLimit(3...5)
                        .padding()
                        .background(Color.feedCanvasCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    HStack(spacing: Spacing.xs) {
                        ForEach(["public", "friends", "private"], id: \.self) { value in
                            Button { vm.privacy = value } label: {
                                Text(value.capitalized)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(vm.privacy == value ? Color.feedCanvasInk : Color.feedCanvasOcean)
                                    .padding(.vertical, Spacing.xs)
                                    .frame(maxWidth: .infinity)
                                    .background(vm.privacy == value ? Color.feedCanvasSky.opacity(0.25) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color.feedCanvasOcean.opacity(0.2), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        Task { await submitRating() }
                    } label: {
                        Text("Submit Rating")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.feedCanvasOcean)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSubmitting)
                }
                .padding(Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.feedCanvasSand)
            .navigationTitle("Rate \(placeName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.feedCanvasOcean)
                }
            }
            .onAppear {
                if !prefillItemName.isEmpty {
                    vm.itemName = prefillItemName
                }
                if vm.itemCategory.isEmpty {
                    vm.itemCategory = placeCategory
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
                    ProgressView().padding()
                } else if lists.isEmpty {
                    Text("No lists yet. Create one below.")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasConcrete)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(lists) { list in
                                Button {
                                    Task { await addToList(list.id) }
                                } label: {
                                    HStack {
                                        Text(list.name)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.feedCanvasInk)
                                        Spacer()
                                        Text("\(list.itemCount) places")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color.feedCanvasConcrete)
                                    }
                                    .padding()
                                    .background(Color.feedCanvasCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                            .padding()
                            .background(Color.feedCanvasCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Button("Create") { Task { await createAndAdd() } }
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.feedCanvasOcean)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, Spacing.md)
                } else {
                    Button { showCreateList = true } label: {
                        Label("New List", systemImage: "plus")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.feedCanvasOcean)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.top, Spacing.md)
            .background(Color.feedCanvasSand)
            .navigationTitle("Add to List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.feedCanvasOcean)
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
