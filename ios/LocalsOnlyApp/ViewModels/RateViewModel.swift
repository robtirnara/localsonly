import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class RateViewModel: ObservableObject {
    @Published var placeQuery: String = ""
    @Published var placeResults: [PlaceResponse] = []
    @Published var isSearchingPlaces = false

    @Published var itemName: String = ""
    @Published var itemCategory: String = ""
    @Published var score: Double = 5.0
    @Published var notes: String = ""
    @Published var privacy: String = "public"
    @Published var visitDate: Date = Date()
    @Published var isSubmitting = false

    @Published var selectedPhoto: PhotosPickerItem?
    @Published var photoData: Data?

    func searchPlaces(using api: APIClient) async throws {
        isSearchingPlaces = true
        defer { isSearchingPlaces = false }
        placeResults = try await api.searchPlaces(query: placeQuery)
    }

    @Published var selectedTags: Set<String> = []

    func submit(using api: APIClient, placeID: UUID) async throws -> String? {
        isSubmitting = true
        defer { isSubmitting = false }

        let trimmedItemName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = itemCategory.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let effectiveCategory = trimmedCategory.isEmpty ? "general" : trimmedCategory

        var uploadedPhotoURL: String?
        if let photoData {
            uploadedPhotoURL = try await api.uploadImage(data: photoData)
        }

        let createdRating = try await api.createRating(
            placeID: placeID,
            itemName: trimmedItemName,
            itemCategory: effectiveCategory,
            score: score,
            notes: notes,
            privacy: privacy,
            photoURL: uploadedPhotoURL
        )

        if !selectedTags.isEmpty {
            try? await api.addTagsToRating(ratingID: createdRating.id, tags: Array(selectedTags))
        }

        let ratings = try await api.myRatings(sort: "scoreDesc")
        let categoryRatings = ratings.filter { ($0.itemCategory ?? "general").lowercased() == effectiveCategory }
        let sorted = categoryRatings.sorted { $0.score > $1.score }
        let rank = sorted.firstIndex {
            ($0.itemName ?? "").caseInsensitiveCompare(trimmedItemName) == .orderedSame && $0.placeID == placeID
        }?.advanced(by: 1)

        itemName = ""
        itemCategory = ""
        notes = ""
        selectedPhoto = nil
        photoData = nil
        selectedTags = []
        score = 5.0
        if let rank {
            return "This ranks #\(rank) out of your \(categoryRatings.count) \(effectiveCategory) ratings."
        }
        return nil
    }
}
