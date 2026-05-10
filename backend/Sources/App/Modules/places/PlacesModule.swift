import Fluent
import FluentSQL
import Foundation
import Vapor

struct PlacesModule: AppModule {
    let name = "places"

    func register(routes: RoutesBuilder, app: Application) {
        let places = routes.grouped("places")
        places.get("search", use: searchPlaces)
        places.get("nearby", use: placesNearby)
        places.get("neighborhoods", use: listNeighborhoods)
        places.get("search-items", use: searchByItem)
        places.get(":id", use: placeDetail)
        places.get(":id", "ratings", use: placeRatings)

        let contributors = places.grouped(UserTokenAuthenticator(), UserGuardMiddleware(), EligibilityGuardMiddleware())
        contributors.post("suggest", use: suggestPlace)
    }
}

private struct PlaceSuggestRequest: Content {
    let name: String
    let neighborhood: String?
    let category: String
    let city: String?
    let latitude: Double?
    let longitude: Double?
}

private struct PlaceRatingResponse: Content {
    let id: UUID
    let userID: UUID
    let userDisplayName: String
    let itemName: String
    let itemCategory: String
    let score: Double
    let notes: String
    let photoURL: String?
    let createdAt: Date?
}

private func searchPlaces(_ req: Request) async throws -> [PlaceModel] {
    let q = req.query[String.self, at: "q"] ?? ""
    let city = req.query[String.self, at: "city"] ?? "SanDiego"
    let repo = DatabasePlaceRepository()
    return try await repo.search(nameQuery: q, city: city, on: req.db)
}

private func placeDetail(_ req: Request) async throws -> PlaceModel {
    guard let id = req.parameters.get("id", as: UUID.self) else {
        throw Abort(.badRequest)
    }
    let repo = DatabasePlaceRepository()
    guard let place = try await repo.findByID(id, on: req.db) else {
        throw Abort(.notFound)
    }
    return place
}

private func placeRatings(_ req: Request) async throws -> [PlaceRatingResponse] {
    guard let id = req.parameters.get("id", as: UUID.self) else {
        throw Abort(.badRequest)
    }

    let ratings = try await RatingModel.query(on: req.db)
        .filter(\.$placeID == id)
        .filter(\.$privacy == "public")
        .filter(\.$isSuppressed == false)
        .sort(\.$score, .descending)
        .all()

    let userIDs = Array(Set(ratings.map(\.userID)))
    let users: [UserModel]
    if userIDs.isEmpty {
        users = []
    } else {
        users = try await UserModel.query(on: req.db)
            .filter(\.$id ~~ userIDs)
            .all()
    }
    let nameByID: [UUID: String] = Dictionary(
        uniqueKeysWithValues: users.compactMap { u in
            guard let uid = u.id else { return nil }
            return (uid, u.displayName)
        }
    )

    return ratings.compactMap { r in
        guard let rid = r.id else { return nil }
        return PlaceRatingResponse(
            id: rid,
            userID: r.userID,
            userDisplayName: nameByID[r.userID] ?? "Local",
            itemName: r.itemName,
            itemCategory: r.itemCategory,
            score: r.score,
            notes: r.notes,
            photoURL: r.photoURL,
            createdAt: r.createdAt
        )
    }
}

private struct PlaceMapResponse: Content {
    let id: UUID
    let name: String
    let category: String
    let neighborhood: String?
    let latitude: Double
    let longitude: Double
    let averageScore: Double?
    let ratingsCount: Int
    let coverPhotoURL: String?
}

private func placesNearby(_ req: Request) async throws -> [PlaceMapResponse] {
    guard let sql = req.db as? SQLDatabase else {
        throw Abort(.internalServerError)
    }
    let city = req.query[String.self, at: "city"] ?? "SanDiego"

    struct MapRow: Decodable {
        let id: UUID
        let name: String
        let category: String
        let neighborhood: String?
        let latitude: Double
        let longitude: Double
        let average_score: Double?
        let ratings_count: Int
        let cover_photo_url: String?
    }

    let rows = try await sql.raw("""
        SELECT p.id, p.name, p.category, p.neighborhood,
               p.latitude, p.longitude,
               AVG(r.score)::float8 AS average_score,
               COUNT(r.id)::int AS ratings_count,
               p.cover_photo_url
        FROM places p
        LEFT JOIN ratings r ON r.place_id = p.id AND r.privacy = 'public' AND r.is_suppressed = FALSE
        WHERE p.city = \(bind: city)
          AND p.latitude IS NOT NULL
          AND p.longitude IS NOT NULL
        GROUP BY p.id
        ORDER BY ratings_count DESC
        LIMIT 100
        """).all(decoding: MapRow.self)

    return rows.map {
        PlaceMapResponse(
            id: $0.id, name: $0.name, category: $0.category,
            neighborhood: $0.neighborhood, latitude: $0.latitude,
            longitude: $0.longitude, averageScore: $0.average_score,
            ratingsCount: $0.ratings_count,
            coverPhotoURL: $0.cover_photo_url
        )
    }
}

