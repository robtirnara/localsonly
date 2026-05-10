import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @State private var confirmSignOut = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    appearanceSection
                    accountSection
                    legalSection
                    productSection
                    aboutSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .padding(.bottom, Spacing.tabBarScrollBottomInset)
            }
            .background(Color.coastalBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.coastalAqua)
                }
            }
        }
        .alert("Sign out?", isPresented: $confirmSignOut) {
            Button("Sign Out", role: .destructive) {
                dismiss()
                session.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to sign in again to use LocalsOnly.")
        }
    }

    private var appearanceSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "moon.sun")
                        .foregroundStyle(Color.coastalAqua)
                    Text("Appearance")
                        .font(.cardTitle)
                        .foregroundStyle(Color.coastalTextPrimary)
                }
                Picker("", selection: $appearanceMode) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Account")
                .font(.microLabel)
                .foregroundStyle(Color.coastalTextSecondary)
                .padding(.horizontal, Spacing.xxs)

            Button {
                confirmSignOut = true
            } label: {
                GlassCard {
                    HStack {
                        Text("Sign Out")
                            .font(.bodyCopy)
                            .foregroundStyle(Color.coastalStatusRestricted)
                        Spacer()
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Legal")
                .font(.microLabel)
                .foregroundStyle(Color.coastalTextSecondary)
                .padding(.horizontal, Spacing.xxs)

            linkRow(title: "Privacy Policy", url: AppLinks.privacyPolicy)
            linkRow(title: "Terms of Service", url: AppLinks.termsOfService)
        }
    }

    private var productSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("About the product")
                .font(.microLabel)
                .foregroundStyle(Color.coastalTextSecondary)
                .padding(.horizontal, Spacing.xxs)

            linkRow(title: "Local contributor rules", subtitle: "Eligibility and expectations", url: AppLinks.localContributorInfo)
        }
    }

    private var aboutSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("About")
                    .font(.cardTitle)
                    .foregroundStyle(Color.coastalTextPrimary)
                Text("Version \(appVersion) (\(appBuild))")
                    .font(.bodyCopy)
                    .foregroundStyle(Color.coastalTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func linkRow(title: String, subtitle: String? = nil, url: URL?) -> some View {
        if let url {
            Link(destination: url) {
                GlassCard {
                    linkCardContent(title: title, subtitle: subtitle, showsChevron: true)
                }
            }
            .buttonStyle(.plain)
        } else {
            GlassCard {
                linkCardContent(title: title, subtitle: subtitle ?? "Available soon", showsChevron: false)
            }
            .opacity(0.85)
        }
    }

    private func linkCardContent(title: String, subtitle: String?, showsChevron: Bool) -> some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyCopy)
                    .foregroundStyle(Color.coastalTextPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.microLabel)
                        .foregroundStyle(Color.coastalTextSecondary)
                }
            }
            Spacer()
            if showsChevron {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.coastalAqua)
            }
        }
    }
}
