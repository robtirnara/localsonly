import Foundation
import UIKit

@MainActor
final class SessionManager: ObservableObject {
    private var sessionInvalidationObserver: NSObjectProtocol?
    enum AppTab: Hashable {
        case feed
        /// Rankings list & search (matches reference “Ranks”).
        case ranks
        case rate
        /// Full map (reference tab bar).
        case map
        case profile
    }

    @Published var phoneE164: String = ""
    @Published var displayName: String = ""
    @Published var inviteCode: String = ""
    @Published var otpCode: String = ""

    @Published var signedIn: Bool
    @Published var eligibilityState: String = "unknown"
    @Published var statusMessage: String = ""
    @Published var toastType: ToastType = .info
    @Published var selectedTab: AppTab = .feed

    @Published var selectedPlace: PlaceResponse?
    @Published var hasUnsavedRating: Bool = false
    @Published var bookmarkedPlaceIDs: Set<UUID> = []
    @Published var unreadNotificationCount: Int = 0

    let api: APIClient

    init(api: APIClient = APIClient()) {
        self.api = api
        self.signedIn = api.hasSession
        sessionInvalidationObserver = NotificationCenter.default.addObserver(
            forName: .localsonlySessionInvalidated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleRemoteSessionInvalidation()
            }
        }
    }

    deinit {
        if let sessionInvalidationObserver {
            NotificationCenter.default.removeObserver(sessionInvalidationObserver)
        }
    }

    func showSuccess(_ message: String) {
        toastType = .success
        statusMessage = message
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func showError(_ message: String) {
        let lower = message.lowercased()
        // Token is cleared on 401 before the error propagates; avoid duplicating the session-expired toast.
        if (lower.contains("unauthorized") || lower.contains("sign in again")), !api.hasSession {
            return
        }
        toastType = .error
        statusMessage = message
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func showInfo(_ message: String) {
        toastType = .info
        statusMessage = message
    }

    @discardableResult
    func sendCode() async -> Bool {
        do {
            let response = try await api.sendCode(phoneE164: phoneE164)
            showInfo("Code sent. Dev code: \(response.devCode)")
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    @discardableResult
    func verifyAndJoin() async -> Bool {
        do {
            _ = try await api.verifyCode(
                phoneE164: phoneE164,
                code: otpCode,
                displayName: displayName.isEmpty ? nil : displayName,
                inviteCode: inviteCode.isEmpty ? nil : inviteCode
            )
            signedIn = true
            showSuccess("Welcome to localsonly")
            Task { await refreshEligibility() }
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func refreshEligibility() async {
        guard signedIn else {
            eligibilityState = "browse_only"
            return
        }
        do {
            _ = try await api.eligibilityCheck(coarseAreaCode: "SanDiego")
            let status = try await api.eligibilityStatus()
            eligibilityState = status.interactionEligibilityState
        } catch {
            showError(error.localizedDescription)
        }
    }

    func loadBookmarks() async {
        guard signedIn else { return }
        do {
            let bookmarks = try await api.listBookmarks()
            bookmarkedPlaceIDs = Set(bookmarks.map(\.id))
        } catch {}
    }

    func toggleBookmark(placeID: UUID) async {
        if bookmarkedPlaceIDs.contains(placeID) {
            bookmarkedPlaceIDs.remove(placeID)
            do {
                try await api.removeBookmark(placeID: placeID)
                showSuccess("Bookmark removed")
            } catch {
                bookmarkedPlaceIDs.insert(placeID)
                showError(error.localizedDescription)
            }
        } else {
            bookmarkedPlaceIDs.insert(placeID)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            do {
                try await api.addBookmark(placeID: placeID)
                showSuccess("Place saved")
            } catch {
                bookmarkedPlaceIDs.remove(placeID)
                showError(error.localizedDescription)
            }
        }
    }

    func refreshNotificationCount() async {
        guard signedIn else { return }
        do {
            let response = try await api.unreadNotificationCount()
            unreadNotificationCount = response.count
        } catch {}
    }

    func signOut() {
        api.signOut()
        signedIn = false
        eligibilityState = "unknown"
        selectedTab = .feed
        selectedPlace = nil
        bookmarkedPlaceIDs = []
        unreadNotificationCount = 0
        showInfo("Signed out")
    }

    private func handleRemoteSessionInvalidation() {
        guard signedIn else { return }
        api.signOut()
        signedIn = false
        eligibilityState = "unknown"
        selectedTab = .feed
        selectedPlace = nil
        bookmarkedPlaceIDs = []
        unreadNotificationCount = 0
        toastType = .error
        statusMessage = "Session expired. Sign in again."
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
