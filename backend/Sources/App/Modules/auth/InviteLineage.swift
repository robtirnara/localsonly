import Foundation

struct InviteLineage: Codable {
    let inviteCode: String
    let inviterUserID: UUID
    let inviteeUserID: UUID?
    let status: String
    let redeemedAt: Date?
}

enum InviteTrustPolicy {
    // Invite lineage is used as a trust/locality signal, not as definitive proof.
    static let maxLineageDepthForPositiveBoost = 2
}
