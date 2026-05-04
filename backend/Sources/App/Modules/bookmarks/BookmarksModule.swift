import FluentSQL
import Foundation
import Vapor

struct BookmarksModule: AppModule {
    let name = "bookmarks"

    func register(routes: RoutesBuilder, app: Application) {
        let authed = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware())
        authed.get("bookmarks", use: listBookmarks)
        authed.post("bookmarks", ":placeID", use: addBookmark)
        authed.delete("bookmarks", ":placeID", use: removeBookmark)
    }
}

private struct BookmarkedPlaceRow: Decodable {
    let id: UUID
    let name: String
    let category: String
    let neighborhood: String?
    let city: String
    let cover_photo_url: String?
    let saved_at: Date
}

private struct BookmarkedPlaceResponse: Content {
    let id: UUID
    let name: String
    let category: String
    let neighborhood: String?
    let city: String
    let coverPhotoURL: String?
    let savedAt: Date
}

private func listBookmarks(_ req: Request) async throws -> [BookmarkedPlaceResponse] {
    guard let user = req.auth.get(AppUser.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.unauthorized)
    }

    let rows = try await sql.raw("""
        SELECT p.id, p.name, p.category, p.neighborhood, p.city,
               p.cover_photo_url, sp.created_at AS saved_at
        FROM saved_places sp
        JOIN places p ON p.id = sp.place_id
        WHERE sp.user_id = \(bind: user.id)
        ORDER BY sp.created_at DESC
        """).all(decoding: BookmarkedPlaceRow.self)

    return rows.map {
        BookmarkedPlaceResponse(
            id: $0.id, name: $0.name, category: $0.category,
            neighborhood: $0.neighborhood, city: $0.city,
            coverPhotoURL: $0.cover_photo_url, savedAt: $0.saved_at
        )
    }
}

private func addBookmark(_ req: Request) async throws -> HTTPStatus {
    guard let user = req.auth.get(AppUser.self),
          let placeID = req.parameters.get("placeID", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    try await sql.raw("""
        INSERT INTO saved_places (user_id, place_id)
        VALUES (\(bind: user.id), \(bind: placeID))
        ON CONFLICT DO NOTHING
        """).run()

    return .ok
}

private func removeBookmark(_ req: Request) async throws -> HTTPStatus {
    guard let user = req.auth.get(AppUser.self),
          let placeID = req.parameters.get("placeID", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    try await sql.raw("""
        DELETE FROM saved_places
        WHERE user_id = \(bind: user.id) AND place_id = \(bind: placeID)
        """).run()

    return .noContent
}
