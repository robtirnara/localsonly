import SwiftUI

// AIDesigner MCP reference: run `bf230560-d5d9-4c90-897c-f533ba00ed82` — four horizontal steps:
// Welcome → Community (photo hero) → Select tastes (square bento) → Sign up (pin hero + sheet card).
// Pagination dots: active segment coral; inactive steel @ 30%. Tokens: cream/card/coral/aqua/ink.

private let onboardingCommunityPhotoURL: URL? = URL(
    string: "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=800"
)

private enum OnboardingSignUpLayout {
    static let heroHeight: CGFloat = 320
}

struct OnboardingScreen: View {
    @Binding var isPresented: Bool

    @State private var currentStep = 0
    @State private var selectedTastes: Set<String> = []
    @State private var email = ""

    private let tasteOptions: [(id: String, title: String, symbol: String)] = [
        ("coffee", "Coffee", "cup.and.saucer.fill"),
        ("food", "Food", "fork.knife"),
        ("drinks", "Drinks", "wineglass.fill"),
        ("bakeries", "Bakeries", "takeoutbag.and.cup.and.straw.fill"),
        ("nightlife", "Nightlife", "moon.stars.fill"),
        ("outdoors", "Outdoors", "mountain.2.fill")
    ]

    var body: some View {
        ZStack {
            Color.coastalBackground.ignoresSafeArea()

            TabView(selection: $currentStep) {
                welcomeStep.tag(0)
                communityStep.tag(1)
                tastesStep.tag(2)
                signUpStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Image(systemName: "scope")
                    .font(.system(size: 220))
                    .foregroundStyle(Color.coastalInk.opacity(0.03))

                VStack(spacing: Spacing.xl) {
                    ZStack {
                        Circle()
                            .stroke(Color.coastalCoral.opacity(0.2), lineWidth: 2)
                            .frame(width: 128, height: 128)
                        Circle()
                            .stroke(Color.coastalCoral.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                            .frame(width: 112, height: 112)

                        VStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.coastalCoral)
                            Image(systemName: "water.waves")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.coastalAqua)
                        }
                    }

                    VStack(spacing: Spacing.md) {
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("localsonly")
                                .font(.system(size: 36, weight: .heavy, design: .default))
                                .foregroundStyle(Color.coastalInk)
                                .textCase(.lowercase)
                            Text(".")
                                .font(.system(size: 36, weight: .heavy, design: .default))
                                .foregroundStyle(Color.coastalCoral)
                        }

                        Text("Ditch the tourist traps. Unearth the spots that actually fuel the city.")
                            .font(.system(size: 17, weight: .medium, design: .default))
                            .foregroundStyle(Color.coastalTextSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .frame(maxWidth: 280)
                    }
                }
            }

            Spacer()

            VStack(spacing: Spacing.lg) {
                OnboardingStepDots(activeIndex: 0, total: 4)
                coralCTAButton(title: "Continue", showArrow: false) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        currentStep = 1
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
    }

    // MARK: - Step 1: Community

    private var communityStep: some View {
        GeometryReader { geo in
            let heroHeight = geo.size.height * 0.55
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Group {
                        if let url = onboardingCommunityPhotoURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case let .success(image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                default:
                                    Color.coastalCard
                                }
                            }
                        } else {
                            Color.coastalCard
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: heroHeight)
                    .clipped()

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: heroHeight)
                    .allowsHitTesting(false)

