import PhotosUI
import SwiftUI

// MCP canvas `verify-local` — UUID 97b8a82c-e4dc-4ac4-9b41-899320024461 (`get_canvas` HTML).
// Full-window sand + orbs match **Select Tastes** via parent `tastesScreenBackgroundFill` (`OnboardingScreen`).

private enum VerifyLocalCanvasColors {
    static let ocean = Color(hex: 0x2A5D84)
    static let sky = Color(hex: 0x85BDD5)
    static let ink = Color(hex: 0x1A1A1A)
    /// Matches `tastesScreenBackgroundFill` base (`WelcomeCanvasColors.sandGray`).
    static let tastesSand = Color(hex: 0xEFEFEF)
    static let white = Color.white
}

/// Verify Local step after first sign-in (`verify-local` canvas).
struct VerifyLocalStatusScreen: View {
    @EnvironmentObject private var session: SessionManager

    var onContinue: () -> Void

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    topWaveBand
                    VStack(spacing: 0) {
                        headerBar
                        progressPills
                        mainScroll
                    }
                }
            }

            bottomSubmitBar
        }
        .background(Color.clear)
    }

    private var topWaveBand: some View {
        LinearGradient(
            colors: [
                VerifyLocalCanvasColors.sky.opacity(0.15),
                VerifyLocalCanvasColors.tastesSand.opacity(0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 250)
        .frame(maxWidth: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }

    private var headerBar: some View {
        HStack {
            Color.clear.frame(width: 48, height: 48)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Image(systemName: "tree.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(VerifyLocalCanvasColors.ink)
                Text("localsonly")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .tracking(-0.3)
                    .foregroundStyle(VerifyLocalCanvasColors.ink)
            }

            Spacer(minLength: 0)

            Color.clear.frame(width: 48, height: 48)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var progressPills: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { _ in
                Capsule()
                    .fill(VerifyLocalCanvasColors.sky.opacity(0.3))
                    .frame(width: 40, height: 6)
            }
            Capsule()
                .fill(VerifyLocalCanvasColors.ocean)
                .frame(width: 40, height: 6)
                .shadow(color: VerifyLocalCanvasColors.ocean.opacity(0.4), radius: 4, x: 0, y: 0)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 8)
    }

    private var mainScroll: some View {
        ScrollView {
            VStack(spacing: 0) {
                titleBlock
                    .padding(.bottom, 32)

                uploadCard
                    .padding(.bottom, 32)

                orDivider
                    .padding(.bottom, 32)

                locationAlternateRow
                    .padding(.bottom, 16)

                Text("Your info is encrypted and never shared. We only use this one time to verify your coastal zip code.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(VerifyLocalCanvasColors.ink.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 140)
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }

    private var titleBlock: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text("Prove you're a")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(VerifyLocalCanvasColors.ink)
                    .tracking(-0.5)
                Text("true local.")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(VerifyLocalCanvasColors.ocean)
                    .tracking(-0.5)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

            Text("To keep the vibes authentic and the kooks out, we need a quick check. Upload an ID or a piece of local mail.")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(VerifyLocalCanvasColors.ink.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
    }

    private var uploadCard: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(VerifyLocalCanvasColors.sky.opacity(0.1))
                    .rotationEffect(.degrees(2))

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(VerifyLocalCanvasColors.sky.opacity(0.2))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.text.rectangle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(VerifyLocalCanvasColors.ocean)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 4) {
                        Text("Upload Document")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(VerifyLocalCanvasColors.ink)
                        Text("PNG, JPG or PDF up to 5MB")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(VerifyLocalCanvasColors.ink.opacity(0.5))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Open Camera")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(VerifyLocalCanvasColors.ocean)
                    .clipShape(Capsule())
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(VerifyLocalCanvasColors.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(
                            VerifyLocalCanvasColors.sky,
                            style: StrokeStyle(lineWidth: 2, dash: [10, 8])
                        )
                )
                .shadow(color: VerifyLocalCanvasColors.ink.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var orDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(VerifyLocalCanvasColors.ink.opacity(0.2))
                .frame(height: 1)
            Text("or verify faster")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(VerifyLocalCanvasColors.ink.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1.2)
            Rectangle()
                .fill(VerifyLocalCanvasColors.ink.opacity(0.2))
                .frame(height: 1)
        }
        .opacity(0.85)
    }

    private var locationAlternateRow: some View {
        Button {
            session.showInfo("Location verify — coming soon")
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(VerifyLocalCanvasColors.tastesSand)
                        .frame(width: 48, height: 48)
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(VerifyLocalCanvasColors.ocean)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Use Current Location")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(VerifyLocalCanvasColors.ink)
                    Text("We'll check your GPS")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(VerifyLocalCanvasColors.ink.opacity(0.6))
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(VerifyLocalCanvasColors.ink.opacity(0.4))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(VerifyLocalCanvasColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(VerifyLocalCanvasColors.sky.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: VerifyLocalCanvasColors.ink.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(SignupAuthButtonPressStyle())
    }

    private var bottomSubmitBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    VerifyLocalCanvasColors.tastesSand.opacity(0),
                    VerifyLocalCanvasColors.tastesSand.opacity(0.96),
                    VerifyLocalCanvasColors.tastesSand
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)

            Button {
                onContinue()
            } label: {
                HStack(spacing: 10) {
                    Text("Submit Verification")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(VerifyLocalCanvasColors.ocean)
                .clipShape(Capsule())
                .shadow(color: VerifyLocalCanvasColors.ocean.opacity(0.25), radius: 20, x: 0, y: 10)
            }
            .buttonStyle(SignupAuthButtonPressStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
            .padding(.top, 4)
            .background(VerifyLocalCanvasColors.tastesSand)
        }
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color(hex: 0xEFEFEF).ignoresSafeArea()
        VerifyLocalStatusScreen(onContinue: {})
            .environmentObject(SessionManager())
    }
}
#endif
