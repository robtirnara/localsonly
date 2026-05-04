import Fluent
import Foundation
import Vapor

struct EligibilityModule: AppModule {
    let name = "eligibility"

    func register(routes: RoutesBuilder, app: Application) {
        let authed = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware())
        authed.post("eligibility", "check", use: runEligibilityCheck)
        authed.get("eligibility", "status", use: eligibilityStatus)
        authed.post("eligibility", "appeals", use: createAppeal)
    }
}

private struct EligibilityCheckRequest: Content {
    let coarseAreaCode: String?
    let latitude: Double?
    let longitude: Double?
}

private struct EligibilityCheckResponse: Content {
    let accountTrustScore: Double
    let localityScore: Double
    let abuseRiskScore: Double
    let interactionEligibilityState: String
    let reasonCodes: [String]
}

private func runEligibilityCheck(_ req: Request) async throws -> EligibilityCheckResponse {
    guard let appUser = req.auth.get(AppUser.self),
          let user = try await UserModel.find(appUser.id, on: req.db) else {
        throw Abort(.unauthorized)
    }
    let payload = try req.content.decode(EligibilityCheckRequest.self)

    var trust = 55.0
    var locality = 50.0
    var risk = 30.0
    var reasons = ["base_scoring"]

    if user.inviterUserID != nil {
        trust += 10
        locality += 5
        reasons.append("invite_lineage")
    }
    if user.phoneE164.hasPrefix("+1") {
        locality += 5
        reasons.append("weak_phone_hint")
    }
    if payload.coarseAreaCode?.lowercased() == "sandiego" {
        locality += 20
        reasons.append("coarse_geofence_match")
    } else if payload.coarseAreaCode != nil {
        locality -= 10
        reasons.append("coarse_geofence_outside")
    }

    if user.isUnderReview { risk = max(risk, 80) }
    if user.isPostingFrozen { risk = max(risk, 90) }

    let policy = EligibilityPolicy()
    let state = policy.deriveState(input: EligibilityInput(
        accountTrustScore: trust,
        localityScore: locality,
        abuseRiskScore: risk,
        postingFrozen: user.isPostingFrozen,
        underReview: user.isUnderReview
    ))

    let snapshot = EligibilitySnapshotModel()
    snapshot.id = UUID()
    snapshot.userID = appUser.id
    snapshot.accountTrustScore = trust
    snapshot.localityScore = locality
    snapshot.abuseRiskScore = risk
    snapshot.interactionEligibilityState = state.rawValue
    snapshot.reasonCodes = reasons
    snapshot.evaluatedAt = Date()
    try await snapshot.create(on: req.db)

    let evidence = EligibilityEvidenceModel()
    evidence.id = UUID()
    evidence.userID = appUser.id
    evidence.sourceType = "coarse_geofence_result"
    evidence.coarseAreaCode = payload.coarseAreaCode
    evidence.evidenceSummary = [
        "location_policy": "transient_precise_coordinates_not_persisted",
        "had_precise_input": (payload.latitude != nil && payload.longitude != nil) ? "true" : "false"
    ]
    evidence.confidenceDelta = payload.coarseAreaCode?.lowercased() == "sandiego" ? 20 : -10
    evidence.createdAt = Date()
    try await evidence.create(on: req.db)

    return EligibilityCheckResponse(
        accountTrustScore: trust,
        localityScore: locality,
        abuseRiskScore: risk,
        interactionEligibilityState: state.rawValue,
        reasonCodes: reasons
    )
}

private func eligibilityStatus(_ req: Request) async throws -> EligibilityCheckResponse {
    guard let appUser = req.auth.get(AppUser.self) else { throw Abort(.unauthorized) }
    guard let snapshot = try await EligibilitySnapshotModel.query(on: req.db)
        .filter(\.$userID == appUser.id)
        .sort(\.$evaluatedAt, .descending)
        .first() else {
        return EligibilityCheckResponse(
            accountTrustScore: 0,
            localityScore: 0,
            abuseRiskScore: 0,
            interactionEligibilityState: EligibilityState.browseOnly.rawValue,
            reasonCodes: ["not_yet_evaluated"]
        )
    }

    return EligibilityCheckResponse(
        accountTrustScore: snapshot.accountTrustScore,
        localityScore: snapshot.localityScore,
        abuseRiskScore: snapshot.abuseRiskScore,
        interactionEligibilityState: snapshot.interactionEligibilityState,
        reasonCodes: snapshot.reasonCodes
    )
}

private struct AppealRequest: Content {
    let userStatement: String
}

private struct AppealResponse: Content {
    let id: UUID
    let status: String
}

private func createAppeal(_ req: Request) async throws -> AppealResponse {
    guard let appUser = req.auth.get(AppUser.self) else { throw Abort(.unauthorized) }
    let payload = try req.content.decode(AppealRequest.self)
    let latestSnapshot = try await EligibilitySnapshotModel.query(on: req.db)
        .filter(\.$userID == appUser.id)
        .sort(\.$evaluatedAt, .descending)
        .first()

    let appeal = AppealModel()
    appeal.id = UUID()
    appeal.userID = appUser.id
    appeal.eligibilitySnapshotID = latestSnapshot?.id
    appeal.status = "open"
    appeal.userStatement = payload.userStatement
    appeal.resolutionNote = ""
    appeal.createdAt = Date()
    appeal.updatedAt = Date()
    try await appeal.create(on: req.db)

    let action = ModerationActionModel()
    action.id = UUID()
    action.userID = appUser.id
    action.actionType = "open_appeal"
    action.actorType = "system"
    action.actorID = nil
    action.reason = "user_submitted_appeal"
    action.metadata = [:]
    action.createdAt = Date()
    try await action.create(on: req.db)

    return AppealResponse(id: appeal.id!, status: appeal.status)
}
