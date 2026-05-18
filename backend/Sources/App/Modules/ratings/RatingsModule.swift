import Fluent
import FluentSQL
import Foundation
import Vapor

struct RatingsModule: AppModule {
    let name = "ratings"

    func register(routes: RoutesBuilder, app: Application) {
        let contributors = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware(), EligibilityGuardMiddleware())
        contributors.post("ratings", use: createRating)
        contributors.patch("ratings", ":id", use: updateRating)
        contributors.delete("ratings", ":id", use: deleteRating)
    }
}

private struct CreateRatingRequest: Content {
    let placeID: UUID
    let score: Double
    let itemName: String
    let itemCategory: String
    let notes: String?
    let visitDate: Date?
    let privacy: String
    let photoURL: String?
}

private struct UpdateRatingRequest: Content {
    let score: Double?
    let itemName: String?
    let itemCategory: String?
    let notes: String?
    let visitDate: Date?
    let privacy: String?
    let photoURL: String?
}

private func validateRating(score: Double, privacy: String) throws {
    guard score >= 1.0, score <= 10.0 else {
        throw Abort(.badRequest, reason: "score must be between 1.0 and 10.0")
    }
    guard ["public", "friends", "private"].contains(privacy) else {
        throw Abort(.badRequest, reason: "privacy must be public, friends, or private")
    }
}

private func validateItem(name: String, category: String) throws {
    guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw Abort(.badRequest, reason: "itemName is required")
    }
    guard !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw Abort(.badRequest, reason: "itemCategory is required")
    }
}

private func createRating(_ req: Request) async throws -> RatingModel {
    guard let user = req.auth.get(AppUser.self) else { throw Abort(.unauthorized) }
    let payload = try req.content.decode(CreateRatingRequest.self)
    let placeRepo = DatabasePlaceRepository()
    let ratingRepo = DatabaseRatingRepository()
    try validateRating(score: payload.score, privacy: payload.privacy)
    try validateItem(name: payload.itemName, category: payload.itemCategory)

    guard try await placeRepo.findByID(payload.placeID, on: req.db) != nil else {
        throw Abort(.notFound, reason: "Place not found")
    }

    let rating = RatingModel()
    rating.id = UUID()
    rating.userID = user.id
    rating.placeID = payload.placeID
    rating.score = payload.score
    rating.itemName = payload.itemName.trimmingCharacters(in: .whitespacesAndNewlines)
    rating.itemCategory = payload.itemCategory.trimmingCharacters(in: .whitespacesAndNewlines)
    rating.notes = payload.notes ?? ""
    rating.visitDate = payload.visitDate
    rating.privacy = payload.privacy
    rating.isSuppressed = false
    rating.photoURL = payload.photoURL
    try await ratingRepo.save(rating, on: req.db)
    try await ItemCategoryRegistry.register(rating.itemCategory, on: req.db)

    if let photoURL = payload.photoURL, !photoURL.isEmpty {
        if let place = try await PlaceModel.find(payload.placeID, on: req.db),
           place.coverPhotoURL == nil {
            place.coverPhotoURL = photoURL
            try await place.update(on: req.db)
        }
    }

    if payload.privacy == "public" || payload.privacy == "friends" {
        let event = FeedEventModel()
        event.id = UUID()
        event.actorUserID = user.id
        event.eventType = "rating_created"
        event.subjectType = "rating"
        event.subjectID = rating.id!
        event.city = "SanDiego"
        event.visibility = payload.privacy == "public" ? "public" : "friends"
        event.createdAt = Date()
        try await event.create(on: req.db)
    }

    return rating
}

private func updateRating(_ req: Request) async throws -> RatingModel {
    guard let user = req.auth.get(AppUser.self) else { throw Abort(.unauthorized) }
    let ratingRepo = DatabaseRatingRepository()
    guard let ratingID = req.parameters.get("id", as: UUID.self),
          let rating = try await ratingRepo.findByID(ratingID, on: req.db) else {
        throw Abort(.notFound)
    }
    guard rating.userID == user.id else {
        throw Abort(.forbidden, reason: "Only owner can update rating")
    }

    let payload = try req.content.decode(UpdateRatingRequest.self)
    if let score = payload.score {
        try validateRating(score: score, privacy: payload.privacy ?? rating.privacy)
        rating.score = score
    }
    if let itemName = payload.itemName {
        let trimmed = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw Abort(.badRequest, reason: "itemName is required")
        }
        rating.itemName = trimmed
    }
    if let itemCategory = payload.itemCategory {
        let trimmed = itemCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw Abort(.badRequest, reason: "itemCategory is required")
        }
        rating.itemCategory = trimmed
    }
    if let notes = payload.notes { rating.notes = notes }
    if let visitDate = payload.visitDate { rating.visitDate = visitDate }
    if let photoURL = payload.photoURL { rating.photoURL = photoURL }
    if let privacy = payload.privacy {
        try validateRating(score: payload.score ?? rating.score, privacy: privacy)
        rating.privacy = privacy
    }
    try await ratingRepo.save(rating, on: req.db)
    if let itemCategory = payload.itemCategory {
        try await ItemCategoryRegistry.register(itemCategory, on: req.db)
    }
    return rating
}

private func deleteRating(_ req: Request) async throws -> HTTPStatus {
    guard let user = req.auth.get(AppUser.self) else { throw Abort(.unauthorized) }
    let ratingRepo = DatabaseRatingRepository()
    guard let ratingID = req.parameters.get("id", as: UUID.self),
          let rating = try await ratingRepo.findByID(ratingID, on: req.db) else {
        throw Abort(.notFound)
    }
    guard rating.userID == user.id else {
        throw Abort(.forbidden, reason: "Only owner can delete rating")
    }
    try await ratingRepo.delete(rating, on: req.db)
    return .noContent
}
