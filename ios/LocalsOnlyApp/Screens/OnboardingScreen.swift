import SwiftUI

// Ported from AIDesigner MCP run `9142eb77-a1c4-4155-9828-b451b714b6ac` (mobile onboarding:
// Community → Select tastes → Sign up). Visual tokens: cream #FFF6ED, card #FFFCF9, coral #F97316,
// aqua #0EA5E9, ink #0F172A, steel #6B7280.

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
        ("outdoors", "Outdoors", "tree.fill")
    ]

    var body: some View {
        ZStack {
            Color.coastalBackground.ignoresSafeArea()

            TabView(selection: $currentStep) {
                communityStep.tag(0)
                tastesStep.tag(1)
                signUpStep.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    // MARK: - Step 1: Community

    private var communityStep: some View {
        GeometryReader { geo in
            let heroHeight = geo.size.height * 0.55
            VStack(spacing: 0) {
                communityHero
                    .frame(height: heroHeight)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Join your\ncommunity.")
                            .font(.system(size: 34, weight: .bold, design: .default))
                            .foregroundStyle(Color.coastalTextPrimary)
                            .tracking(-0.5)
                            .lineSpacing(2)

                        Text("Discover the hidden spaces and local secrets your neighbors already love.")
                            .font(.system(size: 17, weight: .medium, design: .default))
                            .foregroundStyle(Color.coastalTextSecondary)
                            .lineSpacing(4)
                            .frame(maxWidth: 280, alignment: .leading)
                    }
                    .padding(.top, Spacing.xl)

                    Spacer(minLength: Spacing.lg)

                    VStack(spacing: Spacing.lg) {
                        OnboardingStepDots(activeIndex: 0)
                        coralContinueButton(title: "Continue") {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                currentStep = 1
                            }
                        }
                    }
                    .padding(.bottom, Spacing.xl)
                }
                .padding(.horizontal, Spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var communityHero: some View {
        ZStack {
            Color.coastalBackground

            CommunityHeroIllustration()
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xl)
        }
        .clipShape(OnboardingBottomRoundedShape(radius: 48))
    }

    // MARK: - Step 2: Tastes

    private var tastesStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    currentStep = 0
                }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.coastalTextPrimary.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background(Color.coastalCard)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.coastalInk.opacity(0.05), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.bottom, Spacing.md)

            Text("What are\nyou into?")
                .font(.system(size: 38, weight: .bold, design: .default))
                .foregroundStyle(Color.coastalTextPrimary)
                .tracking(-0.8)
                .lineSpacing(0)

            Text("Select a few to tune your feed.")
                .font(.system(size: 17, weight: .medium, design: .default))
                .foregroundStyle(Color.coastalTextSecondary)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xl)

            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.sm),
                        GridItem(.flexible(), spacing: Spacing.sm)
                    ],
                    spacing: Spacing.sm
                ) {
                    ForEach(tasteOptions, id: \.id) { item in
                        TastePillCard(
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
                OnboardingStepDots(activeIndex: 1)
                inkContinueButton(title: "Continue") {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        currentStep = 2
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

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.coastalCoral)
                            .frame(width: 32, height: 32)
                        Image(systemName: "mappin")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text("localsonly")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundStyle(Color.coastalTextPrimary)
                        .tracking(-0.3)
                }
                .padding(.bottom, Spacing.xl)

                Text("Create your\naccount")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundStyle(Color.coastalTextPrimary)
                    .tracking(-0.5)

                Text("You're one step away from the inside scoop.")
                    .font(.system(size: 17, weight: .medium, design: .default))
                    .foregroundStyle(Color.coastalTextSecondary)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.xl)

                VStack(spacing: Spacing.md) {
                    HStack(spacing: 0) {
                        Image(systemName: "envelope")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.coastalTextSecondary.opacity(0.7))
                            .frame(width: 52, alignment: .center)

                        TextField("name@email.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundStyle(Color.coastalTextPrimary)
                    }
                    .padding(.vertical, Spacing.md)
                    .background(Color.coastalBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.coastalInk.opacity(0.05), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)

                    coralContinueButton(title: "Sign up", icon: "paperplane.fill") {
                        finishOnboarding()
                    }
                    .padding(.top, Spacing.xs)
                }

                Spacer(minLength: Spacing.md)

                VStack(spacing: Spacing.lg) {
                    OnboardingStepDots(activeIndex: 2)
                    Button {
                        finishOnboarding()
                    } label: {
                        Text(attributedLogInLine)
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Spacing.lg)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xxl + 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                Color.coastalCard
                    .clipShape(OnboardingTopRoundedShape(radius: 48))
                    .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: -12)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private var attributedLogInLine: AttributedString {
        var base = AttributedString("Already have an account? ")
        base.foregroundColor = Color.coastalTextSecondary
        base.font = .system(size: 15, weight: .medium)
        var bold = AttributedString("Log in")
        bold.foregroundColor = Color.coastalTextPrimary
        bold.font = .system(size: 15, weight: .bold)
        return base + bold
    }

    private func finishOnboarding() {
        isPresented = false
    }

    // MARK: - Buttons (match artifact: coral vs ink CTAs)

    private func coralContinueButton(title: String, icon: String? = "arrow.right", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .offset(y: 1)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md + 2)
            .background(Color.coastalCoral)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.coastalCoral.opacity(0.35), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func inkContinueButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md + 2)
                .background(Color.coastalInk)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step dots

