import SwiftUI
import UIKit

// AIDesigner MCP flow: `localsonly-home` → `testimonials` → `cravings` → `signup` → `signup-2` → `verify-local` (first session).
// Canvases: tastes `cace7aa4…`, sign up `7369e4fc…`, profile setup `1a52a238…`, verify local `97b8a82c…` — parity vs `get_canvas` per step.

struct OnboardingScreen: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var session: SessionManager

    @AppStorage("hasCompletedVerifyLocalFlow") private var hasCompletedVerifyLocalFlow = false

    @State private var currentStep = 0
    @State private var showProfileSetup = false
    @State private var awaitingVerifyLocal = false
    /// Default selection matches `cravings` canvas (`fish_tacos`, `margaritas`, `craft_cerveza`).
    @State private var selectedTastes: Set<String> = ["fish_tacos", "margaritas", "craft_cerveza"]

    /// Order and copy from MCP `cravings` / Select Tastes HTML.
    private let cravingsCanvasPills: [CravingsCanvasPill] = [
        .init(id: "fish_tacos", label: "🌮 Fish Tacos"),
        .init(id: "cold_brew", label: "☕️ Cold Brew"),
        .init(id: "acai", label: "🥥 Acai Bowls"),
        .init(id: "margaritas", label: "🍹 Margaritas"),
        .init(id: "avocado_toast", label: "🥑 Avocado Toast"),
        .init(id: "surf_burgers", label: "🍔 Surf Burgers"),
        .init(id: "local_scoops", label: "🍦 Local Scoops"),
        .init(id: "oysters", label: "🦪 Oysters"),
        .init(id: "craft_cerveza", label: "🍺 Craft Cerveza"),
        .init(id: "poke_bowls", label: "🥗 Poke Bowls"),
        .init(id: "woodfired_pizza", label: "🍕 Woodfired Pizza"),
        .init(id: "sunset_wine", label: "🍷 Sunset Wine"),
        .init(id: "lobster_rolls", label: "🦞 Lobster Rolls")
    ]

    var body: some View {
        ZStack {
            if awaitingVerifyLocal {
                tastesScreenBackgroundFill
            } else if showProfileSetup {
                Color(hex: 0xFFF6ED).ignoresSafeArea()
            } else {
                switch currentStep {
                case 0:
                    welcomeScreenBackgroundFill
                case 1:
                    communityScreenBackgroundFill
                case 2:
                    tastesScreenBackgroundFill
                case 3:
                    signupScreenBackgroundFill
                default:
                    Color.coastalBackground.ignoresSafeArea()
                }
            }

            if awaitingVerifyLocal {
                VerifyLocalStatusScreen {
                    hasCompletedVerifyLocalFlow = true
                    awaitingVerifyLocal = false
                    isPresented = false
                }
            } else if showProfileSetup {
                ProfileSetupScreen(
                    onDismiss: {
                        showProfileSetup = false
                    },
                    onProceedToVerifyLocal: {
                        showProfileSetup = false
                        awaitingVerifyLocal = true
                    }
                )
                .environmentObject(session)
            } else {
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    communitySocialStep.tag(1)
                    vibeTastesStep.tag(2)
                    dropAnchorSignUpStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onAppear {
                    // Page-style TabView sits in a UIScrollView; default background reads as white bands above/below the page.
                    UIScrollView.appearance().backgroundColor = .clear
                }
                .onDisappear {
                    UIScrollView.appearance().backgroundColor = nil
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: awaitingVerifyLocal)
        .animation(.easeInOut(duration: 0.25), value: showProfileSetup)
        .onChange(of: session.signedIn) { _, signedIn in
            guard signedIn else { return }
            showProfileSetup = false
            if !hasCompletedVerifyLocalFlow {
                awaitingVerifyLocal = true
            } else {
                isPresented = false
            }
        }
    }

    // MARK: - Welcome (`localsonly-home` — Tailwind tokens: pale-sky, sand-gray, deep-ocean, ink; SF Rounded ≈ Fredoka/Outfit)

    private var welcomeStep: some View {
        GeometryReader { geo in
            let w = geo.size.width
            VStack(alignment: .center, spacing: 0) {
                welcomeLogoMark
                    .padding(.bottom, 32)

                Text("localsonly")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(WelcomeCanvasColors.ink)
                    .tracking(-0.5)
                    .padding(.bottom, 12)

                welcomeHeroImage(maxWidth: min(280, w - 64))
                    .padding(.bottom, 48)

                Spacer(minLength: 0)

                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        currentStep = 1
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Drop In")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(WelcomeCanvasColors.deepOcean)
                    .clipShape(Capsule())
                    .shadow(color: WelcomeCanvasColors.deepOcean.opacity(0.35), radius: 10, x: 0, y: 8)
                }
                .buttonStyle(WelcomePrimaryButtonStyle())

                Text("Coastal bites & beach vibes.\nRanked by the ones who know.")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(WelcomeCanvasColors.deepOcean)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 32)
            .padding(.top, 80)
            .padding(.bottom, max(geo.safeAreaInsets.bottom, 10) + 24)
        }
        .ignoresSafeArea()
    }

    /// Full-window welcome canvas behind the paged `TabView` (see `body`); avoids cream + system scroll view peeking at top/bottom.
    private var welcomeScreenBackgroundFill: some View {
        let s = onboardingKeyWindowSize()
        return welcomeCanvasBackground(height: s.height, width: s.width)
            .frame(width: s.width, height: s.height)
            .ignoresSafeArea()
    }

    /// Community (`testimonials`) — bright-sky behind page (matches hero flush top; avoids sand “stripe”).
    private var communityScreenBackgroundFill: some View {
        let s = onboardingKeyWindowSize()
        return WelcomeCanvasColors.brightSky
            .frame(width: s.width, height: s.height)
            .ignoresSafeArea()
    }

    /// Select Tastes (`cravings`) — sand + soft gradient orbs behind TabView.
    private var tastesScreenBackgroundFill: some View {
        let s = onboardingKeyWindowSize()
        return ZStack {
            WelcomeCanvasColors.sandGray
            Circle()
                .fill(WelcomeCanvasColors.brightSky.opacity(0.2))
                .frame(width: 256, height: 256)
                .blur(radius: 80)
                .offset(x: s.width * 0.22, y: -s.height * 0.12)
            Circle()
                .fill(WelcomeCanvasColors.paleSky.opacity(0.4))
                .frame(width: 256, height: 256)
                .blur(radius: 80)
                .offset(x: -s.width * 0.22, y: s.height * 0.18)
        }
        .frame(width: s.width, height: s.height)
        .ignoresSafeArea()
    }

    /// Sign Up (`signup`) — bright-sky + palm dot pattern + pale orb behind TabView.
    private var signupScreenBackgroundFill: some View {
        let s = onboardingKeyWindowSize()
        return SignupCanvasBackgroundView(width: s.width, height: s.height)
            .frame(width: s.width, height: s.height)
            .ignoresSafeArea()
    }

    private func welcomeCanvasBackground(height h: CGFloat, width w: CGFloat) -> some View {
        ZStack {
            VStack(spacing: 0) {
                WelcomeCanvasColors.paleSky
                    .frame(height: h * 0.5)
                ZStack {
                    WelcomeCanvasColors.sandGray
                    RadialGradient(
                        colors: [WelcomeCanvasColors.brightSky, Color.clear],
                        center: UnitPoint(x: 0.5, y: 1.05),
                        startRadius: 0,
                        endRadius: max(w, h) * 0.85
                    )
                    .opacity(0.6)
                }
                .frame(height: h * 0.5)
            }

            VStack {
                Spacer(minLength: 0)
                LinearGradient(
                    colors: [WelcomeCanvasColors.deepOcean.opacity(0.2), Color.clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: h * 0.6)
            }
            .allowsHitTesting(false)
        }
    }

    private var welcomeLogoMark: some View {
        WelcomeLogoBounceWrapper {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                Circle()
                    .fill(Color.white.opacity(0.22))
                BrandPalmIcon(size: 60, color: WelcomeCanvasColors.ink)
            }
            .frame(width: 128, height: 128)
            .shadow(color: WelcomeCanvasColors.deepOcean.opacity(0.15), radius: 20, x: 0, y: 10)
        }
    }

    private func welcomeHeroImage(maxWidth: CGFloat) -> some View {
        ZStack {
            AsyncImage(url: WelcomeCanvasPreviewURLs.hero) { phase in
                switch phase {
                case .success(let img):
                    img
                        .resizable()
                        .scaledToFill()
                case .failure:
                    WelcomeCanvasColors.sandGray
                case .empty:
                    WelcomeCanvasColors.paleSky.opacity(0.6)
                @unknown default:
                    WelcomeCanvasColors.paleSky.opacity(0.6)
                }
            }
            WelcomeCanvasColors.brightSky
                .blendMode(.overlay)
                .opacity(0.3)
        }
        .frame(width: maxWidth, height: maxWidth)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .stroke(Color.white, lineWidth: 4)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 8)
    }

    private func onboardingKeyWindowSize() -> CGSize {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        if let scene,
           let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first {
            return window.bounds.size
        }
        return UIScreen.main.bounds.size
    }

    // MARK: - Community (MCP canvas “Community”, slug `testimonials` — same palette as Welcome)

    private var communitySocialStep: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let safeTop = geo.safeAreaInsets.top
            let seamLift = min(max(w * 0.095, 30), 52)
            let heroVisualH = h * 0.55
            let heroFrameH = heroVisualH + safeTop
            let sandTopY = heroFrameH - seamLift

            ZStack(alignment: .top) {
                communityHeroBand(seamLift: seamLift)
                .frame(width: w, height: heroFrameH)
                .ignoresSafeArea(edges: .top)
                .zIndex(0)

                VStack(alignment: .center, spacing: 0) {
                    communityCanvasPageIndicator
                        .padding(.bottom, 24)

                    Text("Trust the Locals.")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(WelcomeCanvasColors.ink)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 16)

                    Text("Discover hidden spots and coastal gems rated by the people who surf the breaks and walk the shores.")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(WelcomeCanvasColors.deepOcean.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            currentStep = 2
                        }
                    } label: {
                        Text("Continue")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(WelcomeCanvasColors.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(WelcomeCanvasColors.brightSky)
                            .clipShape(Capsule())
                            .shadow(color: WelcomeCanvasColors.brightSky.opacity(0.45), radius: 10, x: 0, y: 8)
                    }
                    .buttonStyle(WelcomePrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 10) + 28)
                .frame(width: w, height: max(0, h - sandTopY), alignment: .top)
                .background(WelcomeCanvasColors.sandGray)
                .clipShape(CommunitySandPanelTopUSmileClip(dip: seamLift))
                .offset(y: sandTopY)
                .zIndex(1)

                HStack(alignment: .center) {
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            currentStep = 0
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(WelcomeCanvasColors.deepOcean)
                            .frame(width: 48, height: 48)
                            .background(.ultraThinMaterial)
                            .background(Color.white.opacity(0.35))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)

                    Button("Skip") {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            currentStep = 2
                        }
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(WelcomeCanvasColors.deepOcean)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .background(Color.white.opacity(0.35))
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, max(54, safeTop + 12))
                .zIndex(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    private func communityHeroBand(seamLift: CGFloat) -> some View {
        ZStack {
            WelcomeCanvasColors.sandGray
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ZStack {
                WelcomeCanvasColors.brightSky
                AsyncImage(url: CommunityCanvasPreviewURLs.heroBeachDrinks) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        WelcomeCanvasColors.brightSky.opacity(0.6)
                    case .empty:
                        WelcomeCanvasColors.brightSky.opacity(0.45)
                    @unknown default:
                        WelcomeCanvasColors.brightSky.opacity(0.45)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .blendMode(.multiply)
                .opacity(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .clipShape(CommunityHeroBottomUSmileClip(cornerLift: seamLift))

            VStack {
                Spacer(minLength: 0)
                HStack {
                    Spacer(minLength: 0)
                    communityTestimonialFloatingCard
                        .offset(y: -32)
                }
                .padding(.trailing, 32)
                .padding(.bottom, 100)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var communityCanvasPageIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(WelcomeCanvasColors.paleSky)
                .frame(width: 8, height: 8)
            Capsule()
                .fill(WelcomeCanvasColors.deepOcean)
                .frame(width: 32, height: 8)
            Circle()
                .fill(WelcomeCanvasColors.paleSky)
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
    }

    private var communityTestimonialFloatingCard: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: CommunityCanvasPreviewURLs.avatarQuote) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        WelcomeCanvasColors.paleSky
                    case .empty:
                        WelcomeCanvasColors.paleSky.opacity(0.5)
                    @unknown default:
                        WelcomeCanvasColors.paleSky.opacity(0.5)
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))

                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 32, height: 32)
                    .background(WelcomeCanvasColors.deepOcean)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
                    .offset(x: -12, y: -12)
            }
            .frame(width: 48, height: 48, alignment: .topLeading)

            Text("\"Best palomas in La Jolla hands down.\"")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(WelcomeCanvasColors.ink)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: 200, alignment: .leading)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(WelcomeCanvasColors.paleSky, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 8)
    }

    // MARK: - Select tastes (MCP “Select Tastes”, slug `cravings`)

    private var vibeTastesStep: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            ZStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                currentStep = 1
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(WelcomeCanvasColors.deepOcean)
                                .frame(width: 48, height: 48)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)

                        Text("Step 3 of 3")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(WelcomeCanvasColors.deepOcean)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, max(60, safeTop + 24))
                    .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("What's your")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(WelcomeCanvasColors.ink)
                        Text("coastal vibe?")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(WelcomeCanvasColors.ink)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    Text("Pick your go-to cravings.")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(WelcomeCanvasColors.deepOcean.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 132), spacing: 12)],
                            alignment: .leading,
                            spacing: 12
                        ) {
                            ForEach(cravingsCanvasPills) { pill in
                                CravingsPillButton(
                                    label: pill.label,
                                    isSelected: selectedTastes.contains(pill.id)
                                ) {
                                    if selectedTastes.contains(pill.id) {
                                        selectedTastes.remove(pill.id)
                                    } else {
                                        selectedTastes.insert(pill.id)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 160)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                VStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            currentStep = 3
                        }
                    } label: {
                        Text("Catch the Wave")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(WelcomeCanvasColors.ink)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(WelcomePrimaryButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, max(40, geo.safeAreaInsets.bottom + 28))
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            WelcomeCanvasColors.sandGray.opacity(0),
                            WelcomeCanvasColors.sandGray.opacity(0.88),
                            WelcomeCanvasColors.sandGray
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .zIndex(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    // MARK: - Sign up (`signup` canvas — Join the lineup)

    private var dropAnchorSignUpStep: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom
            ZStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                currentStep = 2
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(SignupCanvasPalette.deepOcean)
                                .frame(width: 48, height: 48)
                                .background(.ultraThinMaterial)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, max(60, safeTop + 24))

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 20)
                        SignupSheetGrabHandle()
                            .padding(.bottom, 28)

                        Text("Join the lineup")
                            .font(DropAnchorTypography.joinLineupTitle)
                            .foregroundStyle(SignupCanvasPalette.ink)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)

                        Text("Create your profile to save and rank your favorite spots.")
                            .font(DropAnchorTypography.bodyMedium(17))
                            .foregroundStyle(SignupCanvasPalette.deepOcean)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 32)

                        SignUpAuthProviderButtons(
                            onApple: { session.showInfo("Sign in with Apple — coming soon") },
                            onGoogle: { session.showInfo("Sign in with Google — coming soon") },
                            onEmail: { showProfileSetup = true }
                        )

                        SignupTermsPrivacyFooterBar(
                            onTerms: { openSignupPolicyLink(AppLinks.termsOfService) },
                            onPrivacy: { openSignupPolicyLink(AppLinks.privacyPolicy) }
                        )
                        .padding(.top, 32)
                        .padding(.bottom, 16)

                        #if DEBUG
                        VStack(spacing: Spacing.sm) {
                            Text("Local testing")
                                .font(.captionCopy)
                                .foregroundStyle(SignupCanvasPalette.deepOcean.opacity(0.55))
                            Button {
                                Task {
                                    #if DEBUG
                                    hasCompletedVerifyLocalFlow = true
                                    let ok = await session.devStressLogin()
                                    if ok {
                                        isPresented = false
                                    } else {
                                        hasCompletedVerifyLocalFlow = false
                                    }
                                    #endif
                                }
                            } label: {
                                Text("Dev login (first DB user)")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.coastalAqua)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(WelcomePrimaryButtonStyle())
                        }
                        .padding(.bottom, 8)
                        #endif
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, max(48, safeBottom + 28))
                    .frame(maxWidth: .infinity)
                    .background(SignupCanvasPalette.sandGray)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 40,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 40
                        )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 28, x: 0, y: -12)

                    DropAnchorPalmCheckBadge()
                        .frame(maxWidth: .infinity)
                        .offset(y: -52)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }

    private func openSignupPolicyLink(_ url: URL?) {
        guard let url else {
            session.showInfo("Link coming soon.")
            return
        }
        UIApplication.shared.open(url)
    }

}

