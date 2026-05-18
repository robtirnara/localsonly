import SwiftUI

struct ListsScreen: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var lists: [ListResponse] = []
    @State private var isLoading = true
    @State private var showCreateSheet = false
    @State private var newListName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ForEach(0..<3, id: \.self) { _ in LoadingShimmer() }
                        .padding(.horizontal, Spacing.md)
                } else if lists.isEmpty {
                    EmptyStateView(
                        title: "No lists yet",
                        message: "Create a list like \"Best Tacos\" or \"Date Night\" to organize your spots.",
                        icon: "list.bullet.rectangle"
                    )
                    .padding(.top, Spacing.xl)
                } else {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(lists) { list in
                            NavigationLink(value: list.id) {
                                GlassCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                                            Text(list.name)
                                                .font(.cardTitle)
                                                .foregroundStyle(Color.coastalTextPrimary)
                                            Text("\(list.itemCount) places")
                                                .font(.captionCopy)
                                                .foregroundStyle(Color.coastalTextSecondary)
                                        }
                                        Spacer()
                                        if !list.isPublic {
                                            Image(systemName: "lock.fill")
                                                .font(.captionCopy)
                                                .foregroundStyle(Color.coastalSand)
                                        }
                                        Image(systemName: "chevron.right")
                                            .font(.captionCopy)
                                            .foregroundStyle(Color.coastalTextSecondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await deleteList(list.id) }
                                } label: {
                                    Label("Delete List", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
            }
            .refreshable { await load() }
            .navigationTitle("My Lists")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { listID in
                ListDetailScreen(listID: listID)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.coastalAqua)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newListName = ""
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.coastalAqua)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                createListSheet
                    .presentationDetents([.medium])
                    .presentationBackground(Color.coastalBackground)
            }
        }
        .task { await load() }
    }

    private var createListSheet: some View {
        VStack(spacing: Spacing.md) {
            Text("New List")
                .font(.sectionTitle)
                .foregroundStyle(Color.coastalTextPrimary)

            TextField("List name (e.g. Best Tacos)", text: $newListName)
                .foregroundStyle(Color.coastalTextPrimary)
                .padding()
                .background(Color.coastalCard)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            PrimaryButton(title: "Create") {
                Task { await createList() }
            }
            .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            lists = try await session.api.myLists()
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func createList() async {
        let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            let list = try await session.api.createList(name: name, description: nil, isPublic: true)
            lists.insert(list, at: 0)
            showCreateSheet = false
            session.showSuccess("List created")
        } catch {
            session.showError(error.localizedDescription)
        }
    }

    private func deleteList(_ id: UUID) async {
        do {
            try await session.api.deleteList(id: id)
            lists.removeAll { $0.id == id }
            session.showSuccess("List deleted")
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}

struct ListDetailScreen: View {
    let listID: UUID
    @EnvironmentObject private var session: SessionManager
    @State private var detail: ListDetailResponse?
    @State private var isLoading = true

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            if isLoading {
                ForEach(0..<3, id: \.self) { _ in ImageTileShimmer() }
                    .padding(.horizontal, Spacing.md)
            } else if let detail {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    if !detail.description.isEmpty {
                        Text(detail.description)
                            .font(.bodyCopy)
                            .foregroundStyle(Color.coastalTextSecondary)
                            .padding(.horizontal, Spacing.md)
                    }

                    Text("\(detail.items.count) places")
                        .font(.captionCopy)
                        .foregroundStyle(Color.coastalTextSecondary)
                        .padding(.horizontal, Spacing.md)

                    if detail.items.isEmpty {
                        EmptyStateView(
                            title: "Empty list",
                            message: "Add places from the place detail screen.",
                            icon: "list.bullet"
                        )
                    } else {
                        LazyVGrid(columns: gridColumns, spacing: Spacing.md) {
                            ForEach(detail.items, id: \.placeID) { item in
                                Button {
                                    session.presentPlaceDetail(item.placeID)
                                } label: {
                                    ImageTileCard(
                                        title: item.placeName,
                                        subtitle: [item.category.capitalized, item.neighborhood].compactMap { $0 }.joined(separator: " · "),
                                        imageURL: item.coverPhotoURL,
                                        category: item.category
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
        }
        .navigationTitle(detail?.name ?? "List")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            detail = try await session.api.listDetail(id: listID)
        } catch {
            session.showError(error.localizedDescription)
        }
    }
}
