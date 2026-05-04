import SwiftUI

struct NotificationsScreen: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [NotificationResponse] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ForEach(0..<3, id: \.self) { _ in
                        LoadingShimmer()
                    }
                    .padding(.horizontal, Spacing.md)
                } else if notifications.isEmpty {
                    EmptyStateView(
                        title: "No notifications",
                        message: "Activity from friends and updates will appear here.",
                        icon: "bell"
                    )
                    .padding(.top, Spacing.xl)
                } else {
                    LazyVStack(spacing: Spacing.xs) {
                        ForEach(notifications) { notif in
                            notificationRow(notif)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
            }
            .refreshable { await load() }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.coastalAqua)
                }
                if notifications.contains(where: { !$0.isRead }) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Read All") {
                            Task { await markAllRead() }
                        }
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalAqua)
                    }
                }
            }
        }
        .task { await load() }
    }

    private func notificationRow(_ notif: NotificationResponse) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: iconForType(notif.type))
                .font(.system(size: 20))
                .foregroundStyle(notif.isRead ? Color.coastalTextSecondary : Color.coastalAqua)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(notif.title)
                    .font(.cardTitle)
                    .foregroundStyle(notif.isRead ? Color.coastalTextSecondary : Color.coastalTextPrimary)
                if !notif.body.isEmpty {
                    Text(notif.body)
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalTextSecondary)
                        .lineLimit(2)
                }
                Text(notif.createdAt.relativeString)
                    .font(.microLabel)
                    .foregroundStyle(Color.coastalTextSecondary)
            }

            Spacer()

            if !notif.isRead {
                Circle()
                    .fill(Color.coastalAqua)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(notif.isRead ? Color.clear : Color.coastalAqua.opacity(0.05))
        )
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "friend_request": return "person.badge.plus"
        case "friend_accepted": return "person.2.fill"
        case "cosign": return "hand.thumbsup.fill"
        case "new_rating": return "star.fill"
        default: return "bell.fill"
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            notifications = try await session.api.listNotifications()
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func markAllRead() async {
        do {
            try await session.api.markAllNotificationsRead()
            notifications = notifications.map {
                NotificationResponse(id: $0.id, type: $0.type, title: $0.title,
                                   body: $0.body, referenceID: $0.referenceID,
                                   isRead: true, createdAt: $0.createdAt)
            }
            session.unreadNotificationCount = 0
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}
