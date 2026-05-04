import SwiftUI

struct AdminScreen: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage("admin_bearer_token") private var adminToken = ""
    @State private var isAuthenticated = false
    @State private var users: [AdminUserResponse] = []
    @State private var ratings: [AdminRatingResponse] = []
    @State private var isLoading = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            Group {
                if isAuthenticated {
                    adminContent
                } else {
                    tokenEntry
                }
            }
            .navigationTitle("Admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.coastalAqua)
                }
                if isAuthenticated {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Logout") {
                            adminToken = ""
                            isAuthenticated = false
                            users = []
                            ratings = []
                        }
                        .foregroundStyle(Color.coastalStatusRestricted)
                    }
                }
            }
        }
    }

    private var tokenEntry: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(Color.coastalAqua)

            Text("Admin Access")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)

            Text("Enter the admin bearer token to continue.")
                .font(.bodyCopy)
                .foregroundStyle(Color.coastalTextSecondary)
                .multilineTextAlignment(.center)

            SecureField("Admin token", text: $adminToken)
                .foregroundStyle(Color.coastalTextPrimary)
                .padding()
                .background(Color.coastalCard)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            PrimaryButton(title: "Authenticate", isLoading: isLoading) {
                Task { await authenticate() }
            }
            .disabled(adminToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Spacer()
        }
        .padding(Spacing.lg)
    }

    private var adminContent: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                Text("Users").tag(0)
                Text("Ratings").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            ScrollView {
                if isLoading {
                    ProgressView()
                        .padding(Spacing.xl)
                } else if selectedTab == 0 {
                    usersSection
                } else {
                    ratingsAdminSection
                }
            }
        }
        .task {
            await loadData()
        }
    }

    private var usersSection: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(users) { user in
                GlassCard {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(user.displayName)
                                .font(.cardTitle)
                                .foregroundStyle(Color.coastalTextPrimary)
                            Spacer()
                            if user.isPostingFrozen {
                                Text("FROZEN")
                                    .font(.microLabel)
                                    .foregroundStyle(Color.coastalStatusRestricted)
                            }
                            if user.isUnderReview {
                                Text("REVIEW")
                                    .font(.microLabel)
                                    .foregroundStyle(Color.coastalStatusProvisional)
                            }
                        }
                        Text(user.homeCity)
                            .font(.captionCopy)
                            .foregroundStyle(Color.coastalTextSecondary)
                        Text(user.id.uuidString.prefix(8))
                            .font(.microLabel)
                            .foregroundStyle(Color.coastalTextSecondary)

                        HStack(spacing: Spacing.xs) {
                            Button("Flag") {
                                Task {
                                    do {
                                        try await session.api.adminFlagUser(id: user.id, reason: "Admin flagged", token: adminToken)
                                        session.statusMessage = "User flagged"
                                    } catch {
                                        session.statusMessage = error.localizedDescription
                                    }
                                }
                            }
                            .font(.captionCopy)
                            .foregroundStyle(Color.coastalStatusProvisional)

                            Button("Freeze") {
                                Task {
                                    do {
                                        try await session.api.adminFreezeUser(id: user.id, reason: "Admin froze posting", token: adminToken)
                                        session.statusMessage = "User posting frozen"
                                        await loadData()
                                    } catch {
                                        session.statusMessage = error.localizedDescription
                                    }
                                }
                            }
                            .font(.captionCopy)
                            .foregroundStyle(Color.coastalStatusRestricted)
                        }
                        .padding(.top, Spacing.xxs)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }

    private var ratingsAdminSection: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(ratings) { rating in
                GlassCard {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(rating.itemName)
                                    .font(.cardTitle)
                                    .foregroundStyle(Color.coastalTextPrimary)
                                Text("\(rating.userDisplayName) at \(rating.placeName)")
                                    .font(.captionCopy)
                                    .foregroundStyle(Color.coastalTextSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                                Text(String(format: "%.1f", rating.score))
                                    .font(.cardTitle)
                                    .foregroundStyle(Color.coastalAqua)
                                if rating.isSuppressed {
                                    Text("SUPPRESSED")
                                        .font(.microLabel)
                                        .foregroundStyle(Color.coastalStatusRestricted)
                                }
                            }
                        }

                        if !rating.isSuppressed {
                            Button("Suppress") {
                                Task {
                                    do {
                                        try await session.api.adminSuppressRating(id: rating.id, reason: "Admin suppressed", token: adminToken)
                                        session.statusMessage = "Rating suppressed"
                                        await loadData()
                                    } catch {
                                        session.statusMessage = error.localizedDescription
                                    }
                                }
                            }
                            .font(.captionCopy)
                            .foregroundStyle(Color.coastalStatusRestricted)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }

    private func authenticate() async {
        isLoading = true
        defer { isLoading = false }
        do {
            users = try await session.api.adminListUsers(token: adminToken)
            isAuthenticated = true
        } catch {
            session.statusMessage = "Invalid admin token"
        }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let usersTask = session.api.adminListUsers(token: adminToken)
            async let ratingsTask = session.api.adminListRatings(token: adminToken)
            users = try await usersTask
            ratings = try await ratingsTask
        } catch {
            session.statusMessage = error.localizedDescription
        }
    }
}
