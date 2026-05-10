import SwiftUI

struct RootView: View {
    @StateObject private var session = SessionManager()
    @State private var showDiscardAlert = false
    @State private var pendingTab: SessionManager.AppTab?
    @State private var showOnboarding = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
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
                AuthScreen()
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
        }
        .onChange(of: showOnboarding) { _, newValue in
            if !newValue { hasSeenOnboarding = true }
        }
        .task {
            if session.signedIn {
                await session.refreshEligibility()
                await session.loadBookmarks()
                await session.refreshNotificationCount()
                if !hasSeenOnboarding {
                    showOnboarding = true
                }
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
            case .map:
                MapTabScreen()
            case .profile:
                ProfileScreen()
            }
        }
        // `Group` + `switch` has no intrinsic size in a `ZStack` (unlike `TabView`), so it collapses to zero without this.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CoastalTabBar(selection: tabBinding)
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

/// Map tab matching reference navigation (full-screen map + place detail).
private struct MapTabScreen: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        NavigationStack {
            MapExploreView()
                .navigationTitle("Map")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: UUID.self) { placeID in
                    PlaceDetailScreen(placeID: placeID)
                }
        }
    }
}
