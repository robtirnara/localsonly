import FluentSQL
import Foundation
import Vapor

struct CosignsModule: AppModule {
    let name = "cosigns"

    func register(routes: RoutesBuilder, app: Application) {
        let authed = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware())
        authed.post("ratings", ":id", "cosign", use: cosignRating)
        authed.delete("ratings", ":id", "cosign", use: removeCosign)
        routes.get("ratings", ":id", "cosigns", use: getCosigns)
    }
}

private struct CosignResponse: Content {
    let userID: UUID
    let displayName: String
    let createdAt: Date
}

private struct CosignCountResponse: Content {
    let ratingID: UUID
    let count: Int
    let cosignedByMe: Bool
    let cosigners: [CosignResponse]
}

private struct CosignRow: Decodable {
    let user_id: UUID
    let display_name: String
    let created_at: Date
}

private func cosignRating(_ req: Request) async throws -> HTTPStatus {
    guard let user = req.auth.get(AppUser.self),
          let ratingID = req.parameters.get("id", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    try await sql.raw("""
        INSERT INTO cosigns (id, user_id, rating_id)
        VALUES (\(bind: UUID()), \(bind: user.id), \(bind: ratingID))
        ON CONFLICT (user_id, rating_id) DO NOTHING
        """).run()

    return .ok
}

private func removeCosign(_ req: Request) async throws -> HTTPStatus {
    guard let user = req.auth.get(AppUser.self),
          let ratingID = req.parameters.get("id", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    try await sql.raw("""
        DELETE FROM cosigns WHERE user_id = \(bind: user.id) AND rating_id = \(bind: ratingID)
        """).run()

    return .noContent
}

private func getCosigns(_ req: Request) async throws -> CosignCountResponse {
    guard let ratingID = req.parameters.get("id", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    let rows = try await sql.raw("""
        SELECT c.user_id, u.display_name, c.created_at
        FROM cosigns c
        JOIN users u ON u.id = c.user_id
        WHERE c.rating_id = \(bind: ratingID)
        ORDER BY c.created_at DESC
        """).all(decoding: CosignRow.self)

    let authedUser = req.auth.get(AppUser.self)
    let cosignedByMe = authedUser.map { u in rows.contains { $0.user_id == u.id } } ?? false

    return CosignCountResponse(
        ratingID: ratingID,
        count: rows.count,
        cosignedByMe: cosignedByMe,
        cosigners: rows.map {
            CosignResponse(userID: $0.user_id, displayName: $0.display_name, createdAt: $0.created_at)
        }
    )
}
