import Fluent
import Foundation
import Vapor

final class UserModel: Model, Content {
    static let schema = "users"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?

    @Field(key: "phone_e164")
    var phoneE164: String

    @Field(key: "display_name")
    var displayName: String

    @Field(key: "bio")
    var bio: String

    @OptionalField(key: "avatar_url")
    var avatarURL: String?

    @Field(key: "home_city")
    var homeCity: String

    @OptionalField(key: "inviter_user_id")
    var inviterUserID: UUID?

    @Field(key: "is_posting_frozen")
    var isPostingFrozen: Bool

    @Field(key: "is_under_review")
    var isUnderReview: Bool

    @Timestamp(key: "created_at", on: .none)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .none)
    var updatedAt: Date?

    init() {}

    init(id: UUID, phoneE164: String, displayName: String, inviterUserID: UUID?) {
        self.id = id
        self.phoneE164 = phoneE164
        self.displayName = displayName
        self.bio = ""
        self.avatarURL = nil
        self.homeCity = "SanDiego"
        self.inviterUserID = inviterUserID
        self.isPostingFrozen = false
        self.isUnderReview = false
    }
}

final class InviteModel: Model {
    static let schema = "invites"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?

    @Field(key: "code")
    var code: String

    @Field(key: "inviter_user_id")
    var inviterUserID: UUID

    @OptionalField(key: "invitee_user_id")
    var inviteeUserID: UUID?

    @Field(key: "status")
    var status: String

    init() {}
}

final class SessionTokenModel: Model {
    static let schema = "user_sessions"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?

    @Field(key: "token")
    var token: String

    @Field(key: "user_id")
    var userID: UUID

    @Field(key: "expires_at")
    var expiresAt: Date

    @Field(key: "created_at")
    var createdAt: Date

    @OptionalField(key: "revoked_at")
    var revokedAt: Date?

    init() {}

    init(id: UUID, token: String, userID: UUID, expiresAt: Date) {
        self.id = id
        self.token = token
        self.userID = userID
        self.expiresAt = expiresAt
        self.createdAt = Date()
        self.revokedAt = nil
    }
}

final class PlaceModel: Model, Content {
    static let schema = "places"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?

    @OptionalField(key: "external_source")
    var externalSource: String?

    @OptionalField(key: "external_id")
    var externalID: String?

    @Field(key: "name")
    var name: String

    @OptionalField(key: "neighborhood")
    var neighborhood: String?

    @Field(key: "category")
    var category: String

    @Field(key: "city")
    var city: String

    @OptionalField(key: "latitude")
    var latitude: Double?

    @OptionalField(key: "longitude")
    var longitude: Double?

    @OptionalField(key: "cover_photo_url")
    var coverPhotoURL: String?

    @Timestamp(key: "created_at", on: .none)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .none)
    var updatedAt: Date?

    init() {}
}

final class RatingModel: Model, Content {
    static let schema = "ratings"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?

    @Field(key: "user_id")
    var userID: UUID

    @Field(key: "place_id")
    var placeID: UUID

    @Field(key: "score")
    var score: Double

    @Field(key: "notes")
    var notes: String

    @Field(key: "item_name")
    var itemName: String

    @Field(key: "item_category")
    var itemCategory: String

    @OptionalField(key: "visit_date")
    var visitDate: Date?

    @Field(key: "privacy")
    var privacy: String

    @Field(key: "is_suppressed")
    var isSuppressed: Bool

    @OptionalField(key: "photo_url")
    var photoURL: String?

    @Timestamp(key: "created_at", on: .none)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .none)
    var updatedAt: Date?

    init() {}
}

final class FeedEventModel: Model {
    static let schema = "feed_events"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?

    @Field(key: "actor_user_id")
    var actorUserID: UUID

    @Field(key: "event_type")
    var eventType: String

    @Field(key: "subject_type")
    var subjectType: String

    @Field(key: "subject_id")
    var subjectID: UUID

    @Field(key: "city")
    var city: String

    @Field(key: "visibility")
    var visibility: String

    @Field(key: "created_at")
    var createdAt: Date

    init() {}
}

final class EligibilitySnapshotModel: Model {
    static let schema = "eligibility_snapshots"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?

    @Field(key: "user_id")
    var userID: UUID

    @Field(key: "account_trust_score")
    var accountTrustScore: Double

    @Field(key: "locality_score")
    var localityScore: Double

    @Field(key: "abuse_risk_score")
    var abuseRiskScore: Double

    @Field(key: "interaction_eligibility_state")
    var interactionEligibilityState: String

    @Field(key: "reason_codes")
    var reasonCodes: [String]

    @Field(key: "evaluated_at")
    var evaluatedAt: Date

    init() {}
}

final class EligibilityEvidenceModel: Model {
    static let schema = "eligibility_evidence"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?

    @Field(key: "user_id")
    var userID: UUID

    @Field(key: "source_type")
    var sourceType: String

    @OptionalField(key: "coarse_area_code")
    var coarseAreaCode: String?

    @Field(key: "evidence_summary")
    var evidenceSummary: [String: String]

    @Field(key: "confidence_delta")
    var confidenceDelta: Double

    @Field(key: "created_at")
    var createdAt: Date

    init() {}
}

final class ModerationActionModel: Model {
    static let schema = "moderation_actions"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?

    @Field(key: "user_id")
    var userID: UUID

    @Field(key: "action_type")
    var actionType: String

    @Field(key: "actor_type")
    var actorType: String

    @OptionalField(key: "actor_id")
    var actorID: UUID?

    @Field(key: "reason")
    var reason: String

    @Field(key: "metadata")
    var metadata: [String: String]

    @Field(key: "created_at")
    var createdAt: Date

    init() {}
}

final class AppealModel: Model {
    static let schema = "appeals"

    @ID(custom: "id", generatedBy: .user)
    var id: UUID?

    @Field(key: "user_id")
    var userID: UUID

    @OptionalField(key: "eligibility_snapshot_id")
    var eligibilitySnapshotID: UUID?

    @Field(key: "status")
    var status: String

    @Field(key: "user_statement")
    var userStatement: String

    @Field(key: "resolution_note")
    var resolutionNote: String

    @Field(key: "created_at")
    var createdAt: Date

    @Field(key: "updated_at")
    var updatedAt: Date

    init() {}
}
