import Fluent
import Vapor

struct EligibilityGuardMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let appUser = request.auth.get(AppUser.self) else {
            throw Abort(.unauthorized, reason: "Authentication required.")
        }

        let user = try await UserModel.find(appUser.id, on: request.db)
        if user?.isPostingFrozen == true {
            throw Abort(.forbidden, reason: "Interaction disabled: restricted.")
        }
        if user?.isUnderReview == true {
            throw Abort(.forbidden, reason: "Interaction disabled: under_review.")
        }

        let latest = try await EligibilitySnapshotModel.query(on: request.db)
            .filter(\.$userID == appUser.id)
            .sort(\.$evaluatedAt, .descending)
            .first()

        let state = latest.flatMap { EligibilityState(rawValue: $0.interactionEligibilityState) } ?? .browseOnly
        switch state {
        case .verifiedLocal, .provisionalLocal:
            return try await next.respond(to: request)
        case .browseOnly, .restricted, .underReview:
            throw Abort(.forbidden, reason: "Interaction disabled for state \(state.rawValue).")
        }
    }
}
