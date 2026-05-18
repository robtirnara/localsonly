import Foundation
import UIKit

@MainActor
final class SessionManager: ObservableObject {
    private var sessionInvalidationObserver: NSObjectProtocol?
    enum AppTab: Hashable {
        case feed
        /// Top locals list, map, and search (tab bar label “Explore”).
        case ranks
        case rate
        /// Saved bookmarks (AIDesigner Saved Spots); map lives inside Explore.
        case saved
        case profile
    }

    /// When true, `RootView` presents the unified onboarding + auth full-screen flow.
    @Published var presentUnauthenticatedFlow = false

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
    /// Slide-up spot detail or public profile; only one at a time (content swaps on deep link).
    @Published var presentedDetailSheet: PresentedDetailSheet?
    /// Slide-up invite friends (`invite` canvas).
    @Published var isInviteFriendsPresented = false
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

    func presentPlaceDetail(_ placeID: UUID) {
        presentedDetailSheet = .place(placeID)
    }

    func dismissPlaceDetail() {
        if case .place = presentedDetailSheet {
            presentedDetailSheet = nil
        }
    }

    func dismissDetailSheet() {
        presentedDetailSheet = nil
    }

    func presentInviteFriends() {
        isInviteFriendsPresented = true
    }

    func dismissInviteFriends() {
        isInviteFriendsPresented = false
    }

    func presentUserProfile(_ userID: UUID) {
        presentedDetailSheet = .userProfile(userID)
    }

    func dismissUserProfile() {
        if case .userProfile = presentedDetailSheet {
            presentedDetailSheet = nil
        }
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

    /// After **Profile Setup** (`signup-2` canvas). No email/password API yet — DEBUG uses `dev-login` for local iteration.
    @discardableResult
    func submitProfileSetupSignup(username: String, password: String) async -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        displayName = trimmed
        _ = password
        #if DEBUG
        return await devStressLogin()
        #else
        showInfo("Email sign-up is coming soon.")
        return false
        #endif
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

    #if DEBUG
    @discardableResult
    func devStressLogin() async -> Bool {
        do {
            _ = try await api.devLogin()
            signedIn = true
            showSuccess("Dev session")
            Task { await refreshEligibility() }
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }
    #endif

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
        presentedDetailSheet = nil
        isInviteFriendsPresented = false
        bookmarkedPlaceIDs = []
        unreadNotificationCount = 0
        presentUnauthenticatedFlow = true
        showInfo("Signed out")
    }

    private func handleRemoteSessionInvalidation() {
        guard signedIn else { return }
        api.signOut()
        signedIn = false
        eligibilityState = "unknown"
        selectedTab = .feed
        selectedPlace = nil
        presentedDetailSheet = nil
        isInviteFriendsPresented = false
        bookmarkedPlaceIDs = []
        unreadNotificationCount = 0
        presentUnauthenticatedFlow = true
        toastType = .error
        statusMessage = "Session expired. Sign in again."
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
