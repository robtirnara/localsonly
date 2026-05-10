import SwiftUI

struct OnboardingScreen: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        ("trophy.fill", "Browse Local Rankings",
         "See what locals are loving across food, drinks, and coffee in San Diego."),
        ("plus.circle.fill", "Log What You Try",
         "Score your favorites, add photos, and build your personal taste profile."),
        ("person.2.fill", "Connect With Friends",
         "Follow friends, see their finds, and cosign the ratings you agree with.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                    VStack(spacing: Spacing.lg) {
                        Spacer()

                        Image(systemName: page.icon)
                            .font(.system(size: 64))
                            .foregroundStyle(Color.coastalAqua)

                        Text(page.title)
                            .font(.sectionTitle)
                            .foregroundStyle(Color.coastalTextPrimary)
                            .multilineTextAlignment(.center)

                        Text(page.subtitle)
                            .font(.bodyCopy)
                            .foregroundStyle(Color.coastalTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)

                        Spacer()
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    isPresented = false
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(.cardTitle)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.coastalCoral)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)

            if currentPage < pages.count - 1 {
                Button("Skip") {
                    isPresented = false
                }
                .font(.captionCopy)
                .foregroundStyle(Color.coastalTextSecondary)
                .padding(.bottom, Spacing.md)
            }
        }
        .background(Color.coastalBackground.ignoresSafeArea())
    }
}
