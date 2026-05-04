import Fluent
import FluentSQL
import Foundation
import Vapor

struct TagsModule: AppModule {
    let name = "tags"

    func register(routes: RoutesBuilder, app: Application) {
        routes.get("tags", use: listTags)
        routes.get("tags", "popular", use: popularTags)

        let authed = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware())
        authed.post("ratings", ":id", "tags", use: addTagsToRating)
        authed.get("ratings", ":id", "tags", use: getTagsForRating)
    }
}

private struct TagResponse: Content {
    let id: UUID
    let slug: String
    let displayName: String
}

private struct AddTagsRequest: Content {
    let tags: [String]
}

private func listTags(_ req: Request) async throws -> [TagResponse] {
    guard let sql = req.db as? SQLDatabase else {
        throw Abort(.internalServerError)
    }
    struct TagRow: Decodable {
        let id: UUID
        let slug: String
        let display_name: String
    }
    let rows = try await sql.raw("SELECT id, slug, display_name FROM tags ORDER BY display_name ASC")
        .all(decoding: TagRow.self)
    return rows.map { TagResponse(id: $0.id, slug: $0.slug, displayName: $0.display_name) }
}

private struct PopularTagRow: Decodable {
    let slug: String
    let display_name: String
    let usage_count: Int
}

private struct PopularTagResponse: Content {
    let slug: String
    let displayName: String
    let usageCount: Int
}

private func popularTags(_ req: Request) async throws -> [PopularTagResponse] {
    guard let sql = req.db as? SQLDatabase else {
        throw Abort(.internalServerError)
    }
    let rows = try await sql.raw("""
        SELECT t.slug, t.display_name, COUNT(rt.rating_id)::int AS usage_count
        FROM tags t
        LEFT JOIN rating_tags rt ON rt.tag_id = t.id
        GROUP BY t.id, t.slug, t.display_name
        ORDER BY usage_count DESC
        LIMIT 30
        """).all(decoding: PopularTagRow.self)
    return rows.map { PopularTagResponse(slug: $0.slug, displayName: $0.display_name, usageCount: $0.usage_count) }
}

private func addTagsToRating(_ req: Request) async throws -> HTTPStatus {
    guard let _ = req.auth.get(AppUser.self) else { throw Abort(.unauthorized) }
    guard let ratingID = req.parameters.get("id", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    let payload = try req.content.decode(AddTagsRequest.self)

    for tagSlug in payload.tags {
        let slug = tagSlug.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
        guard !slug.isEmpty else { continue }

        try await sql.raw("""
            INSERT INTO tags (id, slug, display_name)
            VALUES (\(bind: UUID()), \(bind: slug), \(bind: tagSlug.trimmingCharacters(in: .whitespacesAndNewlines)))
            ON CONFLICT (slug) DO NOTHING
            """).run()

        try await sql.raw("""
            INSERT INTO rating_tags (rating_id, tag_id)
            SELECT \(bind: ratingID), id FROM tags WHERE slug = \(bind: slug)
            ON CONFLICT DO NOTHING
            """).run()
    }
    return .ok
}

private struct RatingTagRow: Decodable {
    let slug: String
    let display_name: String
}

private func getTagsForRating(_ req: Request) async throws -> [TagResponse] {
    guard let ratingID = req.parameters.get("id", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    struct TagIDRow: Decodable {
        let id: UUID
        let slug: String
        let display_name: String
    }

    let rows = try await sql.raw("""
        SELECT t.id, t.slug, t.display_name
        FROM tags t
        JOIN rating_tags rt ON rt.tag_id = t.id
        WHERE rt.rating_id = \(bind: ratingID)
        ORDER BY t.display_name
        """).all(decoding: TagIDRow.self)

    return rows.map { TagResponse(id: $0.id, slug: $0.slug, displayName: $0.display_name) }
}
