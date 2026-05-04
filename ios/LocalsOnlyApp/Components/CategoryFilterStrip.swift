import SwiftUI

struct CategoryFilterStrip: View {
    @Binding var selected: String

    private let filters: [(id: String, label: String, icon: String)] = [
        ("all", "All", "both"),
        ("food", "Food", "food"),
        ("drink", "Drinks", "drink"),
        ("coffee", "Coffee", "coffee"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(filters, id: \.id) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selected = filter.id
                        }
                    } label: {
                        VStack(spacing: Spacing.xxs) {
                            ZStack {
                                Circle()
                                    .fill(selected == filter.id
                                          ? Color.coastalAqua
                                          : Color.coastalSand.opacity(0.12))
                                    .frame(width: 52, height: 52)

                                CategoryIconView(category: filter.icon, size: 28)
                                    .foregroundStyle(selected == filter.id
                                                     ? .white
                                                     : Color.coastalSand)
                            }

                            Text(filter.label)
                                .font(.microLabel)
                                .foregroundStyle(selected == filter.id
                                                 ? Color.coastalTextPrimary
                                                 : Color.coastalTextSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }
}
