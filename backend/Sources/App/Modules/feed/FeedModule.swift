import FluentSQL
import Foundation
import Vapor

struct FeedModule: AppModule {
    let name = "feed"

    func register(routes: RoutesBuilder, app: Application) {
        let authed = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware())
        authed.get("feed", "friends", use: friendsFeed)
        routes.get("feed", "popular", use: popularFeed)
        routes.get("feed", "popular-items", use: popularItemsFeed)
    }
}

private struct FeedEventResponse: Content {
    let actorDisplayName: String
    let actorUserID: UUID
    let ratingID: UUID
    let placeID: UUID
    let placeName: String
    let itemName: String
    let score: Double
    let visibility: String
    let photoURL: String?
    let createdAt: Date
}

private struct PopularPlaceResponse: Content {
    let placeID: UUID
    let placeName: String
    let category: String
    let neighborhood: String?
    let averageScore: Double
    let ratingsCount: Int
    let coverPhotoURL: String?
}

private struct FriendFeedRow: Decodable {
    let actor_display_name: String
    let actor_user_id: UUID
    let subject_id: UUID
    let place_id: UUID
    let place_name: String
    let item_name: String
    let score: Double
    let visibility: String
    let photo_url: String?
    let created_at: Date
}

private func friendsFeed(_ req: Request) async throws -> [FeedEventResponse] {
    guard let appUser = req.auth.get(AppUser.self), let sql = req.db as? SQLDatabase else {
        throw Abort(.unauthorized)
    }

    let rows = try await sql.raw("""
        SELECT u.display_name AS actor_display_name,
               fe.actor_user_id,
               fe.subject_id,
               r.place_id,
               p.name AS place_name,
               r.item_name,
               r.score,
               fe.visibility,
               r.photo_url,
               fe.created_at
        FROM feed_events fe
        JOIN users u ON u.id = fe.actor_user_id
        JOIN ratings r ON r.id = fe.subject_id
        JOIN places p ON p.id = r.place_id
        JOIN friendships f ON (
              (f.requester_user_id = fe.actor_user_id AND f.addressee_user_id = \(bind: appUser.id))
           OR (f.addressee_user_id = fe.actor_user_id AND f.requester_user_id = \(bind: appUser.id))
        )
        WHERE f.status = 'accepted'
          AND r.is_suppressed = FALSE
          AND r.privacy IN ('public', 'friends')
        ORDER BY fe.created_at DESC
        LIMIT \(bind: req.query[Int.self, at: "limit"] ?? 50)
        OFFSET \(bind: req.query[Int.self, at: "offset"] ?? 0)
        """).all(decoding: FriendFeedRow.self)

    return rows.map {
        FeedEventResponse(
            actorDisplayName: $0.actor_display_name,
            actorUserID: $0.actor_user_id,
            ratingID: $0.subject_id,
            placeID: $0.place_id,
            placeName: $0.place_name,
            itemName: $0.item_name,
            score: $0.score,
            visibility: $0.visibility,
            photoURL: $0.photo_url,
            createdAt: $0.created_at
        )
    }
}

private struct PopularRow: Decodable {
    let place_id: UUID
    let place_name: String
    let category: String
    let neighborhood: String?
    let average_score: Double
    let ratings_count: Int
    let cover_photo_url: String?
}

