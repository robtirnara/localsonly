import PhotosUI
import SwiftUI
import UIKit

/// `log-spot` canvas parity: place → photo (square) → wave score → vibe chips → notes; header X / Log a Spot / Post.
private enum RateScreenMetrics {
    static let horizontalPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 32
    static let cardCorner: CGFloat = 24
    static let photoCorner: CGFloat = 32
}

struct RateScreen: View {
    private let defaultSuggestions = ["matcha", "coffee", "cocktail", "taco", "burger", "pizza", "dessert", "ramen", "smoothie", "pastry"]

    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = RateViewModel()
    @FocusState private var focusedField: Field?
    @State private var showSuccess = false
    @State private var lastRanking: String?
    @State private var availableTags: [PopularTagResponse] = []
    @State private var photoPreview: UIImage?

    private enum Field {
        case itemName
        case category
        case notes
        case placeSearch
    }

    private var canPost: Bool {
        session.selectedPlace != nil
            && !vm.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: RateScreenMetrics.sectionSpacing) {
                        placeSelectionSection
                        itemCard
                        photoSection
                        RateWavesPicker(score: $vm.score)
                            .onChange(of: vm.score) { _, _ in trackUnsaved() }
                        tagSection
                        reviewCard
                        moreOptionsSection
                    }
                    .padding(.horizontal, RateScreenMetrics.horizontalPadding)
                    .padding(.top, Spacing.xxs)
                    .padding(.bottom, Spacing.md + Spacing.tabBarScrollBottomInset)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(Color.feedCanvasSand)

