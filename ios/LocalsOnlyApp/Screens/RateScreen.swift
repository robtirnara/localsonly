import PhotosUI
import SwiftUI
import UIKit

struct RateScreen: View {
    private let defaultSuggestions = ["matcha", "coffee", "cocktail", "taco", "burger", "pizza", "dessert", "ramen", "smoothie", "pastry"]

    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = RateViewModel()
    @FocusState private var focusedField: Field?
    @State private var showSuccess = false
    @State private var lastRanking: String?

    private enum Field {
        case itemName
        case category
        case notes
        case placeSearch
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.coastalSand.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        photoSection

                        placeSelectionSection

                        if let place = session.selectedPlace {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                TextField("What did you try?", text: $vm.itemName)
                                    .foregroundStyle(Color.coastalTextPrimary)
                                    .focused($focusedField, equals: .itemName)
                                    .padding()
                                    .background(Color.gray.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.gray.opacity(0.12), lineWidth: 1)
                                    )
                                    .onChange(of: vm.itemName) { _, _ in trackUnsaved() }

                                categoryInput

                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    ScoreSlider(value: $vm.score)
                                }
                                .padding(Spacing.md)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                                        .stroke(Color.orange.opacity(0.08), lineWidth: 1)
                                )
                                .padding(.vertical, Spacing.xs)
                                .overlay(alignment: .top) {
                                    Divider().offset(y: -Spacing.sm)
                                }

                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("The Verdict")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.coastalTextPrimary)
                                        .padding(.leading, 4)
                                    TextField("What's the tea? Talk about the flavors, the waves, the service…", text: $vm.notes, axis: .vertical)
                                        .foregroundStyle(Color.coastalTextPrimary)
                                        .focused($focusedField, equals: .notes)
                                        .lineLimit(4...8)
                                        .padding()
                                        .background(Color.gray.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
                                        )
                                }
                                .padding(.top, Spacing.sm)
                                .overlay(alignment: .top) {
                                    Divider().offset(y: -Spacing.sm)
                                }

                                visitDateRow

                                tagSection
                                    .padding(.top, Spacing.sm)
                                    .overlay(alignment: .top) {
                                        Divider().offset(y: -Spacing.sm)
                                    }

                                privacyPicker

                                PrimaryButton(title: "Post rating", isLoading: vm.isSubmitting) {
                                    Task { await submitRating(placeID: place.id) }
                                }
                                .disabled(vm.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                }
                .scrollDismissesKeyboard(.interactively)

                if showSuccess {
                    successOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSuccess)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.resetDraft()
                        session.selectedPlace = nil
                        session.hasUnsavedRating = false
                        focusedField = nil
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.coastalTextSecondary)
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        PalmTreeShape()
                            .fill(Color.coastalInk)
                            .frame(width: 20, height: 24)
                        Text("Log Spot")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.coastalInk)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if let place = session.selectedPlace,
                       !vm.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button("Post") {
                            Task { await submitRating(placeID: place.id) }
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.coastalInk)
                        .clipShape(Capsule())
                        .disabled(vm.isSubmitting)
                    }
                }
            }
        }
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
            session.selectedPlace = nil
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.coastalBackground.opacity(0.95).ignoresSafeArea()
            VStack(spacing: Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.coastalStatusSuccess)
                Text("Rating Submitted!")
                    .font(.sectionTitle)
                    .foregroundStyle(Color.coastalTextPrimary)
                if let lastRanking {
                    Text(lastRanking)
                        .font(.bodyCopy)
                        .foregroundStyle(Color.coastalTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Spacing.xl)
        }
    }

    private var placeSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Where did you go?")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.coastalTextPrimary)
                .padding(.leading, 4)

            HStack(spacing: Spacing.sm) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.coastalCoral)
                    .font(.system(size: 22))
                TextField("Search restaurant or cafe…", text: $vm.placeQuery)
                    .foregroundStyle(Color.coastalTextPrimary)
                    .focused($focusedField, equals: .placeSearch)
                    .onSubmit {
                        Task { try? await vm.searchPlaces(using: session.api) }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
            }

            if vm.isSearchingPlaces {
                ProgressView()
            } else if !vm.placeResults.isEmpty {
                ForEach(vm.placeResults.prefix(3)) { place in
                    PlaceCard(
                        title: place.name,
                        subtitle: "\(place.category.capitalized) · \(place.city)",
                        trailingText: session.selectedPlace?.id == place.id ? "Selected" : nil
                    )
                    .onTapGesture {
                        session.selectedPlace = place
                        session.showInfo("Selected \(place.name)")
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            } else if session.selectedPlace == nil {
                Text("Search and select a place before you post.")
                    .font(.captionCopy)
                    .foregroundStyle(Color.coastalTextSecondary)
            }
        }
    }

    private var categoryInput: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            TextField("Category (e.g., matcha, burger, cocktail)", text: $vm.itemCategory)
                .foregroundStyle(Color.coastalTextPrimary)
                .focused($focusedField, equals: .category)
                .padding()
                .background(Color.coastalCard)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if vm.itemCategory.isEmpty || focusedField == .category {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(quickPickSuggestions, id: \.self) { suggestion in
                            Button {
                                vm.itemCategory = suggestion
                                focusedField = nil
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Text(suggestion.capitalized)
                                    .font(.captionCopy)
                                    .foregroundStyle(Color.coastalAqua)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs)
                                    .background(Color.coastalAqua.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var quickPickSuggestions: [String] {
        let typed = vm.itemCategory.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if typed.isEmpty {
            return Array(defaultSuggestions.prefix(8))
        }
        let filtered = defaultSuggestions.filter { $0.hasPrefix(typed) && $0 != typed }
        return Array(filtered.prefix(5))
    }

    private var visitDateRow: some View {
        HStack {
            Text("Visit date")
                .font(.bodyCopy)
                .foregroundStyle(Color.coastalTextSecondary)
            Spacer()
            DatePicker("", selection: $vm.visitDate, in: ...Date(), displayedComponents: .date)
                .labelsHidden()
                .tint(.coastalAqua)
        }
    }

    private var photoSection: some View {
        let hasPhoto = vm.photoData != nil
        let currentPhotoData = vm.photoData
        return VStack(spacing: Spacing.xs) {
            if let imageData = currentPhotoData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            vm.selectedPhoto = nil
                            vm.photoData = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .padding(Spacing.xs)
                    }
            }

            PhotosPicker(selection: $vm.selectedPhoto, matching: .images) {
                VStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                        Image(systemName: "camera.fill.badge.plus")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.coastalAqua)
                    }
                    Text(hasPhoto ? "Change photo" : "Add a glorious photo")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.coastalAqua)
                    Text("Make it crave-worthy")
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(Color.coastalSand)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.coastalAqua.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                )
            }
            .onChange(of: vm.selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        vm.photoData = compressImage(data)
                    }
                }
            }
        }
    }

    @State private var availableTags: [PopularTagResponse] = []

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.coastalAqua)
                Text("Select the Vibes")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.coastalInk)
            }
            .padding(.leading, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(availableTags, id: \.slug) { tag in
                        Button {
                            if vm.selectedTags.contains(tag.slug) {
                                vm.selectedTags.remove(tag.slug)
                            } else {
                                vm.selectedTags.insert(tag.slug)
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(tag.displayName)
                                .font(.captionCopy)
                                .fontWeight(vm.selectedTags.contains(tag.slug) ? .semibold : .regular)
                                .foregroundStyle(Color.coastalAqua)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(vm.selectedTags.contains(tag.slug) ? Color.coastalFoam : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            vm.selectedTags.contains(tag.slug) ? Color.coastalAqua : Color.gray.opacity(0.25),
                                            lineWidth: vm.selectedTags.contains(tag.slug) ? 1.5 : 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .task {
            do { availableTags = try await session.api.popularTags() } catch {}
        }
    }

    private var privacyPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Who can see this?")
                .font(.bodyCopy)
                .foregroundStyle(Color.coastalTextSecondary)
            HStack(spacing: Spacing.xs) {
                privacyButton("public", description: "Everyone")
                privacyButton("friends", description: "Friends only")
                privacyButton("private", description: "Just you")
            }
        }
    }

    private func privacyButton(_ value: String, description: String) -> some View {
        Button {
            vm.privacy = value
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 2) {
                Text(value.capitalized)
                    .font(.captionCopy)
                    .fontWeight(.medium)
                    .foregroundStyle(vm.privacy == value ? Color.coastalTextPrimary : Color.coastalAqua)
                Text(description)
                    .font(.microLabel)
                    .foregroundStyle(vm.privacy == value ? Color.coastalTextSecondary : Color.coastalTextSecondary.opacity(0.6))
            }
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
