import Fluent
import Vapor

struct AppUser: Authenticatable {
    let id: UUID
    let phoneE164: String
}

struct UserTokenAuthenticator: AsyncBearerAuthenticator {
    typealias User = AppUser

    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        guard
            let token = try await SessionTokenModel.query(on: request.db)
                .filter(\.$token == bearer.token)
                .first(),
            token.revokedAt == nil,
            token.expiresAt > Date(),
            let user = try await UserModel.find(token.userID, on: request.db),
            let userID = user.id
        else {
            return
        }

        request.auth.login(AppUser(id: userID, phoneE164: user.phoneE164))
    }
}

struct UserGuardMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard request.auth.get(AppUser.self) != nil else {
            throw Abort(.unauthorized, reason: "Missing or invalid bearer session token.")
        }
        return try await next.respond(to: request)
    }
}

struct AdminGuardMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let expected = Environment.get("ADMIN_BEARER_TOKEN"), !expected.isEmpty else {
            throw Abort(.internalServerError, reason: "ADMIN_BEARER_TOKEN is not configured.")
        }
        guard let bearer = request.headers.bearerAuthorization, bearer.token == expected else {
            throw Abort(.unauthorized, reason: "Admin token required.")
        }
        return try await next.respond(to: request)
    }
}
