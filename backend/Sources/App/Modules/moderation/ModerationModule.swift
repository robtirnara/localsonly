import Fluent
import FluentSQL
import Foundation
import Vapor

struct ModerationModule: AppModule {
    let name = "moderation"

    func register(routes: RoutesBuilder, app: Application) {
        let moderation = routes.grouped("moderation").grouped(AdminGuardMiddleware())
        moderation.post("users", ":id", "flag", use: flagUser)
        moderation.post("users", ":id", "freeze-posting", use: freezePosting)
        moderation.post("users", ":id", "mark-under-review", use: markUnderReview)
        moderation.post("ratings", ":id", "suppress", use: suppressRating)

        let admin = routes.grouped("admin").grouped(AdminGuardMiddleware())
        admin.get("users", use: adminListUsers)
        admin.get("ratings", use: adminListRatings)
    }
}

private struct ModerationReasonPayload: Content {
    let reason: String
}

private func appendModerationAction(
    _ req: Request,
    userID: UUID,
    actionType: String,
    reason: String,
    metadata: [String: String] = [:]
) async throws {
    let action = ModerationActionModel()
    action.id = UUID()
    action.userID = userID
    action.actionType = actionType
    action.actorType = "admin"
    action.actorID = nil
    action.reason = reason
    action.metadata = metadata
    action.createdAt = Date()
    try await action.create(on: req.db)
}

private func flagUser(_ req: Request) async throws -> HTTPStatus {
    guard let userID = req.parameters.get("id", as: UUID.self),
          let _ = try await UserModel.find(userID, on: req.db) else {
        throw Abort(.notFound)
    }
    let payload = try req.content.decode(ModerationReasonPayload.self)
    try await appendModerationAction(req, userID: userID, actionType: "flag_user", reason: payload.reason)
    return .ok
}

private func freezePosting(_ req: Request) async throws -> HTTPStatus {
    guard let userID = req.parameters.get("id", as: UUID.self),
          let user = try await UserModel.find(userID, on: req.db) else {
        throw Abort(.notFound)
    }
    let payload = try req.content.decode(ModerationReasonPayload.self)
    user.isPostingFrozen = true
    try await user.save(on: req.db)
    try await appendModerationAction(req, userID: userID, actionType: "freeze_posting", reason: payload.reason)
    return .ok
}

private func markUnderReview(_ req: Request) async throws -> HTTPStatus {
    guard let userID = req.parameters.get("id", as: UUID.self),
          let user = try await UserModel.find(userID, on: req.db) else {
        throw Abort(.notFound)
    }
    let payload = try req.content.decode(ModerationReasonPayload.self)
    user.isUnderReview = true
    try await user.save(on: req.db)
    try await appendModerationAction(req, userID: userID, actionType: "mark_under_review", reason: payload.reason)
    return .ok
}

private func suppressRating(_ req: Request) async throws -> HTTPStatus {
    guard let ratingID = req.parameters.get("id", as: UUID.self),
          let rating = try await RatingModel.find(ratingID, on: req.db) else {
        throw Abort(.notFound)
    }
    let payload = try req.content.decode(ModerationReasonPayload.self)
    rating.isSuppressed = true
    try await rating.save(on: req.db)

    guard let userID = try await RatingModel.find(ratingID, on: req.db)?.userID else {
        throw Abort(.notFound)
    }
    try await appendModerationAction(
        req,
        userID: userID,
        actionType: "suppress_rating",
        reason: payload.reason,
        metadata: ["rating_id": ratingID.uuidString]
    )

    return .ok
}

// MARK: - Admin List Endpoints

private struct AdminUserResponse: Content {
    let id: UUID
    let displayName: String
    let homeCity: String
    let isPostingFrozen: Bool
    let isUnderReview: Bool
    let createdAt: Date?
}

private struct AdminRatingRow: Decodable {
    let id: UUID
    let user_display_name: String
    let place_name: String
    let item_name: String
    let score: Double
    let privacy: String
    let is_suppressed: Bool
    let created_at: Date
}

private struct AdminRatingResponse: Content {
    let id: UUID
    let userDisplayName: String
    let placeName: String
    let itemName: String
    let score: Double
    let privacy: String
    let isSuppressed: Bool
    let createdAt: Date?
}

private func adminListUsers(_ req: Request) async throws -> [AdminUserResponse] {
    let users = try await UserModel.query(on: req.db)
        .sort(\.$createdAt, .descending)
        .all()

    return users.compactMap { user in
        guard let id = user.id else { return nil }
        return AdminUserResponse(
            id: id,
            displayName: user.displayName,
            homeCity: user.homeCity,
            isPostingFrozen: user.isPostingFrozen,
            isUnderReview: user.isUnderReview,
            createdAt: user.createdAt
        )
    }
}

private func adminListRatings(_ req: Request) async throws -> [AdminRatingResponse] {
    guard let sql = req.db as? SQLDatabase else {
        throw Abort(.internalServerError)
    }

    let rows = try await sql.raw("""
        SELECT r.id,
               u.display_name AS user_display_name,
               p.name AS place_name,
               r.item_name,
               r.score,
               r.privacy,
               r.is_suppressed,
               r.created_at
        FROM ratings r
        JOIN users u ON u.id = r.user_id
        JOIN places p ON p.id = r.place_id
        ORDER BY r.created_at DESC
        LIMIT 50
        """).all(decoding: AdminRatingRow.self)

    return rows.map {
        AdminRatingResponse(
            id: $0.id,
            userDisplayName: $0.user_display_name,
            placeName: $0.place_name,
            itemName: $0.item_name,
            score: $0.score,
            privacy: $0.privacy,
            isSuppressed: $0.is_suppressed,
            createdAt: $0.created_at
        )
    }
}
