import FluentSQL
import Foundation
import Vapor

struct FeedModule: AppModule {
    let name = "feed"

    func register(routes: RoutesBuilder, app: Application) {
        let authed = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware())
        authed.get("feed", "friends", use: friendsFeed)
        routes.get("feed", "popular", use: popularFeed)
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
