import Fluent
import FluentSQL
import Foundation
import Vapor

struct FriendshipsModule: AppModule {
    let name = "friendships"

    func register(routes: RoutesBuilder, app: Application) {
        let authed = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware())
        authed.get("friends", use: listFriends)
        authed.get("friends", "pending", use: pendingRequests)

        let contributors = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware(), EligibilityGuardMiddleware())
        contributors.post("friends", "request", use: requestFriend)
        contributors.post("friends", ":id", "accept", use: acceptFriend)
    }
}

private struct FriendRequestPayload: Content {
    let userID: UUID
}

private struct FriendResponse: Content {
    let userID: UUID
    let displayName: String
    let avatarURL: String?
    let homeCity: String
    let status: String
}

private func requestFriend(_ req: Request) async throws -> HTTPStatus {
    guard let appUser = req.auth.get(AppUser.self) else { throw Abort(.unauthorized) }
    guard let sql = req.db as? SQLDatabase else {
        throw Abort(.internalServerError)
    }
    let payload = try req.content.decode(FriendRequestPayload.self)

    guard payload.userID != appUser.id else {
        throw Abort(.badRequest, reason: "Cannot friend yourself")
    }

    try await sql.raw("""
        INSERT INTO friendships (requester_user_id, addressee_user_id, status, created_at, updated_at)
        VALUES (\(bind: appUser.id), \(bind: payload.userID), 'pending', NOW(), NOW())
        ON CONFLICT (requester_user_id, addressee_user_id)
        DO UPDATE SET status = EXCLUDED.status, updated_at = NOW()
        """).run()
    return .ok
}

private func acceptFriend(_ req: Request) async throws -> HTTPStatus {
    guard let appUser = req.auth.get(AppUser.self) else { throw Abort(.unauthorized) }
    guard let requesterID = req.parameters.get("id", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    try await sql.raw("""
        UPDATE friendships
        SET status = 'accepted', updated_at = NOW()
        WHERE requester_user_id = \(bind: requesterID)
          AND addressee_user_id = \(bind: appUser.id)
        """).run()
    return .ok
}

private struct FriendRow: Decodable {
    let user_id: UUID
    let display_name: String
    let avatar_url: String?
    let home_city: String
}

private func listFriends(_ req: Request) async throws -> [FriendResponse] {
    guard let appUser = req.auth.get(AppUser.self) else { throw Abort(.unauthorized) }
    guard let sql = req.db as? SQLDatabase else {
        throw Abort(.internalServerError)
    }

    let rows = try await sql.raw("""
        SELECT u.id AS user_id, u.display_name, u.avatar_url, u.home_city
        FROM users u
        JOIN friendships f
          ON (
            (f.requester_user_id = u.id AND f.addressee_user_id = \(bind: appUser.id))
            OR
            (f.addressee_user_id = u.id AND f.requester_user_id = \(bind: appUser.id))
          )
        WHERE f.status = 'accepted'
        ORDER BY u.display_name ASC
        """).all(decoding: FriendRow.self)

    return rows.map {
        FriendResponse(userID: $0.user_id, displayName: $0.display_name,
                       avatarURL: $0.avatar_url, homeCity: $0.home_city, status: "accepted")
    }
}

private struct PendingRow: Decodable {
    let user_id: UUID
    let display_name: String
    let avatar_url: String?
    let home_city: String
}

private func pendingRequests(_ req: Request) async throws -> [FriendResponse] {
    guard let appUser = req.auth.get(AppUser.self) else { throw Abort(.unauthorized) }
    guard let sql = req.db as? SQLDatabase else {
        throw Abort(.internalServerError)
    }

    let rows = try await sql.raw("""
        SELECT u.id AS user_id, u.display_name, u.avatar_url, u.home_city
        FROM users u
        JOIN friendships f ON f.requester_user_id = u.id
        WHERE f.addressee_user_id = \(bind: appUser.id)
          AND f.status = 'pending'
        ORDER BY f.created_at DESC
        """).all(decoding: PendingRow.self)

    return rows.map {
        FriendResponse(userID: $0.user_id, displayName: $0.display_name,
                       avatarURL: $0.avatar_url, homeCity: $0.home_city, status: "pending")
    }
}
