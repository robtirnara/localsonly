import PhotosUI
import SwiftUI

// MCP canvas `signup-2` / Profile Setup — UUID 1a52a238-e8f4-42a4-85a2-0956baa00f28 (`get_canvas` HTML).

private enum ProfileSetupCanvasColors {
    static let dark = Color(hex: 0x1A1A1A)
    static let sand = Color(hex: 0xFFF6ED)
    static let ocean = Color(hex: 0x7CB9CD)
    static let oceanDark = Color(hex: 0x2A5D84)
    static let oceanLight = Color(hex: 0xC9DEEE)
    static let white = Color.white
}

private struct ProfileSetupJoinButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Profile creation form after **Sign up with Email** (replaces legacy phone / OTP / invite steps).
struct ProfileSetupScreen: View {
    @EnvironmentObject private var session: SessionManager

    var onDismiss: () -> Void
    /// After sign-in (or dev shortcut), parent hides this sheet and presents **Verify Local**.
    var onProceedToVerifyLocal: () -> Void

    @State private var username = ""
    @State private var password = ""
    @State private var birthdayText = ""
    @State private var showPassword = false
    @State private var isSubmitting = false
    @State private var avatarItem: PhotosPickerItem?
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case username, password, birthday
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ProfileSetupCanvasColors.sand
                .ignoresSafeArea()