private struct NeighborhoodResponse: Content {
    let neighborhood: String
    let placeCount: Int
    let coverPhotoURL: String?
}

private struct NeighborhoodRow: Decodable {
    let neighborhood: String
    let place_count: Int
    let cover_photo_url: String?
}

private func listNeighborhoods(_ req: Request) async throws -> [NeighborhoodResponse] {
    guard let sql = req.db as? SQLDatabase else {
        throw Abort(.internalServerError)
    }
    let city = req.query[String.self, at: "city"] ?? "SanDiego"

    let rows = try await sql.raw("""
        SELECT p.neighborhood, COUNT(DISTINCT p.id)::int AS place_count,
               (SELECT p2.cover_photo_url FROM places p2
                WHERE p2.neighborhood = p.neighborhood AND p2.cover_photo_url IS NOT NULL
                LIMIT 1) AS cover_photo_url
        FROM places p
        WHERE p.city = \(bind: city)
          AND p.neighborhood IS NOT NULL AND p.neighborhood != ''
        GROUP BY p.neighborhood
        ORDER BY place_count DESC
        """).all(decoding: NeighborhoodRow.self)

    return rows.map {
        NeighborhoodResponse(neighborhood: $0.neighborhood,
                           placeCount: $0.place_count,
                           coverPhotoURL: $0.cover_photo_url)
    }
}

private struct ItemSearchResponse: Content {
    let placeID: UUID
    let placeName: String
    let category: String
    let neighborhood: String?
    let coverPhotoURL: String?
    let itemName: String
    let averageScore: Double
    let ratingsCount: Int
}

private struct ItemSearchRow: Decodable {
    let place_id: UUID
    let place_name: String
    let category: String
    let neighborhood: String?
    let cover_photo_url: String?
    let item_name: String
    let average_score: Double
    let ratings_count: Int
}

private func searchByItem(_ req: Request) async throws -> [ItemSearchResponse] {
    guard let sql = req.db as? SQLDatabase else {
        throw Abort(.internalServerError)
    }
    let q = (req.query[String.self, at: "q"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let city = req.query[String.self, at: "city"] ?? "SanDiego"
    guard !q.isEmpty else { return [] }

    let rows = try await sql.raw("""
        SELECT r.place_id, p.name AS place_name, p.category, p.neighborhood,
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
          AND (r.item_name ILIKE '%' || \(bind: q) || '%'
               OR r.item_category ILIKE '%' || \(bind: q) || '%')
        GROUP BY r.place_id, p.id, p.name, p.category, p.neighborhood, p.cover_photo_url, r.item_name
        ORDER BY average_score DESC
        LIMIT 25
        """).all(decoding: ItemSearchRow.self)

    return rows.map {
        ItemSearchResponse(placeID: $0.place_id, placeName: $0.place_name,
                          category: $0.category, neighborhood: $0.neighborhood,
                          coverPhotoURL: $0.cover_photo_url,
                          itemName: $0.item_name,
                          averageScore: $0.average_score,
                          ratingsCount: $0.ratings_count)
    }
}

private func suggestPlace(_ req: Request) async throws -> PlaceModel {
    let payload = try req.content.decode(PlaceSuggestRequest.self)
    let repo = DatabasePlaceRepository()
    guard ["food", "drink", "both"].contains(payload.category) else {
        throw Abort(.badRequest, reason: "category must be food, drink, or both")
    }

    let place = PlaceModel()
    place.id = UUID()
    place.name = payload.name
    place.neighborhood = payload.neighborhood
    place.category = payload.category
    place.city = payload.city ?? "SanDiego"
    place.latitude = payload.latitude
    place.longitude = payload.longitude
    place.externalID = nil
    place.externalSource = "user_suggested"
    try await repo.save(place, on: req.db)
    return place
}