                if showSuccess {
                    successOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSuccess)
            .safeAreaInset(edge: .top, spacing: 0) {
                rateHeaderChrome
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: vm.placeQuery) { _, _ in
                guard session.selectedPlace == nil else { return }
                vm.debouncePlaceSearch(using: session.api)
            }
            .onChange(of: vm.itemCategory) { _, _ in
                vm.debounceCategorySearch(using: session.api)
            }
        }
    }

    private var showPlaceSuggestions: Bool {
        session.selectedPlace == nil
            && !vm.placeQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (vm.isSearchingPlaces || !vm.placeResults.isEmpty)
    }

    private var showCategorySuggestions: Bool {
        focusedField == .category
            && !vm.itemCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (vm.isSearchingCategories || !vm.categoryResults.isEmpty)
    }

    // MARK: - Header

    private var rateHeaderChrome: some View {
        HStack(alignment: .center) {
            Button(action: dismissRateFlow) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.feedCanvasInk)
                    .frame(width: 40, height: 40)
                    .background(Color.feedCanvasCard)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer(minLength: 8)

            Text("Log a Spot")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)

            Spacer(minLength: 8)

            Button {
                guard let place = session.selectedPlace else { return }
                Task { await submitRating(placeID: place.id) }
            } label: {
                Text("Post")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(canPost && !vm.isSubmitting ? Color.feedCanvasOcean : Color.feedCanvasConcrete)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.plain)
            .disabled(!canPost || vm.isSubmitting)
            .accessibilityLabel("Post rating")
        }
        .padding(.horizontal, RateScreenMetrics.horizontalPadding)
        .padding(.top, 6)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.feedCanvasSand.opacity(0.92))
                .ignoresSafeArea(edges: .top)
        }
    }

    // MARK: - Place

    private var placeSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            placeCard

            if let place = session.selectedPlace {
                Text(placeAddressLine(place))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasConcrete)
                    .padding(.horizontal, 4)
            }

            if showPlaceSuggestions {
                placeSuggestionsList
            }
        }
    }

    private var placeSuggestionsList: some View {
        VStack(spacing: 0) {
            if vm.isSearchingPlaces, vm.placeResults.isEmpty {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .tint(Color.feedCanvasOcean)
                    Text("Searching places…")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasConcrete)
                    Spacer()
                }
                .padding(14)
            }

            ForEach(vm.placeResults.prefix(8)) { place in
                Button {
                    selectPlace(place)
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.feedCanvasOcean)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.feedCanvasInk)
                                .multilineTextAlignment(.leading)
                            Text(placeAddressLine(place))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.feedCanvasConcrete)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if place.id != vm.placeResults.prefix(8).last?.id {
                    Divider()
                        .padding(.leading, 48)
                }
            }
        }
        .background(Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
    }

    private func selectPlace(_ place: PlaceResponse) {
        session.selectedPlace = place
        vm.placeQuery = place.name
        vm.placeResults = []
        focusedField = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func placeAddressLine(_ place: PlaceResponse) -> String {
        var parts: [String] = []
        if let neighborhood = place.neighborhood, !neighborhood.isEmpty {
            parts.append(neighborhood)
        }
        if !place.city.isEmpty {
            parts.append(place.city.replacingOccurrences(of: "SanDiego", with: "San Diego"))
        }
        let location = parts.joined(separator: ", ")
        if location.isEmpty {
            return place.category.capitalized
        }
        return "\(location) · \(place.category.capitalized)"
    }

    private var placeCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.feedCanvasOcean)

            TextField("Where are you?", text: placeBinding)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .submitLabel(.search)
                .focused($focusedField, equals: .placeSearch)
                .onSubmit {
                    Task { try? await vm.searchPlaces(using: session.api) }
                }
                .disabled(session.selectedPlace != nil)

            if session.selectedPlace != nil {
                Button("Change") {
                    let previousName = session.selectedPlace?.name ?? ""
                    session.selectedPlace = nil
                    vm.placeQuery = previousName
                    vm.placeResults = []
                    focusedField = .placeSearch
                    vm.debouncePlaceSearch(using: session.api)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: 0xF3F4F6))
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: RateScreenMetrics.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RateScreenMetrics.cardCorner, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
    }

    private var placeBinding: Binding<String> {
        Binding(
            get: { session.selectedPlace?.name ?? vm.placeQuery },
            set: { newValue in
                if session.selectedPlace != nil {
                    session.selectedPlace = nil
                }
                vm.placeQuery = newValue
            }
        )
    }

    // MARK: - Item (required for API; compact card before photo)

    private var itemCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("What did you try?")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)

            TextField("e.g., fish tacos", text: $vm.itemName)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .focused($focusedField, equals: .itemName)
                .onChange(of: vm.itemName) { _, _ in trackUnsaved() }

            TextField("Category (taco, coffee…)", text: $vm.itemCategory)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .focused($focusedField, equals: .category)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if showCategorySuggestions {
                categorySuggestionsList
            } else if vm.itemCategory.isEmpty || focusedField == .category {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(quickPickSuggestions, id: \.self) { suggestion in
                            Button {
                                vm.itemCategory = suggestion
                                vm.categoryResults = []
                                focusedField = nil
                            } label: {
                                Text(suggestion.capitalized)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.feedCanvasOcean)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.feedCanvasSky.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if !vm.itemCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !categoryMatchesTypedInput {
                Text("New category — we'll save it for other locals.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasConcrete)
            }
        }
        .padding(16)
        .background(Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: RateScreenMetrics.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RateScreenMetrics.cardCorner, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
    }

    private var categoryMatchesTypedInput: Bool {
        let typed = vm.itemCategory.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !typed.isEmpty else { return false }
        return vm.categoryResults.contains {
            $0.displayName.lowercased() == typed || $0.slug.lowercased() == typed
        }
    }

    private var categorySuggestionsList: some View {
        VStack(spacing: 0) {
            if vm.isSearchingCategories, vm.categoryResults.isEmpty {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .tint(Color.feedCanvasOcean)
                    Text("Searching categories…")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasConcrete)
                    Spacer()
                }
                .padding(14)
            }

            ForEach(vm.categoryResults) { category in
                Button {
                    vm.itemCategory = category.displayName
                    vm.categoryResults = []
                    focusedField = nil
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack {
                        Text(category.displayName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.feedCanvasInk)
                        Spacer()
                        Text("\(category.usageCount) ratings")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.feedCanvasConcrete)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if category.id != vm.categoryResults.last?.id {
                    Divider()
                }
            }
        }
        .background(Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
    }

    private var quickPickSuggestions: [String] {
        let typed = vm.itemCategory.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if typed.isEmpty {
            return Array(defaultSuggestions.prefix(8))
        }
        let filtered = defaultSuggestions.filter { $0.hasPrefix(typed) && $0 != typed }
        return Array(filtered.prefix(5))
    }

    // MARK: - Photo

    private var photoSection: some View {
        PhotosPicker(selection: $vm.selectedPhoto, matching: .images) {
            GeometryReader { geo in
                let side = geo.size.width
                ZStack {
                    RoundedRectangle(cornerRadius: RateScreenMetrics.photoCorner, style: .continuous)
                        .fill(Color.feedCanvasCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: RateScreenMetrics.photoCorner, style: .continuous)
                                .strokeBorder(
                                    Color.feedCanvasSky,
                                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                                )
                        )

                    if let photoPreview {
                        Image(uiImage: photoPreview)
                            .resizable()
                            .scaledToFill()
                            .frame(width: side, height: side)
                            .clipped()
                            .opacity(0.6)
                            .clipShape(RoundedRectangle(cornerRadius: RateScreenMetrics.photoCorner, style: .continuous))

                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.feedCanvasCard.opacity(0.85))
                                    .frame(width: 56, height: 56)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                                Image(systemName: "camera.fill.badge.plus")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(Color.feedCanvasOcean)
                            }
                            Text("Change Photo")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.feedCanvasInk)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.feedCanvasCard.opacity(0.65))
                                .clipShape(Capsule())
                        }
                    } else {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.feedCanvasCard.opacity(0.85))
                                    .frame(width: 56, height: 56)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                                Image(systemName: "camera.fill.badge.plus")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(Color.feedCanvasOcean)
                            }
                            Text("Add Photo")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.feedCanvasInk)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.feedCanvasCard.opacity(0.65))
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(width: side, height: side)
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .onChange(of: vm.selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    let compressed = compressImage(data)
                    await MainActor.run {
                        vm.photoData = compressed
                        photoPreview = UIImage(data: compressed)
                    }
                }
            }
        }
        .onChange(of: vm.photoData) { _, data in
            if data == nil {
                photoPreview = nil
            }
        }
    }

    // MARK: - Vibe tags

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vibe Check 😎")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)

            FlowLayout(spacing: 8) {
                ForEach(availableTags, id: \.slug) { tag in
                    vibeChip(tag.displayName, slug: tag.slug)
                }
                addVibeChip
            }
        }
        .task {
            do { availableTags = try await session.api.popularTags() } catch {}
        }
    }

    private func vibeChip(_ label: String, slug: String) -> some View {
        let isSelected = vm.selectedTags.contains(slug)
        return Button {
            if isSelected {
                vm.selectedTags.remove(slug)
            } else {
                vm.selectedTags.insert(slug)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : Color.feedCanvasConcrete)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.feedCanvasOcean : Color.feedCanvasCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(isSelected ? 0 : 0.05), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var addVibeChip: some View {
        Button {
            session.showInfo("More vibes coming soon.")
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text("Add Vibe")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color.feedCanvasSky)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.feedCanvasCard)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.feedCanvasSky, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notes

    private var reviewCard: some View {
        TextField(
            "Drop your thoughts... what should people order?",
            text: $vm.notes,
            axis: .vertical
        )
        .font(.system(size: 18, weight: .bold, design: .rounded))
        .foregroundStyle(Color.feedCanvasInk)
        .focused($focusedField, equals: .notes)
        .lineLimit(4...8)
        .padding(20)
        .frame(minHeight: 128, alignment: .topLeading)
        .background(Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: RateScreenMetrics.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RateScreenMetrics.cardCorner, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        .onChange(of: vm.notes) { _, _ in trackUnsaved() }
    }

    // MARK: - Visit date + privacy (not in canvas; kept for product)

    private var moreOptionsSection: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("Visit date")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                Spacer()
                DatePicker("", selection: $vm.visitDate, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .tint(Color.feedCanvasOcean)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.feedCanvasCard)
            .clipShape(RoundedRectangle(cornerRadius: RateScreenMetrics.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RateScreenMetrics.cardCorner, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Who can see this?")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                HStack(spacing: 8) {
                    privacyChip("public", description: "Everyone")
                    privacyChip("friends", description: "Friends")
                    privacyChip("private", description: "Just you")
                }
            }
        }
    }

    private func privacyChip(_ value: String, description: String) -> some View {
        let isSelected = vm.privacy == value
        return Button {
            vm.privacy = value
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 2) {
                Text(value.capitalized)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.feedCanvasOcean : Color.feedCanvasConcrete)
                Text(description)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasConcrete)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.feedCanvasSky.opacity(0.2) : Color.feedCanvasCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.feedCanvasOcean.opacity(0.35) : Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func dismissRateFlow() {
        vm.resetDraft()
        session.selectedPlace = nil
        session.hasUnsavedRating = false
        focusedField = nil
        photoPreview = nil
        session.selectedTab = .feed
    }

    private func submitRating(placeID: UUID) async {
        do {
            let rankingMessage = try await vm.submit(using: session.api, placeID: placeID)
            focusedField = nil
            session.hasUnsavedRating = false
            lastRanking = rankingMessage
            showSuccess = true
            session.showSuccess(rankingMessage ?? "Rating submitted")
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            try? await Task.sleep(for: .seconds(2.5))
            showSuccess = false
            photoPreview = nil
            session.selectedPlace = nil
            session.selectedTab = .feed
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.feedCanvasSand.opacity(0.95).ignoresSafeArea()
            VStack(spacing: Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.coastalStatusSuccess)
                Text("Rating Submitted!")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
                if let lastRanking {
                    Text(lastRanking)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasConcrete)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Spacing.xl)
        }
    }

    private func trackUnsaved() {
        session.hasUnsavedRating = !vm.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func compressImage(_ data: Data, maxDimension: CGFloat = 1200, quality: CGFloat = 0.7) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        if scale >= 1.0 { return image.jpegData(compressionQuality: quality) ?? data }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality) ?? data
    }
}

// MARK: - Wrapping chip layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentLineWidth: CGFloat = 0
        var currentLineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentLineWidth + size.width > maxWidth, currentLineWidth > 0 {
                totalHeight += currentLineHeight + spacing
                maxLineWidth = max(maxLineWidth, currentLineWidth - spacing)
                currentLineWidth = 0
                currentLineHeight = 0
            }
            currentLineWidth += size.width + spacing
            currentLineHeight = max(currentLineHeight, size.height)
        }
        totalHeight += currentLineHeight
        maxLineWidth = max(maxLineWidth, currentLineWidth - spacing)
        return CGSize(width: maxLineWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
