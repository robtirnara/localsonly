import FluentSQL
import Foundation
import Vapor

struct InvitesModule: AppModule {
    let name = "invites"

    func register(routes: RoutesBuilder, app: Application) {
        let authed = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware())
        authed.get("invites", "my-code", use: myInviteCode)
        authed.get("invites", "invited-users", use: invitedUsers)
    }
}

private struct InviteCodeResponse: Content {
    let code: String
    let usedCount: Int
}

private struct InvitedUserResponse: Content {
    let userID: UUID
    let displayName: String
    let joinedAt: Date?
}

private struct InviteRow: Decodable {
    let code: String
}

private struct InvitedRow: Decodable {
    let user_id: UUID
    let display_name: String
    let joined_at: Date?
}

private func myInviteCode(_ req: Request) async throws -> InviteCodeResponse {
    guard let user = req.auth.get(AppUser.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.unauthorized)
    }

    struct CodeRow: Decodable {
        let code: String
        let used_count: Int
    }

    if let existing = try await sql.raw("""
        SELECT i.code,
               (SELECT COUNT(*)::int FROM users u2 WHERE u2.inviter_user_id = \(bind: user.id)) AS used_count
        FROM invites i
        WHERE i.inviter_user_id = \(bind: user.id)
        LIMIT 1
        """).first(decoding: CodeRow.self) {
        return InviteCodeResponse(code: existing.code, usedCount: existing.used_count)
    }

    let code = generateCode()
    try await sql.raw("""
        INSERT INTO invites (id, code, inviter_user_id, status)
        VALUES (\(bind: UUID()), \(bind: code), \(bind: user.id), 'issued')
        ON CONFLICT (code) DO NOTHING
        """).run()

    return InviteCodeResponse(code: code, usedCount: 0)
}

private func invitedUsers(_ req: Request) async throws -> [InvitedUserResponse] {
    guard let user = req.auth.get(AppUser.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.unauthorized)
    }

    let rows = try await sql.raw("""
        SELECT u.id AS user_id, u.display_name, u.created_at AS joined_at
        FROM users u
        WHERE u.inviter_user_id = \(bind: user.id)
        ORDER BY u.created_at DESC
        """).all(decoding: InvitedRow.self)

    return rows.map {
        InvitedUserResponse(userID: $0.user_id, displayName: $0.display_name, joinedAt: $0.joined_at)
    }
}

private func generateCode() -> String {
    let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    return "LO-" + String((0..<6).map { _ in chars.randomElement()! })
}
