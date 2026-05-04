import SwiftUI

struct InviteScreen: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode: InviteCodeResponse?
    @State private var invitedUsers: [InvitedUserResponse] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    if isLoading {
                        LoadingShimmer()
                    } else {
                        inviteCodeCard
                        invitedUsersSection
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .navigationTitle("Invites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.coastalAqua)
                }
            }
        }
        .task { await load() }
    }

    @ViewBuilder
    private var inviteCodeCard: some View {
        if let inviteCode {
            GlassCard {
                VStack(spacing: Spacing.md) {
                    Text("Your Invite Code")
                        .font(.sectionTitle)
                        .foregroundStyle(Color.coastalTextPrimary)

                    Text(inviteCode.code)
                        .font(.system(.title, design: .monospaced).weight(.bold))
                        .foregroundStyle(Color.coastalAqua)
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.lg)
                        .background(Color.coastalAqua.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text("\(inviteCode.usedCount) people joined with your code")
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalTextSecondary)

                    ShareLink(item: "Join me on LocalsOnly! Use invite code: \(inviteCode.code)") {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Code")
                                .font(.cardTitle)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.coastalCoral)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var invitedUsersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("People You Invited")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)

            if invitedUsers.isEmpty {
                GlassCard {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.coastalAqua)
                        Text("Share your invite code to grow the community.")
                            .font(.captionCopy)
                            .foregroundStyle(Color.coastalTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(invitedUsers) { user in
                    GlassCard {
                        HStack {
                            DefaultAvatarView(variant: .forUser(user.userID), size: 40)
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(user.displayName)
                                    .font(.cardTitle)
                                    .foregroundStyle(Color.coastalTextPrimary)
                                if let joined = user.joinedAt {
                                    Text("Joined \(joined.relativeString)")
                                        .font(.captionCopy)
                                        .foregroundStyle(Color.coastalTextSecondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
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
