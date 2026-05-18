import SwiftUI

struct RootView: View {
    @StateObject private var session = SessionManager()
    @State private var showDiscardAlert = false
    @State private var pendingTab: SessionManager.AppTab?
    @State private var showOnboarding = false
    /// First-launch carousel (AIDesigner welcome → community → tastes → sign up). Independent of auth.
    @AppStorage("hasCompletedLaunchOnboarding") private var hasCompletedLaunchOnboarding = false
    /// Bump when onboarding visuals/steps change so existing installs see the new flow once.
    private let launchOnboardingRevision = 7
    @AppStorage("launchOnboardingRevisionCompleted") private var launchOnboardingRevisionCompleted = 0
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            Color.coastalBackground
                .ignoresSafeArea()

            if session.signedIn {
                signedInTabs
            } else {
                Color.coastalBackground.ignoresSafeArea()
            }
        }
        .tint(.coastalCoral)
        .preferredColorScheme(colorScheme)
        .environmentObject(session)
        .overlay(alignment: .top) {
            if !session.statusMessage.isEmpty {
                ToastView(message: session.statusMessage, type: session.toastType)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, Spacing.sm)
                    .gesture(
                        DragGesture(minimumDistance: 5)
                            .onEnded { value in
                                if value.translation.height < -10 {
                                    session.statusMessage = ""
                                }
                            }
                    )
                    .onTapGesture {
                        session.statusMessage = ""
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.statusMessage)
        .onChange(of: session.statusMessage) { _, newValue in
            guard !newValue.isEmpty else { return }
            Task {
                try? await Task.sleep(for: .seconds(3))
                if session.statusMessage == newValue {
                    session.statusMessage = ""
                }
            }
        }
        .alert("Discard rating?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) {
                session.hasUnsavedRating = false
                if let tab = pendingTab {
                    session.selectedTab = tab
                    pendingTab = nil
                }
            }
            Button("Keep Editing", role: .cancel) {
                pendingTab = nil
            }
        } message: {
            Text("You have an unsaved rating. Are you sure you want to leave?")
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingScreen(isPresented: $showOnboarding)
                .environmentObject(session)
        }
        .onChange(of: showOnboarding) { _, newValue in
            if !newValue, session.signedIn {
                hasCompletedLaunchOnboarding = true
                launchOnboardingRevisionCompleted = launchOnboardingRevision
                session.presentUnauthenticatedFlow = false
            } else if !newValue, !session.signedIn {
                // Avoid racing the fullScreenCover dismiss with `session.signedIn` flipping to `true`
                // (would immediately re-present onboarding and block post-login dismiss).
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(120))
                    if !session.signedIn {
                        showOnboarding = true
                    }
                }
            }
        }
        .onChange(of: session.signedIn) { _, signedIn in
            if !signedIn {
                showOnboarding = true
            }
        }
        .onChange(of: session.presentUnauthenticatedFlow) { _, show in
            if show { showOnboarding = true }
        }
        .task {
            if launchOnboardingRevisionCompleted < launchOnboardingRevision || !hasCompletedLaunchOnboarding {
                showOnboarding = true
            } else if !session.signedIn {
                showOnboarding = true
            }
            if session.signedIn {
                await session.refreshEligibility()
                await session.loadBookmarks()
                await session.refreshNotificationCount()
            }
        }
    }

    /// Reference layout: custom bottom bar (outline + gray inactive / fill + coral selected); no system `TabView` chrome.
    private var signedInTabs: some View {
        Group {
            switch session.selectedTab {
            case .feed:
                FeedScreen()
            case .ranks:
                ExploreScreen()
            case .rate:
                RateScreen()
            case .saved:
                SavedPlacesScreen(embedded: true)
            case .profile:
                ProfileScreen()
            }
        }
        // `Group` + `switch` has no intrinsic size in a `ZStack` (unlike `TabView`), so it collapses to zero without this.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CoastalTabBar(selection: tabBinding)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sheet(item: $session.presentedDetailSheet) { route in
            Group {
                switch route {
                case .place(let placeID):
                    PlaceDetailScreen(placeID: placeID)
                case .userProfile(let userID):
                    UserProfileScreen(userID: userID)
                }
            }
            .environmentObject(session)
            .id(route.id)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground(Color.feedCanvasSand)
        }
        .sheet(isPresented: $session.isInviteFriendsPresented) {
            InviteScreen()
                .environmentObject(session)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground(Color.feedCanvasSand)
        }
    }

    private var tabBinding: Binding<SessionManager.AppTab> {
        Binding(
            get: { session.selectedTab },
            set: { newTab in
                if session.selectedTab == .rate && newTab != .rate && session.hasUnsavedRating {
                    pendingTab = newTab
                    showDiscardAlert = true
                } else {
                    session.selectedTab = newTab
                }
            }
        )
    }
}