private struct OnboardingStepDots: View {
    let activeIndex: Int
    private let count = 3

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { i in
                if i == activeIndex {
                    Capsule()
                        .fill(Color.coastalInk)
                        .frame(width: 32, height: 8)
                } else {
                    Circle()
                        .fill(Color.coastalInk.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

// MARK: - Community illustration (abstract coastal / community motif from artifact)

private struct CommunityHeroIllustration: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.coastalCoral.opacity(0.2))
                .frame(width: 220, height: 220)
                .blur(radius: 45)
                .offset(x: 70, y: -90)

            Circle()
                .fill(Color.coastalAqua.opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .offset(x: -80, y: 60)

            ZStack {
                Circle()
                    .fill(Color.coastalCoral.opacity(0.12))
                    .frame(width: 280, height: 280)
                Circle()
                    .fill(Color.coastalCoral.opacity(0.9))
                    .frame(width: 200, height: 200)

                CommunityWave()
                    .fill(Color.coastalAqua.opacity(0.9))
                    .frame(width: 320, height: 120)
                    .offset(y: 55)

                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.coastalCard)
                    .frame(width: 40, height: 90)
                    .offset(x: -55, y: -15)

                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.coastalCard)
                    .frame(width: 50, height: 120)
                    .offset(x: 5, y: -28)

                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.coastalCard)
                    .frame(width: 36, height: 70)
                    .offset(x: 65, y: 5)

                Circle().fill(Color.coastalInk).frame(width: 28, height: 28).offset(x: -55, y: -78)
                Circle().fill(Color.coastalInk).frame(width: 36, height: 36).offset(x: 5, y: -98)
                Circle().fill(Color.coastalInk).frame(width: 24, height: 24).offset(x: 68, y: -62)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }
}

private struct CommunityWave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h * 0.35))
        path.addCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.35),
            control1: CGPoint(x: w * 0.08, y: h * 0.05),
            control2: CGPoint(x: w * 0.22, y: h * 0.55)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.72, y: h * 0.42),
            control1: CGPoint(x: w * 0.48, y: h * 0.15),
            control2: CGPoint(x: w * 0.58, y: h * 0.62)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.48),
            control1: CGPoint(x: w * 0.82, y: h * 0.22),
            control2: CGPoint(x: w * 0.95, y: h * 0.42)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Taste pill (bento cards)

private struct TastePillCard: View {
    let title: String
    let symbolName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.coastalAqua : Color.coastalBackground)
                            .frame(width: 40, height: 40)
                        Image(systemName: symbolName)
                            .font(.system(size: 18))
                            .foregroundStyle(isSelected ? Color.white : Color.coastalInk)
                    }

                    Spacer(minLength: 0)

                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.clear : Color.coastalInk.opacity(0.1), lineWidth: 2)
                            .background(
                                Circle().fill(isSelected ? Color.coastalAqua : Color.clear)
                            )
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.coastalAqua : Color.coastalTextPrimary)

                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .background(Color.coastalCard)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isSelected ? Color.coastalAqua.opacity(0.35) : Color.coastalInk.opacity(0.04),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 10)
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
