import Foundation

struct EligibilitySnapshot: Codable {
    let userID: UUID
    let accountTrustScore: Double
    let localityScore: Double
    let abuseRiskScore: Double
    let interactionEligibilityState: EligibilityState
    let reasonCodes: [String]
    let evaluatedAt: Date
}

enum InteractionAction: String, CaseIterable {
    case createRating
    case likeRating
    case comment
    case sendFriendRequest
}

struct EligibilityCapabilities {
    static func canPerform(_ action: InteractionAction, in state: EligibilityState) -> Bool {
        switch state {
        case .browseOnly:
            return false
        case .provisionalLocal:
            return action != .comment
        case .verifiedLocal:
            return true
        case .restricted, .underReview:
            return false
        }
    }
}
