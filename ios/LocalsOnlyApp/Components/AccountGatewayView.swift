import SwiftUI

/// Signed-out auth shell matching MCP `signup` canvas (same chrome as onboarding step 4).

enum AccountGatewayMode {
    case signUp
    case logIn
}

struct AccountGatewayView: View {
    @EnvironmentObject private var session: SessionManager

    @Binding var mode: AccountGatewayMode
    @Binding var phoneE164: String

    var onSignUp: () -> Void
    var onSendCode: () -> Void
    var onAppleSSO: () -> Void
    var onGoogleSSO: () -> Void

    var body: some View {
        ZStack {
            DropAnchorDecorBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    if mode == .signUp {
                        signUpBody
                    } else {
                        logInBody
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var signUpBody: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Color.clear.frame(height: 16)
                SignupSheetGrabHandle()
                    .padding(.top, 8)
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
                    onApple: onAppleSSO,
                    onGoogle: onGoogleSSO,
                    onEmail: onSignUp
                )

                SignupTermsPrivacyFooterBar(
                    onTerms: { openSignupPolicyLink(AppLinks.termsOfService) },
                    onPrivacy: { openSignupPolicyLink(AppLinks.privacyPolicy) }
                )
                .padding(.top, 32)
                .padding(.bottom, 8)

                Button {
                    mode = .logIn
                } label: {
                    gatewayFooterPrompt(
                        plain: "Already signed up? ",
                        bold: "Log in"
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 24)
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(SignupCanvasPalette.sandGray)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 40,
                    bottomLeadingRadius: 40,
                    bottomTrailingRadius: 40,
                    topTrailingRadius: 40
                )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)

            DropAnchorPalmCheckBadge()
                .frame(maxWidth: .infinity)
                .offset(y: -44)
        }
        .padding(.top, 8)
    }

    private var logInBody: some View {
        VStack(spacing: 0) {
            Text("Welcome back")
                .font(DropAnchorTypography.titleBlack(36))
                .foregroundStyle(SignupCanvasPalette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text("Sign in with SSO, or use local phone login while we ship native SSO.")
                .font(DropAnchorTypography.bodyMedium(17))
                .foregroundStyle(SignupCanvasPalette.deepOcean.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)

            VStack(spacing: 16) {
                DropAnchorCapsuleButton(
                    title: "Continue with Apple",
                    foreground: SignupCanvasPalette.ink,
                    background: Color.white,
                    border: SignupCanvasPalette.paleSky,
                    icon: { Image(systemName: "apple.logo").font(.system(size: 22)).foregroundStyle(SignupCanvasPalette.ink) },
                    action: onAppleSSO
                )

                DropAnchorCapsuleButton(
                    title: "Continue with Google",
                    foreground: SignupCanvasPalette.ink,
                    background: Color.white,
                    border: SignupCanvasPalette.paleSky,
                    icon: {
                        googleGatewayMark
                    },
                    action: onGoogleSSO
                )
            }

            orDivider
                .padding(.vertical, 24)

            Text("Local login")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SignupCanvasPalette.deepOcean.opacity(0.65))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

            TextField("+1 555 123 4567", text: $phoneE164)
                .foregroundStyle(SignupCanvasPalette.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SignupCanvasPalette.paleSky.opacity(0.9), lineWidth: 1)
                )

            coralSendCodeButton(title: "Send code", action: onSendCode)
                .padding(.top, 16)

            Button {
                mode = .signUp
            } label: {
                gatewayFooterPrompt(
                    plain: "Need an account? ",
                    bold: "Sign up"
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 32)
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 12)
        .background(SignupCanvasPalette.sandGray)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 40,
                bottomLeadingRadius: 40,
                bottomTrailingRadius: 40,
                topTrailingRadius: 40
            )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)
        .padding(.top, 8)
    }

    private var orDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(SignupCanvasPalette.deepOcean.opacity(0.12))
                .frame(height: 1)
            Text("or")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SignupCanvasPalette.deepOcean.opacity(0.45))
            Rectangle()
                .fill(SignupCanvasPalette.deepOcean.opacity(0.12))
                .frame(height: 1)
        }
    }

    private func coralSendCodeButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.coastalCoral)
                .clipShape(Capsule())
                .shadow(color: Color.coastalCoral.opacity(0.28), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(SignupAuthButtonPressStyle())
    }

    private func gatewayFooterPrompt(plain: String, bold: String) -> some View {
        (Text(plain)
            .font(DropAnchorTypography.bodyMedium(16))
            .foregroundStyle(SignupCanvasPalette.deepOcean.opacity(0.65))
        + Text(bold)
            .font(DropAnchorTypography.bodyMedium(16))
            .fontWeight(.bold)
            .foregroundStyle(Color.coastalCoral))
            .multilineTextAlignment(.center)
    }

    private func openSignupPolicyLink(_ url: URL?) {
        guard let url else {
            session.showInfo("Link coming soon.")
            return
        }
        UIApplication.shared.open(url)
    }

    @ViewBuilder
    private var googleGatewayMark: some View {
        if let url = URL(string: "https://cdn.iconscout.com/icon/free/png-256/google-1772223-1507811.png") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    googleGatewayFallback
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                case .failure:
                    googleGatewayFallback
                @unknown default:
                    googleGatewayFallback
                }
            }
        } else {
            googleGatewayFallback
        }
    }

    private var googleGatewayFallback: some View {
        Text("G")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(SignupCanvasPalette.ink)
    }
}

#if DEBUG
#Preview {
    PreviewAccountGateway()
}

private struct PreviewAccountGateway: View {
    @State private var mode = AccountGatewayMode.signUp
    @State private var phone = ""

    var body: some View {
        AccountGatewayView(
            mode: $mode,
            phoneE164: $phone,
            onSignUp: {},
            onSendCode: {},
            onAppleSSO: {},
            onGoogleSSO: {}
        )
        .environmentObject(SessionManager())
    }
}
#endif
