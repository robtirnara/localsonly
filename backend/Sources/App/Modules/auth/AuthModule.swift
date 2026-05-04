import Fluent
import Foundation
import Vapor

struct AuthModule: AppModule {
    let name = "auth"

    func register(routes: RoutesBuilder, app: Application) {
        let auth = routes.grouped("auth")
        auth.post("send-code", use: sendCode)
        auth.post("verify-code", use: verifyCode)
    }
}

private struct SendCodeRequest: Content {
    let phoneE164: String
}

private struct SendCodeResponse: Content {
    let ok: Bool
    let devCode: String
}

private struct VerifyCodeRequest: Content {
    let phoneE164: String
    let code: String
    let displayName: String?
    let inviteCode: String?
}

private struct VerifyCodeResponse: Content {
    let token: String
    let userID: UUID
    let displayName: String
}

private func sendCode(_ req: Request) async throws -> SendCodeResponse {
    _ = try req.content.decode(SendCodeRequest.self)
    return SendCodeResponse(ok: true, devCode: "111111")
}

private func verifyCode(_ req: Request) async throws -> VerifyCodeResponse {
    let payload = try req.content.decode(VerifyCodeRequest.self)
    let userRepo = DatabaseUserRepository()
    guard payload.code == "111111" else {
        throw Abort(.unauthorized, reason: "Invalid code.")
    }

    var inviterUserID: UUID?
    if let inviteCode = payload.inviteCode, !inviteCode.isEmpty {
        inviterUserID = try await InviteModel.query(on: req.db)
            .filter(\.$code == inviteCode)
            .filter(\.$status == "issued")
            .first()?
            .inviterUserID
    }

    let user: UserModel
    if let existing = try await userRepo.findByPhone(payload.phoneE164, on: req.db) {
        user = existing
        if let displayName = payload.displayName, !displayName.isEmpty {
            user.displayName = displayName
            try await userRepo.save(user, on: req.db)
        }
    } else {
        let created = UserModel(
            id: UUID(),
            phoneE164: payload.phoneE164,
            displayName: payload.displayName?.isEmpty == false ? payload.displayName! : "Local User",
            inviterUserID: inviterUserID
        )
        try await userRepo.save(created, on: req.db)
        user = created
    }

    guard let userID = user.id else {
        throw Abort(.internalServerError, reason: "User id missing.")
    }

    let token = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    let session = SessionTokenModel(
        id: UUID(),
        token: token,
        userID: userID,
        expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date().addingTimeInterval(2_592_000)
    )
    try await session.create(on: req.db)

    return VerifyCodeResponse(token: token, userID: userID, displayName: user.displayName)
}

private extension String {
    var isEmptyOrWhitespace: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
