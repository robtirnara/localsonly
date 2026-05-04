import FluentSQL
import Foundation
import Vapor

struct ListsModule: AppModule {
    let name = "lists"

    func register(routes: RoutesBuilder, app: Application) {
        let authed = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware())
        authed.get("lists", use: myLists)
        authed.post("lists", use: createList)
        authed.patch("lists", ":id", use: updateList)
        authed.delete("lists", ":id", use: deleteList)
        authed.post("lists", ":id", "items", use: addItem)
        authed.delete("lists", ":id", "items", ":placeID", use: removeItem)

        routes.get("lists", ":id", use: listDetail)
        routes.get("users", ":id", "lists", use: userLists)
    }
}

private struct CreateListRequest: Content {
    let name: String
    let description: String?
    let isPublic: Bool?
}

private struct UpdateListRequest: Content {
    let name: String?
    let description: String?
    let isPublic: Bool?
}

private struct AddListItemRequest: Content {
    let placeID: UUID
    let note: String?
    let sortOrder: Int?
}

private struct ListResponse: Content {
    let id: UUID
    let userID: UUID
    let userName: String
    let name: String
    let description: String
    let isPublic: Bool
    let itemCount: Int
    let createdAt: Date
}

private struct ListDetailResponse: Content {
    let id: UUID
    let userID: UUID
    let userName: String
    let name: String
    let description: String
    let isPublic: Bool
    let items: [ListItemResponse]
    let createdAt: Date
}

private struct ListItemResponse: Content {
    let placeID: UUID
    let placeName: String
    let category: String
    let neighborhood: String?
    let coverPhotoURL: String?
    let note: String
    let sortOrder: Int
}

private struct ListRow: Decodable {
    let id: UUID
    let user_id: UUID
    let user_name: String
    let name: String
    let description: String
    let is_public: Bool
    let item_count: Int
    let created_at: Date
}

private struct ListItemRow: Decodable {
    let place_id: UUID
    let place_name: String
    let category: String
    let neighborhood: String?
    let cover_photo_url: String?
    let note: String
    let sort_order: Int
}

private func myLists(_ req: Request) async throws -> [ListResponse] {
    guard let user = req.auth.get(AppUser.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.unauthorized)
    }

    let rows = try await sql.raw("""
        SELECT l.id, l.user_id, u.display_name AS user_name,
               l.name, l.description, l.is_public,
               COUNT(li.place_id)::int AS item_count,
               l.created_at
        FROM lists l
        JOIN users u ON u.id = l.user_id
        LEFT JOIN list_items li ON li.list_id = l.id
        WHERE l.user_id = \(bind: user.id)
        GROUP BY l.id, u.display_name
        ORDER BY l.created_at DESC
        """).all(decoding: ListRow.self)

    return rows.map {
        ListResponse(id: $0.id, userID: $0.user_id, userName: $0.user_name,
                     name: $0.name, description: $0.description,
                     isPublic: $0.is_public, itemCount: $0.item_count,
                     createdAt: $0.created_at)
    }
}

private func userLists(_ req: Request) async throws -> [ListResponse] {
    guard let userID = req.parameters.get("id", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    let rows = try await sql.raw("""
        SELECT l.id, l.user_id, u.display_name AS user_name,
               l.name, l.description, l.is_public,
               COUNT(li.place_id)::int AS item_count,
               l.created_at
        FROM lists l
        JOIN users u ON u.id = l.user_id
        LEFT JOIN list_items li ON li.list_id = l.id
        WHERE l.user_id = \(bind: userID) AND l.is_public = TRUE
        GROUP BY l.id, u.display_name
        ORDER BY l.created_at DESC
        """).all(decoding: ListRow.self)

    return rows.map {
        ListResponse(id: $0.id, userID: $0.user_id, userName: $0.user_name,
                     name: $0.name, description: $0.description,
                     isPublic: $0.is_public, itemCount: $0.item_count,
                     createdAt: $0.created_at)
    }
}

private func listDetail(_ req: Request) async throws -> ListDetailResponse {
    guard let listID = req.parameters.get("id", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    struct HeaderRow: Decodable {
        let id: UUID
        let user_id: UUID
        let user_name: String
        let name: String
        let description: String
        let is_public: Bool
        let created_at: Date
    }

    guard let header = try await sql.raw("""
        SELECT l.id, l.user_id, u.display_name AS user_name,
               l.name, l.description, l.is_public, l.created_at
        FROM lists l
        JOIN users u ON u.id = l.user_id
        WHERE l.id = \(bind: listID)
        """).first(decoding: HeaderRow.self) else {
        throw Abort(.notFound)
    }

    let authedUser = req.auth.get(AppUser.self)
    if !header.is_public && authedUser?.id != header.user_id {
        throw Abort(.notFound)
    }

    let items = try await sql.raw("""
        SELECT li.place_id, p.name AS place_name, p.category,
               p.neighborhood, p.cover_photo_url,
               li.note, li.sort_order
        FROM list_items li
        JOIN places p ON p.id = li.place_id
        WHERE li.list_id = \(bind: listID)
        ORDER BY li.sort_order ASC, li.created_at ASC
        """).all(decoding: ListItemRow.self)

    return ListDetailResponse(
        id: header.id, userID: header.user_id, userName: header.user_name,
        name: header.name, description: header.description,
        isPublic: header.is_public,
        items: items.map {
            ListItemResponse(placeID: $0.place_id, placeName: $0.place_name,
                           category: $0.category, neighborhood: $0.neighborhood,
                           coverPhotoURL: $0.cover_photo_url,
                           note: $0.note, sortOrder: $0.sort_order)
        },
        createdAt: header.created_at
    )
}

private func createList(_ req: Request) async throws -> ListResponse {
    guard let user = req.auth.get(AppUser.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.unauthorized)
    }

    let payload = try req.content.decode(CreateListRequest.self)
    let trimmed = payload.name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
        throw Abort(.badRequest, reason: "List name is required")
    }

    let listID = UUID()
    let isPublic = payload.isPublic ?? true
    let description = payload.description ?? ""

    try await sql.raw("""
        INSERT INTO lists (id, user_id, name, description, is_public)
        VALUES (\(bind: listID), \(bind: user.id), \(bind: trimmed),
                \(bind: description), \(bind: isPublic))
        """).run()

    let userName = try await UserModel.find(user.id, on: req.db)?.displayName ?? "Local"

    return ListResponse(
        id: listID, userID: user.id, userName: userName,
        name: trimmed, description: description,
        isPublic: isPublic, itemCount: 0, createdAt: Date()
    )
}

