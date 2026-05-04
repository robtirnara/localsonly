import FluentSQL
import Foundation
import Vapor

struct NotificationsModule: AppModule {
    let name = "notifications"

    func register(routes: RoutesBuilder, app: Application) {
        let authed = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware())
        authed.get("notifications", use: listNotifications)
        authed.get("notifications", "unread-count", use: unreadCount)
        authed.post("notifications", "mark-read", use: markAllRead)
        authed.post("notifications", ":id", "read", use: markOneRead)
    }
}

private struct NotificationResponse: Content {
    let id: UUID
    let type: String
    let title: String
    let body: String
    let referenceID: UUID?
    let isRead: Bool
    let createdAt: Date
}

private struct NotificationRow: Decodable {
    let id: UUID
    let type: String
    let title: String
    let body: String
    let reference_id: UUID?
    let is_read: Bool
    let created_at: Date
}

private struct UnreadCountResponse: Content {
    let count: Int
}

private func listNotifications(_ req: Request) async throws -> [NotificationResponse] {
    guard let user = req.auth.get(AppUser.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.unauthorized)
    }

    let rows = try await sql.raw("""
        SELECT id, type, title, body, reference_id, is_read, created_at
        FROM notifications
        WHERE user_id = \(bind: user.id)
        ORDER BY created_at DESC
        LIMIT 50
        """).all(decoding: NotificationRow.self)

    return rows.map {
        NotificationResponse(id: $0.id, type: $0.type, title: $0.title,
                           body: $0.body, referenceID: $0.reference_id,
                           isRead: $0.is_read, createdAt: $0.created_at)
    }
}

private func unreadCount(_ req: Request) async throws -> UnreadCountResponse {
    guard let user = req.auth.get(AppUser.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.unauthorized)
    }

    struct CountRow: Decodable { let count: Int }
    let row = try await sql.raw("""
        SELECT COUNT(*)::int AS count FROM notifications
        WHERE user_id = \(bind: user.id) AND is_read = FALSE
        """).first(decoding: CountRow.self)

    return UnreadCountResponse(count: row?.count ?? 0)
}

private func markAllRead(_ req: Request) async throws -> HTTPStatus {
    guard let user = req.auth.get(AppUser.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.unauthorized)
    }

    try await sql.raw("""
        UPDATE notifications SET is_read = TRUE
        WHERE user_id = \(bind: user.id) AND is_read = FALSE
        """).run()

    return .ok
}

private func markOneRead(_ req: Request) async throws -> HTTPStatus {
    guard let user = req.auth.get(AppUser.self),
          let notifID = req.parameters.get("id", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    try await sql.raw("""
        UPDATE notifications SET is_read = TRUE
        WHERE id = \(bind: notifID) AND user_id = \(bind: user.id)
        """).run()

    return .ok
}