private func popularFeed(_ req: Request) async throws -> [PopularPlaceResponse] {
    guard let sql = req.db as? SQLDatabase else {
        throw Abort(.internalServerError)
    }
    let city = req.query[String.self, at: "city"] ?? "SanDiego"

    let rows = try await sql.raw("""
        SELECT r.place_id,
               p.name AS place_name,
               p.category,
               p.neighborhood,
               AVG(r.score)::float8 AS average_score,
               COUNT(*)::int AS ratings_count,
               COALESCE(p.cover_photo_url,
                        (SELECT r2.photo_url FROM ratings r2
                         WHERE r2.place_id = p.id AND r2.photo_url IS NOT NULL
                           AND r2.is_suppressed = FALSE AND r2.privacy = 'public'
                         ORDER BY r2.score DESC LIMIT 1)) AS cover_photo_url
        FROM ratings r
        JOIN places p ON p.id = r.place_id
        WHERE p.city = \(bind: city)
          AND r.privacy = 'public'
          AND r.is_suppressed = FALSE
        GROUP BY r.place_id, p.id, p.name, p.category, p.neighborhood, p.cover_photo_url
        ORDER BY (AVG(r.score) * LN(COUNT(*) + 1))::float8 DESC
        LIMIT \(bind: req.query[Int.self, at: "limit"] ?? 25)
        OFFSET \(bind: req.query[Int.self, at: "offset"] ?? 0)
        """).all(decoding: PopularRow.self)

    return rows.map {
        PopularPlaceResponse(
            placeID: $0.place_id,
            placeName: $0.place_name,
            category: $0.category,
            neighborhood: $0.neighborhood,
            averageScore: $0.average_score,
            ratingsCount: $0.ratings_count,
            coverPhotoURL: $0.cover_photo_url
        )
    }
}

// MARK: - Popular items (dish-at-place), same JSON shape as PlacesModule.ItemSearchResponse

private struct PopularItemSearchResponse: Content {
    let placeID: UUID
    let placeName: String
    let category: String
    let neighborhood: String?
    let coverPhotoURL: String?
    let itemName: String
    let averageScore: Double
    let ratingsCount: Int
}

private struct PopularItemRow: Decodable {
    let place_id: UUID
    let place_name: String
    let category: String
    let neighborhood: String?
    let cover_photo_url: String?
    let item_name: String
    let average_score: Double
    let ratings_count: Int
}

