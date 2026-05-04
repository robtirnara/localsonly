import SwiftUI

enum AuthStep: CaseIterable {
    case welcome
    case phone
    case otp
    case displayName
    case inviteCode
}

struct AuthScreen: View {
    @EnvironmentObject private var session: SessionManager

    @State private var step: AuthStep = .welcome
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: Spacing.xl)

            stepContent
                .frame(maxWidth: .infinity)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )

            Spacer()

            if step != .welcome {
                stepIndicator
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xl)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
    }

    private var stepIndicator: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Array(AuthStep.allCases.dropFirst()), id: \.self) { s in
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
        case .welcome:
            welcomeStep
        case .phone:
            phoneStep
        case .otp:
            otpStep
        case .displayName:
            displayNameStep
        case .inviteCode:
            inviteCodeStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xs) {
                BrandLockupView(compact: false)

                Text("locals contribute. tourists browse.")
                    .font(.bodyCopy)
                    .foregroundStyle(Color.coastalSand)
                    .multilineTextAlignment(.center)
            }

            GlassCard {
                VStack(spacing: Spacing.md) {
                    Text("Find the real local spots and add your own takes.")
                        .font(.bodyCopy)
                        .foregroundStyle(Color.coastalTextSecondary)
                        .multilineTextAlignment(.center)

                    PrimaryButton(title: "get started") {
                        goTo(.phone)
                    }
                }
            }
        }
    }

    private var phoneStep: some View {
        VStack(spacing: Spacing.md) {
            Text("what's your number?")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)

            GlassCard {
                VStack(spacing: Spacing.md) {
                    TextField("+1 555 123 4567", text: $session.phoneE164)
                        .foregroundStyle(Color.coastalTextPrimary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .padding()
                        .background(Color.coastalCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    PrimaryButton(title: "send code", isLoading: isLoading) {
                        Task {
                            isLoading = true
                            let ok = await session.sendCode()
                            isLoading = false
                            if ok { goTo(.otp) }
                        }
                    }

                    SecondaryButton(title: "back") {
                        goTo(.welcome)
                    }
                }
            }
        }
    }

    private var otpStep: some View {
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

                    PrimaryButton(title: "next") {
                        let code = session.otpCode.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !code.isEmpty else {
                            session.showError("Enter the verification code")
                            return
                        }
                        goTo(.displayName)
                    }

                    SecondaryButton(title: "back") {
                        goTo(.phone)
                    }
                }
            }
        }
    }

    private var displayNameStep: some View {
        VStack(spacing: Spacing.md) {
            Text("what should we call you?")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)

            GlassCard {
                VStack(spacing: Spacing.md) {
                    TextField("your name", text: $session.displayName)
                        .foregroundStyle(Color.coastalTextPrimary)
                        .padding()
                        .background(Color.coastalCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    PrimaryButton(title: "continue") {
                        guard !session.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            session.showError("Enter a display name")
                            return
                        }
                        goTo(.inviteCode)
                    }

                    SecondaryButton(title: "back") {
                        goTo(.otp)
                    }
                }
            }
        }
    }

    private var inviteCodeStep: some View {
        VStack(spacing: Spacing.md) {
            Text("got an invite code?")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)

            Text("optional. test code: LOCALS2026")
                .font(.captionCopy)
                .foregroundStyle(Color.coastalTextSecondary)

            GlassCard {
                VStack(spacing: Spacing.md) {
                    TextField("invite code", text: $session.inviteCode)
                        .foregroundStyle(Color.coastalTextPrimary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.coastalCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    PrimaryButton(title: "join localsonly", isLoading: isLoading) {
                        Task {
                            isLoading = true
                            _ = await session.verifyAndJoin()
                            isLoading = false
                        }
                    }

                    SecondaryButton(title: "skip invite code") {
                        session.inviteCode = ""
                        Task {
                            isLoading = true
                            _ = await session.verifyAndJoin()
                            isLoading = false
                        }
                    }
                }
            }
        }
    }

    private func goTo(_ nextStep: AuthStep) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            step = nextStep
        }
    }
}
