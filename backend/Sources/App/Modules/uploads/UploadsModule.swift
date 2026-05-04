import Foundation
import Vapor

struct UploadsModule: AppModule {
    let name = "uploads"

    func register(routes: RoutesBuilder, app: Application) {
        let uploadsDir = app.directory.workingDirectory + "uploads/"
        if !FileManager.default.fileExists(atPath: uploadsDir) {
            try? FileManager.default.createDirectory(atPath: uploadsDir, withIntermediateDirectories: true)
        }

        let authed = routes.grouped(UserTokenAuthenticator(), UserGuardMiddleware())
        authed.on(.POST, "uploads", "image", body: .collect(maxSize: "10mb"), use: { req in
            try await uploadImage(req, uploadsDir: uploadsDir)
        })
    }
}

private struct UploadResponse: Content {
    let url: String
}

private func uploadImage(_ req: Request, uploadsDir: String) async throws -> UploadResponse {
    guard let _ = req.auth.get(AppUser.self) else {
        throw Abort(.unauthorized)
    }

    guard let contentType = req.headers.contentType,
          contentType.type == "multipart" else {
        throw Abort(.badRequest, reason: "Expected multipart form data")
    }

    let boundary = contentType.parameters["boundary"] ?? ""
    guard !boundary.isEmpty else {
        throw Abort(.badRequest, reason: "Missing multipart boundary")
    }

    guard let body = req.body.data else {
        throw Abort(.badRequest, reason: "No body data")
    }

    let bytes = Data(buffer: body)
    let boundaryData = "--\(boundary)".data(using: .utf8)!

    guard let firstBoundary = bytes.range(of: boundaryData) else {
        throw Abort(.badRequest, reason: "Invalid multipart data")
    }

    let afterFirst = bytes[firstBoundary.upperBound...]

    guard let headerEnd = afterFirst.range(of: "\r\n\r\n".data(using: .utf8)!) else {
        throw Abort(.badRequest, reason: "Invalid multipart headers")
    }

    let fileDataStart = headerEnd.upperBound
    let closingBoundary = "\r\n--\(boundary)".data(using: .utf8)!

    let fileDataEnd: Data.Index
    if let closingRange = afterFirst[fileDataStart...].range(of: closingBoundary) {
        fileDataEnd = closingRange.lowerBound
    } else {
        fileDataEnd = afterFirst.endIndex
    }

    let fileData = afterFirst[fileDataStart..<fileDataEnd]
    guard !fileData.isEmpty else {
        throw Abort(.badRequest, reason: "Empty file")
    }

    let filename = "\(UUID().uuidString).jpg"
    let filePath = uploadsDir + filename

    try Data(fileData).write(to: URL(fileURLWithPath: filePath))

    let host = req.headers.first(name: .host) ?? "127.0.0.1:8080"
    let scheme = req.headers.first(name: "X-Forwarded-Proto") ?? "http"
    let url = "\(scheme)://\(host)/uploads/\(filename)"

    return UploadResponse(url: url)
}