private func popularItemsFeed(_ req: Request) async throws -> [PopularItemSearchResponse] {
    guard let sql = req.db as? SQLDatabase else {
        throw Abort(.internalServerError)
    }
    let city = req.query[String.self, at: "city"] ?? "SanDiego"
    let filter = req.query[String.self, at: "filter"]
    let qRaw = (req.query[String.self, at: "q"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let limit = req.query[Int.self, at: "limit"] ?? 25
    let offset = req.query[Int.self, at: "offset"] ?? 0

    let filterKind: Int
    switch filter?.lowercased() {
    case "food": filterKind = 1
    case "drink": filterKind = 2
    case "coffee": filterKind = 3
    case "seafood": filterKind = 4
    default: filterKind = 0
    }

    let rows: [PopularItemRow]
    if qRaw.isEmpty {
        rows = try await sql.raw("""
            SELECT r.place_id,
                   p.name AS place_name,
                   p.category,
                   p.neighborhood,
                   COALESCE(
                     (SELECT r2.photo_url FROM ratings r2
                      WHERE r2.place_id = r.place_id AND r2.item_name = r.item_name
                        AND r2.photo_url IS NOT NULL AND r2.is_suppressed = FALSE AND r2.privacy = 'public'
                      ORDER BY r2.score DESC LIMIT 1),
                     p.cover_photo_url,
                     (SELECT r3.photo_url FROM ratings r3
                      WHERE r3.place_id = p.id AND r3.photo_url IS NOT NULL
                        AND r3.is_suppressed = FALSE AND r3.privacy = 'public'
                      ORDER BY r3.score DESC LIMIT 1)
                   ) AS cover_photo_url,
                   r.item_name,
                   AVG(r.score)::float8 AS average_score,
                   COUNT(*)::int AS ratings_count
            FROM ratings r
            JOIN places p ON p.id = r.place_id
            WHERE p.city = \(bind: city)
              AND r.privacy = 'public'
              AND r.is_suppressed = FALSE
              AND CASE
                    WHEN \(bind: filterKind) = 0 THEN TRUE
                    WHEN \(bind: filterKind) = 1 THEN LOWER(p.category) IN ('food', 'both')
                    WHEN \(bind: filterKind) = 2 THEN LOWER(p.category) IN ('drink', 'both')
                    WHEN \(bind: filterKind) = 3 THEN (
                         LOWER(p.category) LIKE '%coffee%' OR LOWER(p.category) LIKE '%cafe%'
                         OR LOWER(p.name) LIKE '%coffee%' OR LOWER(p.name) LIKE '%cafe%'
                    )
                    WHEN \(bind: filterKind) = 4 THEN (
                         LOWER(p.name) LIKE '%fish%' OR LOWER(p.name) LIKE '%poke%' OR LOWER(p.name) LIKE '%seafood%'
                         OR LOWER(p.name) LIKE '%sushi%' OR LOWER(p.category) LIKE '%seafood%'
                    )
                    ELSE TRUE
                  END
            GROUP BY r.place_id, r.item_name, p.id, p.name, p.category, p.neighborhood, p.cover_photo_url
            ORDER BY (AVG(r.score) * LN(COUNT(*) + 1))::float8 DESC
            LIMIT \(bind: limit)
            OFFSET \(bind: offset)
            """).all(decoding: PopularItemRow.self)
    } else {
        rows = try await sql.raw("""
            SELECT r.place_id,
                   p.name AS place_name,
                   p.category,
                   p.neighborhood,
                   COALESCE(
                     (SELECT r2.photo_url FROM ratings r2
                      WHERE r2.place_id = r.place_id AND r2.item_name = r.item_name
                        AND r2.photo_url IS NOT NULL AND r2.is_suppressed = FALSE AND r2.privacy = 'public'
                      ORDER BY r2.score DESC LIMIT 1),
                     p.cover_photo_url,
                     (SELECT r3.photo_url FROM ratings r3
                      WHERE r3.place_id = p.id AND r3.photo_url IS NOT NULL
                        AND r3.is_suppressed = FALSE AND r3.privacy = 'public'
                      ORDER BY r3.score DESC LIMIT 1)
                   ) AS cover_photo_url,
                   r.item_name,
                   AVG(r.score)::float8 AS average_score,
                   COUNT(*)::int AS ratings_count
            FROM ratings r
            JOIN places p ON p.id = r.place_id
            WHERE p.city = \(bind: city)
              AND r.privacy = 'public'
              AND r.is_suppressed = FALSE
              AND CASE
                    WHEN \(bind: filterKind) = 0 THEN TRUE
                    WHEN \(bind: filterKind) = 1 THEN LOWER(p.category) IN ('food', 'both')
                    WHEN \(bind: filterKind) = 2 THEN LOWER(p.category) IN ('drink', 'both')
                    WHEN \(bind: filterKind) = 3 THEN (
                         LOWER(p.category) LIKE '%coffee%' OR LOWER(p.category) LIKE '%cafe%'
                         OR LOWER(p.name) LIKE '%coffee%' OR LOWER(p.name) LIKE '%cafe%'
                    )
                    WHEN \(bind: filterKind) = 4 THEN (
                         LOWER(p.name) LIKE '%fish%' OR LOWER(p.name) LIKE '%poke%' OR LOWER(p.name) LIKE '%seafood%'
                         OR LOWER(p.name) LIKE '%sushi%' OR LOWER(p.category) LIKE '%seafood%'
                    )
                    ELSE TRUE
                  END
              AND (
                   r.item_name ILIKE '%' || \(bind: qRaw) || '%'
                   OR r.item_category ILIKE '%' || \(bind: qRaw) || '%'
              )
            GROUP BY r.place_id, r.item_name, p.id, p.name, p.category, p.neighborhood, p.cover_photo_url
            ORDER BY (AVG(r.score) * LN(COUNT(*) + 1))::float8 DESC
            LIMIT \(bind: limit)
            OFFSET \(bind: offset)
            """).all(decoding: PopularItemRow.self)
    }

    return rows.map {
        PopularItemSearchResponse(
            placeID: $0.place_id,
            placeName: $0.place_name,
            category: $0.category,
            neighborhood: $0.neighborhood,
            coverPhotoURL: $0.cover_photo_url,
            itemName: $0.item_name,
            averageScore: $0.average_score,
            ratingsCount: $0.ratings_count
        )
    }
}
