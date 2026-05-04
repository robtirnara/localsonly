import Foundation

enum ModerationActionType: String, CaseIterable, Codable {
    case flagUser = "flag_user"
    case freezePosting = "freeze_posting"
    case unfreezePosting = "unfreeze_posting"
    case markUnderReview = "mark_under_review"
    case clearUnderReview = "clear_under_review"
    case suppressRating = "suppress_rating"
    case openAppeal = "open_appeal"
    case resolveAppeal = "resolve_appeal"
}

struct ModerationActionRecord: Codable {
    let id: UUID
    let userID: UUID
    let actionType: ModerationActionType
    let actorType: String
    let actorID: UUID?
    let reason: String
    let createdAt: Date
}

struct RatingSuppressionRecord: Codable {
    let ratingID: UUID
    let isSuppressedFromPublic: Bool
    let suppressionReason: String
    let suppressedAt: Date?
}
