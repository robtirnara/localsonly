import Fluent
import FluentSQL
import Foundation
import Vapor

struct ItemCategoriesModule: AppModule {
    let name = "item_categories"

    func register(routes: RoutesBuilder, app: Application) {
        routes.get("item-categories", "search", use: searchItemCategories)
    }
}

private struct ItemCategoryResponse: Content {
    let slug: String
    let displayName: String
    let usageCount: Int
}

private struct ItemCategoryRow: Decodable {
    let slug: String
    let display_name: String
    let usage_count: Int
}

private func searchItemCategories(_ req: Request) async throws -> [ItemCategoryResponse] {
    guard let sql = req.db as? SQLDatabase else {
        throw Abort(.internalServerError)
    }
    let q = (req.query[String.self, at: "q"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !q.isEmpty else { return [] }

    let pattern = "%\(q)%"
    let rows = try await sql.raw("""
        SELECT slug, display_name, usage_count
        FROM item_categories
        WHERE display_name ILIKE \(bind: pattern)
           OR slug ILIKE \(bind: pattern)
        ORDER BY usage_count DESC, display_name ASC
        LIMIT 15
        """).all(decoding: ItemCategoryRow.self)

    return rows.map {
        ItemCategoryResponse(slug: $0.slug, displayName: $0.display_name, usageCount: $0.usage_count)
    }
}

enum ItemCategoryRegistry {
    static func normalizeSlug(_ raw: String) -> String {
        let lowered = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let underscored = lowered.replacingOccurrences(
            of: "\\s+",
            with: "_",
            options: .regularExpression
        )
        return String(underscored.filter { $0.isLetter || $0.isNumber || $0 == "_" })
    }

    static func register(_ raw: String, on db: Database) async throws {
        guard let sql = db as? SQLDatabase else { return }
        let display = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !display.isEmpty else { return }
        let slug = normalizeSlug(display)
        guard !slug.isEmpty else { return }

        try await sql.raw("""
            INSERT INTO item_categories (slug, display_name, usage_count, created_at, updated_at)
            VALUES (\(bind: slug), \(bind: display), 1, NOW(), NOW())
            ON CONFLICT (slug) DO UPDATE SET
                usage_count = item_categories.usage_count + 1,
                display_name = EXCLUDED.display_name,
                updated_at = NOW()
            """).run()
    }
}