private struct CravingsCanvasPill: Identifiable, Hashable {
    let id: String
    let label: String
}

private struct CravingsPillButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : WelcomeCanvasColors.deepOcean)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? WelcomeCanvasColors.deepOcean : Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isSelected ? WelcomeCanvasColors.deepOcean : WelcomeCanvasColors.paleSky,
                        lineWidth: 2
                    )
                )
                .shadow(color: isSelected ? Color.black.opacity(0.12) : Color.clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(WelcomePrimaryButtonStyle())
    }
}

// MARK: - Welcome canvas (`localsonly-home`) — colors + hero from `get_canvas` HTML

private enum WelcomeCanvasColors {
    static let paleSky = Color(hex: 0xC9DEEE)
    static let brightSky = Color(hex: 0x7CB9CD)
    static let deepOcean = Color(hex: 0x244F70)
    static let sandGray = Color(hex: 0xEFEFEF)
    static let ink = Color(hex: 0x1A1A1A)
}

private enum WelcomeCanvasPreviewURLs {
    static let hero = URL(string: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80")!
}

private struct WelcomeLogoBounceWrapper<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var lift = false

    var body: some View {
        content()
            .offset(y: lift ? -8 : 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    lift = true
                }
            }
    }
}

private struct WelcomePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Community canvas (`testimonials`) — assets from `get_canvas` HTML

