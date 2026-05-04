import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .unauthorized:
            return "Unauthorized. Sign in again."
        case .serverError(let message):
            return message
        }
    }
}

final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let sessionStore: SessionStore
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    private static var defaultBaseURL: String {
        if let env = ProcessInfo.processInfo.environment["LOCALSONLY_API_BASE_URL"], !env.isEmpty { return env }
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:8080"
        #else
        return "http://192.168.1.182:8080"
        #endif
    }

    init(baseURL: String = APIClient.defaultBaseURL) {
        guard let url = URL(string: baseURL) else {
            self.baseURL = URL(string: "http://127.0.0.1:8080")!
            self.session = .shared
            self.sessionStore = SessionStore()
            self.jsonEncoder = JSONEncoder()
            self.jsonDecoder = JSONDecoder()
            return
        }
        self.baseURL = url
        self.session = .shared
        self.sessionStore = SessionStore()
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
        self.jsonDecoder.dateDecodingStrategy = .iso8601
    }

    var hasSession: Bool { sessionStore.token != nil }

    func signOut() { sessionStore.clear() }

    func sendCode(phoneE164: String) async throws -> AuthSendCodeResponse {
        try await request(
            method: "POST",
            path: "/auth/send-code",
            body: AuthSendCodeRequest(phoneE164: phoneE164),
            authenticated: false
        )
    }

    func verifyCode(phoneE164: String, code: String, displayName: String?, inviteCode: String?) async throws -> AuthVerifyCodeResponse {
        let response: AuthVerifyCodeResponse = try await request(
            method: "POST",
            path: "/auth/verify-code",
            body: AuthVerifyCodeRequest(
                phoneE164: phoneE164,
                code: code,
                displayName: displayName,
                inviteCode: inviteCode
            ),
            authenticated: false
        )
        sessionStore.token = response.token
        return response
    }

    func eligibilityCheck(coarseAreaCode: String = "SanDiego") async throws -> EligibilityStatusResponse {
        try await request(
            method: "POST",
            path: "/eligibility/check",
            body: EligibilityCheckRequest(coarseAreaCode: coarseAreaCode, latitude: nil, longitude: nil),
            authenticated: true
        )
    }

    func eligibilityStatus() async throws -> EligibilityStatusResponse {
        try await request(method: "GET", path: "/eligibility/status", authenticated: true)
    }

    func searchPlaces(query: String, city: String = "SanDiego") async throws -> [PlaceResponse] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await request(method: "GET", path: "/places/search?q=\(encoded)&city=\(city)", authenticated: false)
    }

    func suggestPlace(name: String, neighborhood: String?, category: String, city: String?) async throws -> PlaceResponse {
        try await request(
            method: "POST",
            path: "/places/suggest",
            body: PlaceSuggestRequest(name: name, neighborhood: neighborhood, category: category, city: city),
            authenticated: true
        )
    }

    func createRating(
        placeID: UUID,
        itemName: String,
        itemCategory: String,
        score: Double,
        notes: String,
        privacy: String,
        photoURL: String? = nil
    ) async throws -> RatingResponse {
        try await request(
            method: "POST",
            path: "/ratings",
            body: CreateRatingRequest(
                placeID: placeID,
                itemName: itemName,
                itemCategory: itemCategory,
                score: score,
                notes: notes,
                visitDate: nil,
                privacy: privacy,
                photoURL: photoURL
            ),
            authenticated: true
        )
    }

    func deleteRating(id: UUID) async throws {
        guard let requestURL = URL(string: "/ratings/\(id.uuidString)", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Failed to delete rating.")
        }
    }

    func placeDetail(id: UUID) async throws -> PlaceResponse {
        try await request(method: "GET", path: "/places/\(id.uuidString)", authenticated: false)
    }

    func placeRatings(id: UUID) async throws -> [PlaceRatingResponse] {
        try await request(method: "GET", path: "/places/\(id.uuidString)/ratings", authenticated: false)
    }

    func myRatings(sort: String = "createdAtDesc", privacy: String? = nil) async throws -> [RatingResponse] {
        var path = "/me/ratings?sort=\(sort)"
        if let privacy { path += "&privacy=\(privacy)" }
        return try await request(method: "GET", path: path, authenticated: true)
    }

    func myRatingsRankings(category: String) async throws -> [RatingResponse] {
        let encoded = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category
        return try await request(method: "GET", path: "/me/ratings/rankings?category=\(encoded)", authenticated: true)
    }

    func friendsFeed() async throws -> [FeedEventResponse] {
        try await request(method: "GET", path: "/feed/friends", authenticated: true)
    }

    func popularFeed(city: String = "SanDiego") async throws -> [PopularPlaceResponse] {
        try await request(method: "GET", path: "/feed/popular?city=\(city)", authenticated: false)
    }

    func myProfile() async throws -> UserProfileResponse {
        try await request(method: "GET", path: "/me/profile", authenticated: true)
    }

    func updateMyProfile(displayName: String?, bio: String?, avatarURL: String?) async throws -> UserProfileResponse {
        try await request(
            method: "PATCH",
            path: "/me/profile",
            body: UpdateMyProfileRequest(displayName: displayName, bio: bio, avatarURL: avatarURL),
            authenticated: true
        )
    }

    func uploadImage(data: Data) async throws -> String {
        guard let requestURL = URL(string: "/uploads/image", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        let boundary = UUID().uuidString
        var req = URLRequest(url: requestURL)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (responseData, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Image upload failed.")
        }
        let result = try jsonDecoder.decode(UploadResponse.self, from: responseData)
        return result.url
    }

    func updateRating(id: UUID, score: Double?, itemName: String?, itemCategory: String?,
                       notes: String?, privacy: String?, photoURL: String?) async throws -> RatingResponse {
        try await request(
            method: "PATCH",
            path: "/ratings/\(id.uuidString)",
            body: UpdateRatingRequest(score: score, itemName: itemName, itemCategory: itemCategory,
                                      notes: notes, visitDate: nil, privacy: privacy, photoURL: photoURL),
            authenticated: true
        )
    }

    func searchUsers(query: String) async throws -> [UserSearchResponse] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await request(method: "GET", path: "/users/search?q=\(encoded)", authenticated: false)
    }

    func userProfile(id: UUID) async throws -> UserProfileResponse {
        try await request(method: "GET", path: "/users/\(id.uuidString)/profile", authenticated: false)
    }

    func userRatings(id: UUID) async throws -> [RatingResponse] {
        try await request(method: "GET", path: "/users/\(id.uuidString)/ratings", authenticated: false)
    }

    func friends() async throws -> [FriendResponse] {
        try await request(method: "GET", path: "/friends", authenticated: true)
    }

    func pendingFriendRequests() async throws -> [FriendResponse] {
        try await request(method: "GET", path: "/friends/pending", authenticated: true)
    }

    func sendFriendRequest(userID: UUID) async throws {
        guard let requestURL = URL(string: "/friends/request", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try jsonEncoder.encode(FriendRequestPayload(userID: userID))
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Failed to send friend request.")
        }
    }

    func acceptFriendRequest(userID: UUID) async throws {
        guard let requestURL = URL(string: "/friends/\(userID.uuidString)/accept", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Failed to accept friend request.")
        }
    }

    func placesNearby(city: String = "SanDiego") async throws -> [PlaceMapResponse] {
        try await request(method: "GET", path: "/places/nearby?city=\(city)", authenticated: false)
    }

    func listTags() async throws -> [TagResponse] {
        try await request(method: "GET", path: "/tags", authenticated: false)
    }

    func popularTags() async throws -> [PopularTagResponse] {
        try await request(method: "GET", path: "/tags/popular", authenticated: false)
    }

    func addTagsToRating(ratingID: UUID, tags: [String]) async throws {
        guard let requestURL = URL(string: "/ratings/\(ratingID.uuidString)/tags", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try jsonEncoder.encode(AddTagsRequest(tags: tags))
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Failed to add tags.")
        }
    }

    func tagsForRating(ratingID: UUID) async throws -> [TagResponse] {
        try await request(method: "GET", path: "/ratings/\(ratingID.uuidString)/tags", authenticated: false)
    }

    // MARK: - Bookmarks

    func listBookmarks() async throws -> [BookmarkedPlaceResponse] {
        try await request(method: "GET", path: "/bookmarks", authenticated: true)
    }

    func addBookmark(placeID: UUID) async throws {
        guard let requestURL = URL(string: "/bookmarks/\(placeID.uuidString)", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Failed to bookmark place.")
        }
    }

    func removeBookmark(placeID: UUID) async throws {
        guard let requestURL = URL(string: "/bookmarks/\(placeID.uuidString)", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Failed to remove bookmark.")
        }
    }

    // MARK: - Lists

    func myLists() async throws -> [ListResponse] {
        try await request(method: "GET", path: "/lists", authenticated: true)
    }

    func listDetail(id: UUID) async throws -> ListDetailResponse {
        try await request(method: "GET", path: "/lists/\(id.uuidString)", authenticated: true)
    }

    func createList(name: String, description: String?, isPublic: Bool) async throws -> ListResponse {
        try await request(
            method: "POST", path: "/lists",
            body: CreateListRequest(name: name, description: description, isPublic: isPublic),
            authenticated: true
        )
    }

    func deleteList(id: UUID) async throws {
        guard let requestURL = URL(string: "/lists/\(id.uuidString)", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Failed to delete list.")
        }
    }

    func addListItem(listID: UUID, placeID: UUID, note: String? = nil) async throws {
        guard let requestURL = URL(string: "/lists/\(listID.uuidString)/items", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try jsonEncoder.encode(AddListItemRequest(placeID: placeID, note: note, sortOrder: nil))
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Failed to add item to list.")
        }
    }

    func removeListItem(listID: UUID, placeID: UUID) async throws {
        guard let requestURL = URL(string: "/lists/\(listID.uuidString)/items/\(placeID.uuidString)", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Failed to remove item from list.")
        }
    }

    // MARK: - Cosigns

    func cosignRating(ratingID: UUID) async throws {
        guard let requestURL = URL(string: "/ratings/\(ratingID.uuidString)/cosign", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Failed to cosign rating.")
        }
    }

    func removeCosign(ratingID: UUID) async throws {
        guard let requestURL = URL(string: "/ratings/\(ratingID.uuidString)/cosign", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Failed to remove cosign.")
        }
    }

    func getCosigns(ratingID: UUID) async throws -> CosignCountResponse {
        try await request(method: "GET", path: "/ratings/\(ratingID.uuidString)/cosigns", authenticated: true)
    }

    // MARK: - Notifications

    func listNotifications() async throws -> [NotificationResponse] {
        try await request(method: "GET", path: "/notifications", authenticated: true)
    }

    func unreadNotificationCount() async throws -> UnreadCountResponse {
        try await request(method: "GET", path: "/notifications/unread-count", authenticated: true)
    }

    func markAllNotificationsRead() async throws {
        guard let requestURL = URL(string: "/notifications/mark-read", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Failed to mark notifications read.")
        }
    }

    // MARK: - Invites

    func myInviteCode() async throws -> InviteCodeResponse {
        try await request(method: "GET", path: "/invites/my-code", authenticated: true)
    }

    func invitedUsers() async throws -> [InvitedUserResponse] {
        try await request(method: "GET", path: "/invites/invited-users", authenticated: true)
    }

    // MARK: - Neighborhoods

    func listNeighborhoods(city: String = "SanDiego") async throws -> [NeighborhoodResponse] {
        try await request(method: "GET", path: "/places/neighborhoods?city=\(city)", authenticated: false)
    }

    // MARK: - Item Search

    func searchByItem(query: String, city: String = "SanDiego") async throws -> [ItemSearchResponse] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await request(method: "GET", path: "/places/search-items?q=\(encoded)&city=\(city)", authenticated: false)
    }

    // MARK: - Admin

    func adminRequest<T: Decodable>(method: String, path: String, adminToken: String, body: (some Encodable)? = Optional<String>.none) async throws -> T {
        guard let requestURL = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(adminToken)", forHTTPHeaderField: "Authorization")
        if let body {
            req.httpBody = try jsonEncoder.encode(body)
        }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.serverError("No HTTP response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Admin request failed."
            throw APIError.serverError(message)
        }
        return try jsonDecoder.decode(T.self, from: data)
    }

    func adminListUsers(token: String) async throws -> [AdminUserResponse] {
        try await adminRequest(method: "GET", path: "/admin/users", adminToken: token)
    }

    func adminListRatings(token: String) async throws -> [AdminRatingResponse] {
        try await adminRequest(method: "GET", path: "/admin/ratings", adminToken: token)
    }

    func adminFlagUser(id: UUID, reason: String, token: String) async throws {
        try await adminAction(method: "POST", path: "/moderation/users/\(id.uuidString)/flag", adminToken: token, body: AdminReasonPayload(reason: reason))
    }

    func adminFreezeUser(id: UUID, reason: String, token: String) async throws {
        try await adminAction(method: "POST", path: "/moderation/users/\(id.uuidString)/freeze-posting", adminToken: token, body: AdminReasonPayload(reason: reason))
    }

    func adminSuppressRating(id: UUID, reason: String, token: String) async throws {
        try await adminAction(method: "POST", path: "/moderation/ratings/\(id.uuidString)/suppress", adminToken: token, body: AdminReasonPayload(reason: reason))
    }

    private func adminAction(method: String, path: String, adminToken: String, body: some Encodable) async throws {
        guard let requestURL = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(adminToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try jsonEncoder.encode(body)
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("Admin action failed.")
        }
    }

    private func request<T: Decodable>(method: String, path: String, authenticated: Bool) async throws -> T {
        try await request(method: method, path: path, body: Optional<String>.none, authenticated: authenticated)
    }

    private func request<T: Decodable, B: Encodable>(
        method: String,
        path: String,
        body: B?,
        authenticated: Bool
    ) async throws -> T {
        guard let requestURL = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated, let token = sessionStore.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try jsonEncoder.encode(body)
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch is URLError {
            throw APIError.serverError("Couldn't connect. Check your internet connection and try again.")
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.serverError("No HTTP response.")
        }

        switch http.statusCode {
        case 200..<300:
            return try jsonDecoder.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        default:
            let message = String(data: data, encoding: .utf8) ?? "Request failed with status \(http.statusCode)"
            throw APIError.serverError(message)
        }
    }
}