            waveBackdrop
                .allowsHitTesting(false)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                mainScroll
            }

            bottomBar
        }
    }

    private var waveBackdrop: some View {
        LinearGradient(
            colors: [
                Color.clear,
                ProfileSetupCanvasColors.ocean.opacity(0.05),
                ProfileSetupCanvasColors.ocean.opacity(0.1)
            ],
            startPoint: UnitPoint(x: 0.5, y: 0.3),
            endPoint: .bottom
        )
    }

    private var header: some View {
        HStack {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ProfileSetupCanvasColors.dark)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.6))
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: "tree.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ProfileSetupCanvasColors.dark)
                Text("localsonly")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(ProfileSetupCanvasColors.dark)
            }

            Spacer(minLength: 0)

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    private var mainScroll: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Claim your spot")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(ProfileSetupCanvasColors.dark)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)

                    Text("Let's finish setting up your profile so you can start discovering.")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(ProfileSetupCanvasColors.dark.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.bottom, 40)

                avatarBlock
                    .padding(.bottom, 40)

                VStack(spacing: 16) {
                    labeledField(
                        title: "Choose a Username",
                        showsFocus: focusedField == .username
                    ) {
                        HStack(spacing: 12) {
                            Image(systemName: "at")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(ProfileSetupCanvasColors.oceanDark)
                                .frame(width: 24)
                            TextField("beachbum99", text: $username)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(ProfileSetupCanvasColors.dark)
                                .focused($focusedField, equals: .username)
                        }
                    }

                    labeledField(
                        title: "Set Password",
                        showsFocus: focusedField == .password
                    ) {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(ProfileSetupCanvasColors.oceanDark)
                                .frame(width: 24)
                            Group {
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .focused($focusedField, equals: .password)
                                } else {
                                    SecureField("••••••••", text: $password)
                                        .focused($focusedField, equals: .password)
                                }
                            }
                            .textContentType(.newPassword)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(ProfileSetupCanvasColors.dark)

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(ProfileSetupCanvasColors.dark.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    labeledField(
                        title: "When's your birthday?",
                        showsFocus: focusedField == .birthday
                    ) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(ProfileSetupCanvasColors.oceanDark)
                                .frame(width: 24)
                            TextField("MM / DD / YYYY", text: $birthdayText)
                                .keyboardType(.numbersAndPunctuation)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(ProfileSetupCanvasColors.dark)
                                .focused($focusedField, equals: .birthday)
                        }
                    }

                    Text("Must be 18+ to view some spots & drinks.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(ProfileSetupCanvasColors.dark.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                }
                .padding(.bottom, 160)
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var avatarBlock: some View {
        VStack(spacing: 0) {
            PhotosPicker(selection: $avatarItem, matching: .images) {
                ZStack {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                        .foregroundStyle(ProfileSetupCanvasColors.ocean)
                        .background(
                            Circle()
                                .fill(ProfileSetupCanvasColors.white)
                        )
                        .frame(width: 128, height: 128)
                        .shadow(color: ProfileSetupCanvasColors.oceanDark.opacity(0.08), radius: 12, x: 0, y: 8)

                    SurferShakaSilhouette(color: ProfileSetupCanvasColors.oceanLight, size: 76)
                }
                .frame(width: 128, height: 128)
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(ProfileSetupCanvasColors.dark)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(ProfileSetupCanvasColors.sand, lineWidth: 4)
                        )
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                        )
                        .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private func labeledField<Content: View>(
        title: String,
        showsFocus: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(ProfileSetupCanvasColors.dark)
                .padding(.leading, 10)

            content()
                .frame(height: 56)
                .padding(.horizontal, 20)
                .background(ProfileSetupCanvasColors.white)
                .clipShape(Capsule())
                .shadow(color: ProfileSetupCanvasColors.oceanDark.opacity(0.08), radius: 12, x: 0, y: 8)
                .overlay(
                    Capsule()
                        .stroke(showsFocus ? ProfileSetupCanvasColors.ocean : Color.clear, lineWidth: 2)
                )
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    ProfileSetupCanvasColors.sand.opacity(0),
                    ProfileSetupCanvasColors.sand.opacity(0.92),
                    ProfileSetupCanvasColors.sand
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)

            VStack(spacing: 16) {
                Button {
                    Task { await submitJoin() }
                } label: {
                    HStack(spacing: 8) {
                        Text("Join the Locals")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ProfileSetupCanvasColors.dark)
                    .clipShape(Capsule())
                    .shadow(color: ProfileSetupCanvasColors.dark.opacity(0.2), radius: 8, x: 0, y: 8)
                }
                .buttonStyle(ProfileSetupJoinButtonStyle())
                .disabled(isSubmitting)

                Button {
                    Task { await skipToVerifyLocal() }
                } label: {
                    Text("I'll do this later")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(ProfileSetupCanvasColors.dark.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 4)
            .background(ProfileSetupCanvasColors.sand)
        }
    }

    private func submitJoin() async {
        let u = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard u.count >= 3 else {
            session.showError("Choose a username (at least 3 characters).")
            return
        }
        guard password.count >= 8 else {
            session.showError("Password must be at least 8 characters.")
            return
        }
        guard let birthday = parseBirthday(birthdayText), isAdult(birthday) else {
            session.showError("Enter a valid birthday (e.g. 01/15/2000). You must be 18+.")
            return
        }
        _ = birthday
        isSubmitting = true
        let ok = await session.submitProfileSetupSignup(username: u, password: password)
        isSubmitting = false
        if ok {
            onProceedToVerifyLocal()
        }
    }

    private func skipToVerifyLocal() async {
        #if DEBUG
        let ok = await session.devStressLogin()
        if ok {
            onProceedToVerifyLocal()
        }
        #else
        if session.signedIn {
            onProceedToVerifyLocal()
        } else {
            session.showInfo("Finish sign up with Join the Locals when email signup is available.")
        }
        #endif
    }

    private func parseBirthday(_ raw: String) -> Date? {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }

        let digits = t.filter(\.isNumber)
        if digits.count == 8 {
            let m = Int(digits.prefix(2)) ?? 0
            let d = Int(digits.dropFirst(2).prefix(2)) ?? 0
            let y = Int(digits.suffix(4)) ?? 0
            var c = DateComponents()
            c.year = y
            c.month = m
            c.day = d
            c.calendar = Calendar(identifier: .gregorian)
            c.timeZone = TimeZone.current
            if let date = c.date, m >= 1, m <= 12, d >= 1, d <= 31, y >= 1900, y <= 2100 {
                return date
            }
        }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        for pattern in ["MM/dd/yyyy", "M/d/yyyy", "MM/d/yyyy", "M/dd/yyyy", "yyyy-MM-dd"] {
            df.dateFormat = pattern
            if let d = df.date(from: t) {
                return d
            }
        }
        return nil
    }

    private func isAdult(_ date: Date) -> Bool {
        guard let eighteenYearsAgo = Calendar.current.date(byAdding: .year, value: -18, to: Date()) else {
            return false
        }
        return date <= eighteenYearsAgo
    }
}

#if DEBUG
#Preview {
    ProfileSetupScreen(onDismiss: {}, onProceedToVerifyLocal: {})
        .environmentObject(SessionManager())
}
#endif
