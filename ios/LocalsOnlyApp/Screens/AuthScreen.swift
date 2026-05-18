import SwiftUI

enum AuthStep: CaseIterable {
    case gateway
    case profileSetup
    case loginOtp
}

struct AuthScreen: View {
    @EnvironmentObject private var session: SessionManager

    @AppStorage("hasCompletedLaunchOnboarding") private var hasCompletedLaunchOnboarding = false

    @State private var step: AuthStep = .gateway
    @State private var gatewayMode: AccountGatewayMode = .signUp
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Group {
                if step == .gateway {
                    Color.clear
                } else if step == .profileSetup {
                    Color(hex: 0xFFF6ED)
                } else {
                    Color.coastalBackground
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )

                if step != .gateway && step != .profileSetup {
                    stepIndicator
                        .padding(.bottom, Spacing.lg)
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
        .onAppear {
            if hasCompletedLaunchOnboarding {
                step = .gateway
            }
        }
        .onChange(of: hasCompletedLaunchOnboarding) { _, completed in
            if completed {
                step = .gateway
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Array(AuthStep.allCases.filter { $0 != .gateway && $0 != .profileSetup }), id: \.self) { s in
                Capsule()
                    .fill(s == step ? Color.coastalAqua : Color.coastalTextSecondary.opacity(0.2))
                    .frame(width: s == step ? 24 : 8, height: 4)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .gateway:
            AccountGatewayView(
                mode: $gatewayMode,
                phoneE164: $session.phoneE164,
                onSignUp: {
                    goTo(.profileSetup)
                },
                onSendCode: {
                    Task {
                        isLoading = true
                        let ok = await session.sendCode()
                        isLoading = false
                        if ok {
                            goTo(.loginOtp)
                        }
                    }
                },
                onAppleSSO: {
                    session.showInfo("Sign in with Apple — coming soon")
                },
                onGoogleSSO: {
                    session.showInfo("Sign in with Google — coming soon")
                }
            )
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }

        case .profileSetup:
            ProfileSetupScreen(
                onDismiss: {
                    goTo(.gateway)
                },
                onProceedToVerifyLocal: {
                    goTo(.gateway)
                }
            )
            .environmentObject(session)

        case .loginOtp:
            loginOtpStep
        }
    }

    private var loginOtpStep: some View {
        VStack(spacing: Spacing.md) {
            Text("enter the code")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)

            Text("we sent a code to \(session.phoneE164)")
                .font(.captionCopy)
                .foregroundStyle(Color.coastalTextSecondary)

            GlassCard {
                VStack(spacing: Spacing.md) {
                    TextField("111111", text: $session.otpCode)
                        .foregroundStyle(Color.coastalTextPrimary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .padding()
                        .background(Color.coastalCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    PrimaryButton(title: "next", isLoading: isLoading) {
                        let code = session.otpCode.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !code.isEmpty else {
                            session.showError("Enter the verification code")
                            return
                        }
                        Task {
                            isLoading = true
                            _ = await session.verifyAndJoin()
                            isLoading = false
                        }
                    }

                    SecondaryButton(title: "back") {
                        goTo(.gateway)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.xl)
    }

    private func goTo(_ nextStep: AuthStep) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            step = nextStep
        }
    }
}
