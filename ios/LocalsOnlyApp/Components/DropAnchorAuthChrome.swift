import SwiftUI

// MARK: - Signup canvas (`signup` — MCP `get_canvas` HTML: bright-sky + palm dots, sand bottom sheet, Join the lineup)

/// Tailwind tokens from AIDesigner `signup` HTML (matches Welcome canvas hex).
enum SignupCanvasPalette {
    static let paleSky = Color(hex: 0xC9DEEE)
    static let brightSky = Color(hex: 0x7CB9CD)
    static let deepOcean = Color(hex: 0x244F70)
    static let sandGray = Color(hex: 0xEFEFEF)
    static let ink = Color(hex: 0x1A1A1A)
}

struct SignupCanvasBackgroundView: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            SignupCanvasPalette.brightSky
            SignupPalmDotPatternLayer()
                .opacity(0.4)
            Circle()
                .fill(SignupCanvasPalette.paleSky)
                .frame(width: 384, height: 384)
                .blur(radius: 60)
                .offset(x: -width * 0.25, y: -height * 0.28)
                .opacity(0.8)
                .allowsHitTesting(false)
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

private struct SignupPalmDotPatternLayer: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 20
            let r: CGFloat = 2
            var y: CGFloat = 0
            while y < size.height + step {
                var x: CGFloat = 0
                while x < size.width + step {
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(SignupCanvasPalette.paleSky))
                    x += step
                }
                y += step
            }
        }
        .allowsHitTesting(false)
    }
}

/// Full-bleed bright-sky signup canvas behind content (onboarding + signed-out gateway).
struct DropAnchorDecorBackground: View {
    var body: some View {
        GeometryReader { geo in
            SignupCanvasBackgroundView(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }
}

struct SignupSheetGrabHandle: View {
    var body: some View {
        Capsule()
            .fill(SignupCanvasPalette.paleSky)
            .frame(width: 64, height: 6)
    }
}

/// Palm + check badge from `signup` HTML (`w-20` circle `deep-ocean`, check on `bright-sky`).
struct DropAnchorPalmCheckBadge: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(SignupCanvasPalette.deepOcean)
                .frame(width: 80, height: 80)
                .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 8)
                .overlay(
                    Circle()
                        .stroke(SignupCanvasPalette.sandGray, lineWidth: 4)
                )

            BrandPalmIcon(size: 36, color: .white)
        }
        .frame(width: 80, height: 80)
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(SignupCanvasPalette.brightSky)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(SignupCanvasPalette.sandGray, lineWidth: 2)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                )
                .offset(x: 6, y: 6)
        }
    }
}

struct SignupAuthButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct DropAnchorCapsuleButton<L: View>: View {
    let title: String
    let foreground: Color
    let background: Color
    let border: Color?
    let usesElevatedShadow: Bool
    let icon: () -> L
    let action: () -> Void

    init(
        title: String,
        foreground: Color,
        background: Color,
        border: Color?,
        usesElevatedShadow: Bool = false,
        @ViewBuilder icon: @escaping () -> L,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.foreground = foreground
        self.background = background
        self.border = border
        self.usesElevatedShadow = usesElevatedShadow
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                HStack(spacing: 12) {
                    icon()
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(foreground)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(background)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(border ?? Color.clear, lineWidth: border == nil ? 0 : 1)
            )
            .shadow(
                color: Color.black.opacity(usesElevatedShadow ? 0.2 : 0.06),
                radius: usesElevatedShadow ? 14 : 4,
                x: 0,
                y: usesElevatedShadow ? 8 : 2
            )
        }
        .buttonStyle(SignupAuthButtonPressStyle())
    }
}

/// Shared typography for signup-adjacent screens (SF Rounded ≈ Fredoka/Outfit).
enum DropAnchorTypography {
    static func titleBlack(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func titleBold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func bodyMedium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    /// `signup` canvas H2: `text-3xl font-bold` display.
    static var joinLineupTitle: Font {
        .system(size: 30, weight: .bold, design: .rounded)
    }
}

/// Tappable footer matching `signup` legal row (uses `AppLinks` when set).
struct SignupTermsPrivacyFooterBar: View {
    var onTerms: () -> Void
    var onPrivacy: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            legalHStack
            legalVStack
        }
        .multilineTextAlignment(.center)
    }

    private var legalHStack: some View {
        HStack(spacing: 0) {
            Text("By continuing, you agree to our ")
            linkButton("Terms", action: onTerms)
            Text(" & ")
            linkButton("Privacy", action: onPrivacy)
            Text(".")
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .foregroundStyle(SignupCanvasPalette.deepOcean.opacity(0.6))
    }

    private var legalVStack: some View {
        VStack(spacing: 4) {
            Text("By continuing, you agree to our")
            HStack(spacing: 4) {
                linkButton("Terms", action: onTerms)
                Text("&")
                linkButton("Privacy", action: onPrivacy)
                Text(".")
            }
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .foregroundStyle(SignupCanvasPalette.deepOcean.opacity(0.6))
    }

    private func linkButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .underline()
                .foregroundStyle(SignupCanvasPalette.deepOcean.opacity(0.75))
        }
        .buttonStyle(.plain)
    }
}

struct SignUpAuthProviderButtons: View {
    var onApple: () -> Void
    var onGoogle: () -> Void
    var onEmail: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            DropAnchorCapsuleButton(
                title: "Continue with Apple",
                foreground: SignupCanvasPalette.ink,
                background: Color.white,
                border: SignupCanvasPalette.paleSky,
                usesElevatedShadow: false,
                icon: {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 22))
                        .foregroundStyle(SignupCanvasPalette.ink)
                },
                action: onApple
            )

            DropAnchorCapsuleButton(
                title: "Continue with Google",
                foreground: SignupCanvasPalette.ink,
                background: Color.white,
                border: SignupCanvasPalette.paleSky,
                usesElevatedShadow: false,
                icon: {
                    googleMark
                },
                action: onGoogle
            )

            DropAnchorCapsuleButton(
                title: "Sign up with Email",
                foreground: Color.white,
                background: SignupCanvasPalette.deepOcean,
                border: nil,
                usesElevatedShadow: true,
                icon: {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(SignupCanvasPalette.brightSky)
                },
                action: onEmail
            )
        }
    }

    @ViewBuilder
    private var googleMark: some View {
        if let url = URL(string: "https://cdn.iconscout.com/icon/free/png-256/google-1772223-1507811.png") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    googleFallbackMark
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                case .failure:
                    googleFallbackMark
                @unknown default:
                    googleFallbackMark
                }
            }
        } else {
            googleFallbackMark
        }
    }

    private var googleFallbackMark: some View {
        Text("G")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(SignupCanvasPalette.ink)
    }
}
