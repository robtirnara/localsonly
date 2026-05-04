import Foundation

struct AuthSendCodeRequest: Codable {
    let phoneE164: String
}

struct AuthSendCodeResponse: Codable {
    let ok: Bool
    let devCode: String
}

struct AuthVerifyCodeRequest: Codable {
    let phoneE164: String
    let code: String
    let displayName: String?
    let inviteCode: String?
}

struct AuthVerifyCodeResponse: Codable {
    let token: String
    let userID: UUID
    let displayName: String
}

struct EligibilityCheckRequest: Codable {
    let coarseAreaCode: String?
    let latitude: Double?
    let longitude: Double?
}

struct EligibilityStatusResponse: Codable {
    let accountTrustScore: Double
    let localityScore: Double
    let abuseRiskScore: Double
    let interactionEligibilityState: String
    let reasonCodes: [String]
}

struct PlaceResponse: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let neighborhood: String?
    let category: String
    let city: String
    let coverPhotoURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, neighborhood, category, city
        case coverPhotoURL = "cover_photo_url"
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

struct PlaceSuggestRequest: Codable {
    let name: String
    let neighborhood: String?
    let category: String
    let city: String?
}

struct RatingResponse: Codable, Identifiable {
    let id: UUID
    let placeID: UUID
    let placeName: String?
    let itemName: String?
    let itemCategory: String?
    let score: Double
    let notes: String
    let privacy: String
    let photoURL: String?
    let createdAt: Date?
}

struct CreateRatingRequest: Codable {
    let placeID: UUID
    let itemName: String
    let itemCategory: String
    let score: Double
    let notes: String?
    let visitDate: Date?
    let privacy: String
    let photoURL: String?
}

struct UpdateRatingRequest: Codable {
    let score: Double?
    let itemName: String?
    let itemCategory: String?
    let notes: String?
    let visitDate: Date?
    let privacy: String?
    let photoURL: String?
}

struct FeedEventResponse: Codable, Identifiable {
    var id: UUID { ratingID }
    let actorDisplayName: String
    let actorUserID: UUID
    let ratingID: UUID
    let placeID: UUID
    let placeName: String
    let itemName: String
    let score: Double
    let visibility: String
    let photoURL: String?
    let createdAt: Date
}

struct PlaceRatingResponse: Codable, Identifiable {
    let id: UUID
    let userID: UUID
    let userDisplayName: String
    let itemName: String
    let itemCategory: String
    let score: Double
    let notes: String
    let photoURL: String?
    let createdAt: Date?
}

struct PopularPlaceResponse: Codable, Identifiable {
    var id: UUID { placeID }
    let placeID: UUID
    let placeName: String
    let category: String
    let neighborhood: String?
    let averageScore: Double
    let ratingsCount: Int
    let coverPhotoURL: String?
}

struct UserProfileResponse: Codable, Identifiable {
    let id: UUID
    let displayName: String
    let bio: String
    let avatarURL: String?
    let homeCity: String
}

struct UpdateMyProfileRequest: Codable {
    let displayName: String?
    let bio: String?
    let avatarURL: String?
}

struct UploadResponse: Codable {
    let url: String
}

struct UserSearchResponse: Codable, Identifiable {
    let id: UUID
    let displayName: String
    let avatarURL: String?
    let homeCity: String
}

struct FriendResponse: Codable, Identifiable {
    var id: UUID { userID }
    let userID: UUID
    let displayName: String
    let avatarURL: String?
    let homeCity: String
    let status: String
}

struct FriendRequestPayload: Codable {
    let userID: UUID
}

struct PlaceMapResponse: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String
    let neighborhood: String?
    let latitude: Double
    let longitude: Double
    let averageScore: Double?
    let ratingsCount: Int
    let coverPhotoURL: String?
}

struct TagResponse: Codable, Identifiable {
    let id: UUID
    let slug: String
    let displayName: String
}

struct PopularTagResponse: Codable {
    let slug: String
    let displayName: String
    let usageCount: Int
}

struct AddTagsRequest: Codable {
    let tags: [String]
}

struct UserNavigationID: Hashable {
    let id: UUID
}

struct AdminUserResponse: Codable, Identifiable {
    let id: UUID
    let displayName: String
    let homeCity: String
    let isPostingFrozen: Bool
    let isUnderReview: Bool
    let createdAt: Date?
}

struct AdminRatingResponse: Codable, Identifiable {
    let id: UUID
    let userDisplayName: String
    let placeName: String
    let itemName: String
    let score: Double
    let privacy: String
    let isSuppressed: Bool
    let createdAt: Date?
}

struct AdminReasonPayload: Codable {
    let reason: String
}

// MARK: - Bookmarks

struct BookmarkedPlaceResponse: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String
    let neighborhood: String?
    let city: String
    let coverPhotoURL: String?
    let savedAt: Date
}

// MARK: - Lists

struct ListResponse: Codable, Identifiable {
    let id: UUID
    let userID: UUID
    let userName: String
    let name: String
    let description: String
    let isPublic: Bool
    let itemCount: Int
    let createdAt: Date
}

struct ListDetailResponse: Codable, Identifiable {
    let id: UUID
    let userID: UUID
    let userName: String
    let name: String
    let description: String
    let isPublic: Bool
    let items: [ListItemResponse]
    let createdAt: Date
}

struct ListItemResponse: Codable {
    let placeID: UUID
    let placeName: String
    let category: String
    let neighborhood: String?
    let coverPhotoURL: String?
    let note: String
    let sortOrder: Int
}

struct CreateListRequest: Codable {
    let name: String
    let description: String?
    let isPublic: Bool?
}

struct AddListItemRequest: Codable {
    let placeID: UUID
    let note: String?
    let sortOrder: Int?
}

// MARK: - Cosigns

struct CosignCountResponse: Codable {
    let ratingID: UUID
    let count: Int
    let cosignedByMe: Bool
}

// MARK: - Notifications

struct NotificationResponse: Codable, Identifiable {
    let id: UUID
    let type: String
    let title: String
    let body: String
    let referenceID: UUID?
    let isRead: Bool
    let createdAt: Date
}

struct UnreadCountResponse: Codable {
    let count: Int
}

// MARK: - Invites

struct InviteCodeResponse: Codable {
    let code: String
    let usedCount: Int
}

struct InvitedUserResponse: Codable, Identifiable {
    var id: UUID { userID }
    let userID: UUID
    let displayName: String
    let joinedAt: Date?
}

// MARK: - Neighborhoods

struct NeighborhoodResponse: Codable {
    let neighborhood: String
    let placeCount: Int
    let coverPhotoURL: String?
}

// MARK: - Item Search

struct ItemSearchResponse: Codable, Identifiable {
    var id: String { "\(placeID)-\(itemName)" }
    let placeID: UUID
    let placeName: String
    let category: String
    let neighborhood: String?
    let coverPhotoURL: String?
    let itemName: String
    let averageScore: Double
    let ratingsCount: Int
}