                    HStack(spacing: Spacing.sm) {
                        Circle()
                            .fill(Color.coastalCoral)
                            .frame(width: 8, height: 8)
                        Text("Live Local")
                            .font(.system(size: 11, weight: .bold, design: .default))
                            .foregroundStyle(Color.coastalInk)
                            .tracking(1.2)
                            .textCase(.uppercase)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(.white.opacity(0.9))
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                    .padding(.leading, Spacing.lg)
                    .padding(.bottom, 40)
                }
                .clipShape(OnboardingBottomRoundedShape(radius: 48))

                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: Spacing.xl)

                    Text("Join your\ncommunity.")
                        .font(.system(size: 30, weight: .bold, design: .default))
                        .foregroundStyle(Color.coastalTextPrimary)
                        .tracking(-0.5)
                        .lineSpacing(2)

                    Text("Connect with neighbors who share your palate. See exactly where the regulars are going tonight.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.coastalTextSecondary)
                        .lineSpacing(5)
                        .padding(.top, Spacing.sm)

                    Spacer()

                    VStack(spacing: Spacing.lg) {
                        OnboardingStepDots(activeIndex: 1, total: 4)
                        coralCTAButton(title: "Continue", showArrow: false) {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                currentStep = 2
                            }
                        }
                    }
                    .padding(.bottom, Spacing.xl)
                }
                .padding(.horizontal, Spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Step 2: Tastes

    private var tastesStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.md) {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        currentStep = 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.coastalTextPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.coastalCard)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                Text("What are you into?")
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .foregroundStyle(Color.coastalTextPrimary)
                    .tracking(-0.4)

                Spacer(minLength: 0)
            }
            .padding(.bottom, Spacing.lg)

            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.md),
                        GridItem(.flexible(), spacing: Spacing.md)
                    ],
                    spacing: Spacing.md
                ) {
                    ForEach(tasteOptions, id: \.id) { item in
                        TasteBentoCard(
                            title: item.title,
                            symbolName: item.symbol,
                            isSelected: selectedTastes.contains(item.id)
                        ) {
                            if selectedTastes.contains(item.id) {
                                selectedTastes.remove(item.id)
                            } else {
                                selectedTastes.insert(item.id)
                            }
                        }
                    }
                }
                .padding(.bottom, Spacing.md)
            }

            Spacer(minLength: Spacing.sm)

            VStack(spacing: Spacing.lg) {
                OnboardingStepDots(activeIndex: 2, total: 4)
                inkContinueButton(title: "Continue") {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        currentStep = 3
                    }
                }
            }
            .padding(.bottom, Spacing.xl)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xxl)
    }

    // MARK: - Step 3: Sign up

    private var signUpStep: some View {
        ZStack(alignment: .top) {
            Color.coastalBackground

            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Color.clear.frame(height: OnboardingSignUpLayout.heroHeight)

                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            currentStep = 2
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.coastalTextPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.coastalCard)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, Spacing.lg)
                    .padding(.top, Spacing.xxl)

                    VStack(spacing: Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(Color.coastalCoral.opacity(0.15))
                                .frame(width: 120, height: 120)
                                .blur(radius: 24)
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(Color.coastalCoral)
                                .symbolRenderingMode(.hierarchical)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("localsonly")
                                .font(.system(size: 24, weight: .heavy, design: .default))
                                .foregroundStyle(Color.coastalInk)
                                .textCase(.lowercase)
                            Text(".")
                                .font(.system(size: 24, weight: .heavy, design: .default))
                                .foregroundStyle(Color.coastalCoral)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 72)
                }
                .frame(height: OnboardingSignUpLayout.heroHeight)

                VStack(alignment: .leading, spacing: 0) {
                        Capsule()
                            .fill(Color.coastalTextSecondary.opacity(0.2))
                            .frame(width: 48, height: 6)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, Spacing.lg)

                        Text("Create your account")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundStyle(Color.coastalTextPrimary)
                            .tracking(-0.4)

                        Text("Join the inner circle. No tourists allowed.")
                            .font(.system(size: 15, weight: .medium, design: .default))
                            .foregroundStyle(Color.coastalTextSecondary)
                            .padding(.top, Spacing.xs)
                            .padding(.bottom, Spacing.lg)

                        ZStack(alignment: .trailing) {
                            TextField("name@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundStyle(Color.coastalTextPrimary)
                                .padding(.vertical, 18)
                                .padding(.leading, 20)
                                .padding(.trailing, 48)
                                .background(Color.coastalBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.coastalTextSecondary.opacity(0.15), lineWidth: 1)
                                )

                            Image(systemName: "envelope")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.coastalTextSecondary.opacity(0.4))
                                .padding(.trailing, 20)
                        }

                        coralCTAButton(title: "Sign up", showArrow: false) {
                            finishOnboarding()
                        }
                        .padding(.top, Spacing.sm)

                        Button {
                            finishOnboarding()
                        } label: {
                            Text(attributedLogInLine)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, Spacing.md)

                        Spacer(minLength: Spacing.sm)

                        OnboardingStepDots(activeIndex: 3, total: 4)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, Spacing.lg)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.coastalCard)
                .clipShape(OnboardingTopRoundedShape(radius: 40))
                .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: -12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var attributedLogInLine: AttributedString {
        var base = AttributedString("Already have an account? ")
        base.foregroundColor = Color.coastalTextSecondary
        base.font = .system(size: 15, weight: .medium)
        var bold = AttributedString("Log in")
        bold.foregroundColor = Color.coastalInk
        bold.font = .system(size: 15, weight: .bold)
        return base + bold
    }

    private func finishOnboarding() {
        isPresented = false
    }

    private func coralCTAButton(title: String, showArrow: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                if showArrow {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.coastalCoral)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.coastalCoral.opacity(0.28), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func inkContinueButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.coastalInk)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step dots (coral active — matches AIDesigner artifact)

private struct OnboardingStepDots: View {
    let activeIndex: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                if i == activeIndex {
                    Capsule()
                        .fill(Color.coastalCoral)
                        .frame(width: 32, height: 6)
                } else {
                    Circle()
                        .fill(Color.coastalTextSecondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}

// MARK: - Bento taste tile (square, aqua selection)

private struct TasteBentoCard: View {
    let title: String
    let symbolName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.coastalAqua : Color.coastalBackground)
                        .frame(width: 48, height: 48)
                    Image(systemName: symbolName)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? Color.white : Color.coastalTextSecondary)
                }

                Spacer(minLength: 0)

                Text(title)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .medium, design: .default))
                    .foregroundStyle(isSelected ? Color.coastalInk : Color.coastalTextSecondary)
            }
            .padding(Spacing.md + 2)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(isSelected ? Color.coastalAqua.opacity(0.08) : Color.coastalCard)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? Color.coastalAqua : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Shapes

private struct OnboardingBottomRoundedShape: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = radius
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - r, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - r),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

private struct OnboardingTopRoundedShape: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = radius
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + r, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + r),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#if DEBUG
#Preview {
    OnboardingScreen(isPresented: .constant(true))
}
#endif
