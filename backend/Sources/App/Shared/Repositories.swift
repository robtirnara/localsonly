import Fluent
import Foundation

protocol UserRepository {
    func findByPhone(_ phoneE164: String, on db: Database) async throws -> UserModel?
    func findByID(_ id: UUID, on db: Database) async throws -> UserModel?
    func save(_ user: UserModel, on db: Database) async throws
}

struct DatabaseUserRepository: UserRepository {
    func findByPhone(_ phoneE164: String, on db: Database) async throws -> UserModel? {
        try await UserModel.query(on: db).filter(\.$phoneE164 == phoneE164).first()
    }

    func findByID(_ id: UUID, on db: Database) async throws -> UserModel? {
        try await UserModel.find(id, on: db)
    }

    func save(_ user: UserModel, on db: Database) async throws {
        if let id = user.id, try await UserModel.find(id, on: db) != nil {
            try await user.save(on: db)
        } else {
            try await user.create(on: db)
        }
    }
}

protocol PlaceRepository {
    func findByID(_ id: UUID, on db: Database) async throws -> PlaceModel?
    func search(nameQuery: String, city: String, on db: Database) async throws -> [PlaceModel]
    func save(_ place: PlaceModel, on db: Database) async throws
}

struct DatabasePlaceRepository: PlaceRepository {
    func findByID(_ id: UUID, on db: Database) async throws -> PlaceModel? {
        try await PlaceModel.find(id, on: db)
    }

    func search(nameQuery: String, city: String, on db: Database) async throws -> [PlaceModel] {
        let trimmed = nameQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        var builder = PlaceModel.query(on: db).filter(\.$city == city)
        if !trimmed.isEmpty {
            let pattern = "%\(trimmed)%"
            builder = builder.group(.or) { group in
                group.filter(\.$name, .custom("ILIKE"), pattern)
                group.filter(\.$neighborhood, .custom("ILIKE"), pattern)
            }
        }
        return try await builder.sort(\.$name, .ascending).limit(25).all()
    }

    func save(_ place: PlaceModel, on db: Database) async throws {
        if let id = place.id, try await PlaceModel.find(id, on: db) != nil {
            try await place.save(on: db)
        } else {
            try await place.create(on: db)
        }
    }
}

protocol RatingRepository {
    func findByID(_ id: UUID, on db: Database) async throws -> RatingModel?
    func save(_ rating: RatingModel, on db: Database) async throws
    func delete(_ rating: RatingModel, on db: Database) async throws
}

struct DatabaseRatingRepository: RatingRepository {
    func findByID(_ id: UUID, on db: Database) async throws -> RatingModel? {
        try await RatingModel.find(id, on: db)
    }

    func save(_ rating: RatingModel, on db: Database) async throws {
        if let id = rating.id, try await RatingModel.find(id, on: db) != nil {
            try await rating.save(on: db)
        } else {
            try await rating.create(on: db)
        }
    }

    func delete(_ rating: RatingModel, on db: Database) async throws {
        try await rating.delete(on: db)
    }
}
