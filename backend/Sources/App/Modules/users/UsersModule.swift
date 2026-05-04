import Fluent
import Foundation
import Vapor

struct UsersModule: AppModule {
    let name = "users"

    func register(routes: RoutesBuilder, app: Application) {
        routes.get("users", "search", use: searchUsers)
        routes.get("users", ":id", "profile", use: profile)
        routes.get("users", ":id", "ratings", use: userRatings)

        let authed = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware())
        authed.get("me", "ratings", use: myRatings)
        authed.get("me", "ratings", "rankings", use: myRatingsRankings)
        authed.get("me", "profile", use: myProfile)
        authed.patch("me", "profile", use: updateMyProfile)
    }
}

private struct UserSearchResponse: Content {
    let id: UUID
    let displayName: String
    let avatarURL: String?
    let homeCity: String
}

private func searchUsers(_ req: Request) async throws -> [UserSearchResponse] {
    let q = (req.query[String.self, at: "q"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !q.isEmpty else { return [] }
    let users = try await UserModel.query(on: req.db)
        .filter(\.$displayName, .custom("ILIKE"), "%\(q)%")
        .range(..<20)
        .all()
    return users.compactMap { u in
        guard let id = u.id else { return nil }
        return UserSearchResponse(id: id, displayName: u.displayName, avatarURL: u.avatarURL, homeCity: u.homeCity)
    }
}

private struct UserProfileResponse: Content {
    let id: UUID
    let displayName: String
    let bio: String
    let avatarURL: String?
    let homeCity: String
}

private struct RatingResponse: Content {
    let id: UUID
    let placeID: UUID
    let placeName: String
    let itemName: String
    let itemCategory: String
    let score: Double
    let notes: String
    let privacy: String
    let photoURL: String?
    let createdAt: Date?
}

private struct UpdateMyProfileRequest: Content {
    let displayName: String?
    let bio: String?
    let avatarURL: String?
}

private func mapRatingsWithPlaceName(_ ratings: [RatingModel], on db: Database) async throws -> [RatingResponse] {
    let placeIDs = Array(Set(ratings.map(\.placeID)))
    let places: [PlaceModel]
    if placeIDs.isEmpty {
        places = []
    } else {
        places = try await PlaceModel.query(on: db)
            .filter(\.$id ~~ placeIDs)
            .all()
    }
    let placeNameByID: [UUID: String] = Dictionary(
        uniqueKeysWithValues: places.compactMap { place in
            guard let id = place.id else { return nil }
            return (id, place.name)
        }
    )

    return ratings.compactMap { rating in
        guard let ratingID = rating.id else { return nil }
        return RatingResponse(
            id: ratingID,
            placeID: rating.placeID,
            placeName: placeNameByID[rating.placeID] ?? "Unknown place",
            itemName: rating.itemName,
            itemCategory: rating.itemCategory,
            score: rating.score,
            notes: rating.notes,
            privacy: rating.privacy,
            photoURL: rating.photoURL,
            createdAt: rating.createdAt
        )
    }
}

private func profile(_ req: Request) async throws -> UserProfileResponse {
    guard
        let id = req.parameters.get("id", as: UUID.self),
        let user = try await UserModel.find(id, on: req.db),
        let userID = user.id
    else {
        throw Abort(.notFound)
    }
    return UserProfileResponse(
        id: userID,
        displayName: user.displayName,
        bio: user.bio,
        avatarURL: user.avatarURL,
        homeCity: user.homeCity
    )
}

private func userRatings(_ req: Request) async throws -> [RatingResponse] {
    guard let id = req.parameters.get("id", as: UUID.self) else {
        throw Abort(.badRequest)
    }
    let ratings = try await RatingModel.query(on: req.db)
        .filter(\.$userID == id)
        .filter(\.$privacy == "public")
        .sort(\.$createdAt, .descending)
        .all()
    return try await mapRatingsWithPlaceName(ratings, on: req.db)
}

private func myRatings(_ req: Request) async throws -> [RatingResponse] {
    guard let user = req.auth.get(AppUser.self) else {
        throw Abort(.unauthorized)
    }

    let sort = req.query[String.self, at: "sort"] ?? "createdAtDesc"
    var builder = RatingModel.query(on: req.db).filter(\.$userID == user.id)

    if let privacy = req.query[String.self, at: "privacy"] {
        builder = builder.filter(\.$privacy == privacy)
    }

    switch sort {
    case "scoreDesc":
        builder = builder.sort(\.$score, .descending)
    case "scoreAsc":
        builder = builder.sort(\.$score, .ascending)
    default:
        builder = builder.sort(\.$createdAt, .descending)
    }
    let ratings = try await builder.all()
    return try await mapRatingsWithPlaceName(ratings, on: req.db)
}

private func myRatingsRankings(_ req: Request) async throws -> [RatingResponse] {
    guard let user = req.auth.get(AppUser.self) else {
        throw Abort(.unauthorized)
    }
    let category = (req.query[String.self, at: "category"] ?? "").lowercased()
    guard !category.isEmpty else {
        throw Abort(.badRequest, reason: "category query parameter is required")
    }

    let ratings = try await RatingModel.query(on: req.db)
        .filter(\.$userID == user.id)
        .filter(\.$itemCategory == category)
        .sort(\.$score, .descending)
        .all()
    return try await mapRatingsWithPlaceName(ratings, on: req.db)
}

private func myProfile(_ req: Request) async throws -> UserProfileResponse {
    guard let appUser = req.auth.get(AppUser.self),
          let user = try await UserModel.find(appUser.id, on: req.db)
    else {
        throw Abort(.unauthorized)
    }

    return UserProfileResponse(
        id: appUser.id,
        displayName: user.displayName,
        bio: user.bio,
        avatarURL: user.avatarURL,
        homeCity: user.homeCity
    )
}

private func updateMyProfile(_ req: Request) async throws -> UserProfileResponse {
    guard let appUser = req.auth.get(AppUser.self),
          let user = try await UserModel.find(appUser.id, on: req.db)
    else {
        throw Abort(.unauthorized)
    }
    let payload = try req.content.decode(UpdateMyProfileRequest.self)

    if let displayName = payload.displayName {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw Abort(.badRequest, reason: "displayName cannot be empty")
        }
        user.displayName = trimmed
    }
    if let bio = payload.bio {
        user.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if let avatarURL = payload.avatarURL {
        let trimmed = avatarURL.trimmingCharacters(in: .whitespacesAndNewlines)
        user.avatarURL = trimmed.isEmpty ? nil : trimmed
    }

    try await user.save(on: req.db)

    return UserProfileResponse(
        id: appUser.id,
        displayName: user.displayName,
        bio: user.bio,
        avatarURL: user.avatarURL,
        homeCity: user.homeCity
    )
}