private enum CommunityCanvasPreviewURLs {
    static let heroBeachDrinks = URL(string: "https://images.unsplash.com/photo-1687394431847-b973e817ffd4?fm=jpg&q=60&w=3000&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YmVhY2glMjBkcmlua3xlbnwwfHwwfHx8MA%3D%3D")!
    static let avatarQuote = URL(string: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80")!
}

/// Hero bottom seam: ∪ shape (corners lift, center dips) like AIDesigner `clip-curve` / ellipse-at-top feel.
private struct CommunityHeroBottomUSmileClip: Shape {
    var cornerLift: CGFloat

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let lift = min(max(cornerLift, 8), h * 0.48)
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: w, y: 0))
        p.addLine(to: CGPoint(x: w, y: h - lift))
        p.addQuadCurve(to: CGPoint(x: 0, y: h - lift), control: CGPoint(x: w * 0.5, y: h))
        p.closeSubpath()
        return p
    }

    var animatableData: CGFloat {
        get { cornerLift }
        set { cornerLift = newValue }
    }
}

/// Top edge of the sand panel: ∪ (center dips) so the white block matches the hero seam; clipped pixels reveal the hero below.
private struct CommunitySandPanelTopUSmileClip: Shape {
    var dip: CGFloat

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let H = rect.height
        let d = min(max(dip, 4), min(w * 0.35, H * 0.25))
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addQuadCurve(to: CGPoint(x: w, y: 0), control: CGPoint(x: w * 0.5, y: d))
        p.addLine(to: CGPoint(x: w, y: H))
        p.addLine(to: CGPoint(x: 0, y: H))
        p.closeSubpath()
        return p
    }

    var animatableData: CGFloat {
        get { dip }
        set { dip = newValue }
    }
}

#if DEBUG
#Preview {
    OnboardingScreen(isPresented: .constant(true))
        .environmentObject(SessionManager())
}
#endif