private func updateList(_ req: Request) async throws -> HTTPStatus {
    guard let user = req.auth.get(AppUser.self),
          let listID = req.parameters.get("id", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    let payload = try req.content.decode(UpdateListRequest.self)

    struct OwnerRow: Decodable { let user_id: UUID }
    guard let row = try await sql.raw("""
        SELECT user_id FROM lists WHERE id = \(bind: listID)
        """).first(decoding: OwnerRow.self), row.user_id == user.id else {
        throw Abort(.forbidden)
    }

    if let name = payload.name {
        try await sql.raw("UPDATE lists SET name = \(bind: name), updated_at = NOW() WHERE id = \(bind: listID)").run()
    }
    if let desc = payload.description {
        try await sql.raw("UPDATE lists SET description = \(bind: desc), updated_at = NOW() WHERE id = \(bind: listID)").run()
    }
    if let isPublic = payload.isPublic {
        try await sql.raw("UPDATE lists SET is_public = \(bind: isPublic), updated_at = NOW() WHERE id = \(bind: listID)").run()
    }

    return .ok
}

private func deleteList(_ req: Request) async throws -> HTTPStatus {
    guard let user = req.auth.get(AppUser.self),
          let listID = req.parameters.get("id", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    struct OwnerRow: Decodable { let user_id: UUID }
    guard let row = try await sql.raw("""
        SELECT user_id FROM lists WHERE id = \(bind: listID)
        """).first(decoding: OwnerRow.self), row.user_id == user.id else {
        throw Abort(.forbidden)
    }

    try await sql.raw("DELETE FROM lists WHERE id = \(bind: listID)").run()
    return .noContent
}

private func addItem(_ req: Request) async throws -> HTTPStatus {
    guard let user = req.auth.get(AppUser.self),
          let listID = req.parameters.get("id", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    let payload = try req.content.decode(AddListItemRequest.self)

    struct OwnerRow: Decodable { let user_id: UUID }
    guard let row = try await sql.raw("""
        SELECT user_id FROM lists WHERE id = \(bind: listID)
        """).first(decoding: OwnerRow.self), row.user_id == user.id else {
        throw Abort(.forbidden)
    }

    let sortOrder = payload.sortOrder ?? 0
    let note = payload.note ?? ""

    try await sql.raw("""
        INSERT INTO list_items (list_id, place_id, sort_order, note)
        VALUES (\(bind: listID), \(bind: payload.placeID), \(bind: sortOrder), \(bind: note))
        ON CONFLICT (list_id, place_id) DO UPDATE
        SET sort_order = EXCLUDED.sort_order, note = EXCLUDED.note
        """).run()

    return .ok
}

private func removeItem(_ req: Request) async throws -> HTTPStatus {
    guard let user = req.auth.get(AppUser.self),
          let listID = req.parameters.get("id", as: UUID.self),
          let placeID = req.parameters.get("placeID", as: UUID.self),
          let sql = req.db as? SQLDatabase else {
        throw Abort(.badRequest)
    }

    struct OwnerRow: Decodable { let user_id: UUID }
    guard let row = try await sql.raw("""
        SELECT user_id FROM lists WHERE id = \(bind: listID)
        """).first(decoding: OwnerRow.self), row.user_id == user.id else {
        throw Abort(.forbidden)
    }

    try await sql.raw("""
        DELETE FROM list_items WHERE list_id = \(bind: listID) AND place_id = \(bind: placeID)
        """).run()

    return .noContent
}
