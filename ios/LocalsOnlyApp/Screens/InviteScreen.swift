import SwiftUI
import UIKit

/// `invite` canvas (`073186c0-…`): hero, invite link, quick share grid — slide-up sheet from `RootView`.
struct InviteScreen: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode: InviteCodeResponse?
    @State private var invitedUsers: [InvitedUserResponse] = []
    @State private var isLoading = true
    @State private var didCopyLink = false

    private let heroImageURL =
        "https://images.unsplash.com/photo-1520116468816-95b69f847357?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"

    private var inviteLinkText: String {
        guard let code = inviteCode?.code else { return "localsonly.app/…" }
        let slug = code.lowercased().replacingOccurrences(of: " ", with: "")
        return "localsonly.app/\(slug)"
    }

    private var shareMessage: String {
        guard let code = inviteCode?.code else {
            return "Join me on LocalsOnly — good spots for good people."
        }
        return "Join me on LocalsOnly! Use my link: \(inviteLinkText) (code: \(code))"
    }

    private var invitesRemainingCopy: String {
        guard let inviteCode else { return "Loading invites…" }
        let remaining = max(0, 5 - inviteCode.usedCount)
        return "\(remaining) invites remaining this week"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                sheetDragHandle
                headerChrome
                    .padding(.bottom, InviteCanvasMetrics.sectionGap)

                if isLoading {
                    loadingPlaceholder
                } else {
                    heroCard
                        .padding(.bottom, InviteCanvasMetrics.sectionGap)

                    Text("Good spots are meant to be shared with good people. Invite your trusted circle to LocalsOnly.")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasInk.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, InviteCanvasMetrics.contentInset)
                        .padding(.bottom, InviteCanvasMetrics.sectionGap)

                    inviteLinkCard
                        .padding(.bottom, InviteCanvasMetrics.sectionGap)

                    quickShareSection
                        .padding(.bottom, InviteCanvasMetrics.sectionGap)

                    invitesRemainingPill
                        .padding(.bottom, InviteCanvasMetrics.sectionGap)

                    if !invitedUsers.isEmpty {
                        invitedUsersSection
                    }
                }
            }
            .padding(.horizontal, InviteCanvasMetrics.screenGutter)
            .padding(.bottom, InviteCanvasMetrics.scrollBottomInset)
        }
        .scrollIndicators(.hidden)
        .background(Color.feedCanvasSand)
        .task { await load() }
    }

    // MARK: - Chrome

    private var sheetDragHandle: some View {
        Capsule()
            .fill(Color.feedCanvasConcrete.opacity(0.35))
            .frame(width: 40, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 8)
    }

    private var headerChrome: some View {
        HStack {
            Button {
                dismiss()
                session.dismissInviteFriends()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.feedCanvasInk)
                    .frame(width: 48, height: 48)
                    .background(Color.feedCanvasCard.opacity(0.5))
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()

            Text("Invite Locals")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.feedCanvasOcean)
                    .frame(width: 48, height: 48)
                PalmTreeShape()
                    .fill(Color.feedCanvasSand)
                    .frame(width: 22, height: 26)
            }
            .accessibilityHidden(true)
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: heroImageURL)) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.feedCanvasHeroPlaceholder
                }
            }
            .frame(height: InviteCanvasMetrics.heroHeight)
            .frame(maxWidth: .infinity)
            .clipped()

            LinearGradient(
                colors: [.clear, Color.feedCanvasInk.opacity(0.2), Color.feedCanvasInk.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )

            Text("Grow\nYour Crew")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasSand)
                .lineSpacing(2)
                .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: InviteCanvasMetrics.heroCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: InviteCanvasMetrics.heroCorner, style: .continuous)
                .stroke(Color.feedCanvasCard, lineWidth: 4)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, y: 6)
    }

    // MARK: - Invite link

    private var inviteLinkCard: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.feedCanvasSky.opacity(0.2))
                .offset(x: 16, y: -16)

            VStack(spacing: 16) {
                Text("Your Unique Invite Link")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasConcrete)
                    .textCase(.uppercase)
                    .tracking(1.2)

                HStack(spacing: 12) {
                    Text(inviteLinkText)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.feedCanvasOcean)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Button {
                        copyInviteLink()
                    } label: {
                        Image(systemName: didCopyLink ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.feedCanvasSand)
                            .frame(width: 40, height: 40)
                            .background(Color.feedCanvasOcean)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy invite link")
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.feedCanvasSand)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if let inviteCode {
                    Text("\(inviteCode.usedCount) friends joined so far")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.feedCanvasConcrete)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: InviteCanvasMetrics.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: InviteCanvasMetrics.cardCorner, style: .continuous)
                .stroke(Color.feedCanvasOcean.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
    }

    // MARK: - Quick share

    private var quickShareSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Share")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .padding(.leading, 8)

            HStack(spacing: 0) {
                InviteShareChannelButton(
                    title: "Messages",
                    systemImage: "message.fill",
                    background: Color(hex: 0x22C55E)
                ) {
                    shareViaSystem()
                }
                Spacer()
                InviteShareChannelButton(
                    title: "Instagram",
                    systemImage: "camera.fill",
                    background: LinearGradient(
                        colors: [Color(hex: 0xFACC15), Color(hex: 0xEC4899), Color(hex: 0x9333EA)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                ) {
                    shareViaSystem()
                }
                Spacer()
                InviteShareChannelButton(
                    title: "WhatsApp",
                    systemImage: "phone.fill",
                    background: Color(hex: 0x25D366)
                ) {
                    shareViaSystem()
                }
                Spacer()
                InviteShareChannelButton(
                    title: "More",
                    systemImage: "ellipsis",
                    background: Color.feedCanvasOcean
                ) {
                    shareViaSystem()
                }
            }
        }
    }

    private var invitesRemainingPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.feedCanvasOcean)
            Text(invitesRemainingCopy)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.feedCanvasOcean)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.feedCanvasOcean.opacity(0.1))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity)
    }

    // MARK: - Invited users (API; below canvas fold)

    private var invitedUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("People You Invited")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)

            ForEach(invitedUsers) { user in
                HStack(spacing: 12) {
                    DefaultAvatarView(variant: .forUser(user.userID), size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.feedCanvasInk)
                        if let joined = user.joinedAt {
                            Text("Joined \(joined.relativeString)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.feedCanvasConcrete)
                        }
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.feedCanvasCard)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: InviteCanvasMetrics.heroCorner)
                .fill(Color.feedCanvasHeroPlaceholder)
                .frame(height: InviteCanvasMetrics.heroHeight)
            RoundedRectangle(cornerRadius: InviteCanvasMetrics.cardCorner)
                .fill(Color.feedCanvasHeroPlaceholder)
                .frame(height: 160)
        }
    }

    // MARK: - Actions

    private func copyInviteLink() {
        UIPasteboard.general.string = shareMessage
        didCopyLink = true
        session.showSuccess("Invite link copied")
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            try? await Task.sleep(for: .seconds(2))
            didCopyLink = false
        }
    }

    private func shareViaSystem() {
        // ShareLink is used in channel buttons via overlay — trigger copy+open share sheet using UIActivity
        let controller = UIActivityViewController(activityItems: [shareMessage], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var presenter = root
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        controller.popoverPresentationController?.sourceView = presenter.view
        presenter.present(controller, animated: true)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let codeTask = session.api.myInviteCode()
            async let usersTask = session.api.invitedUsers()
            inviteCode = try await codeTask
            invitedUsers = try await usersTask
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}

// MARK: - Canvas layout (same file)

private enum InviteCanvasMetrics {
    static let screenGutter: CGFloat = 20
    static let contentInset: CGFloat = 16
    static let sectionGap: CGFloat = 32
    static let heroHeight: CGFloat = 256
    static let heroCorner: CGFloat = 32
    static let cardCorner: CGFloat = 32
    static let scrollBottomInset: CGFloat = 32
}

private struct InviteShareChannelButton<Background: ShapeStyle>: View {
    let title: String
    let systemImage: String
    let background: Background
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(background)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)

                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk.opacity(0.8))
                    .lineLimit(1)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
    }
}
