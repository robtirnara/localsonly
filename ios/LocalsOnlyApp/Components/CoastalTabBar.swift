import SwiftUI

/// Bottom navigation matching AIDesigner HTML reference canvases:
/// - Inactive: `text-gray-400`, Phosphor-style **bold** icons (`ph-bold`), `text-[11px] font-bold`, `gap-1` between icon and label.
/// - Selected: `text-coastal-sunset` (`#f97316`), **filled** icons (`ph-fill`).
/// - Center: elevated `w-16 h-16` FAB `bg-coastal-dark`, white filled palm, `border-4 border-coastal-sand`, shadow (no caption under FAB).
struct CoastalTabBar: View {
    @Binding var selection: SessionManager.AppTab

    /// Tailwind `gray-400` (#9ca3af)
    private let inactiveColor = Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)

    private let iconPointSize: CGFloat = 22
    private let labelPointSize: CGFloat = 11

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.coastalInk.opacity(0.08))
                .frame(height: 1)

            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 0) {
                    tabColumn(tab: .feed, title: "Feed", outline: "house", filled: "house.fill")
                    tabColumn(tab: .ranks, title: "Ranks", outline: "trophy", filled: "trophy.fill")
                    Color.clear
                        .frame(maxWidth: .infinity)
                    tabColumn(tab: .map, title: "Map", outline: "safari", filled: "safari.fill")
                    tabColumn(tab: .profile, title: "Profile", outline: "person", filled: "person.fill")
                }

                logFAB
                    .offset(y: -24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background {
            UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: 32, bottomLeading: 0, bottomTrailing: 0, topTrailing: 32))
                .fill(Color.coastalTabBar)
                .ignoresSafeArea(edges: .bottom)
        }
        .shadow(color: Color.coastalCoral.opacity(0.12), radius: 24, x: 0, y: -12)
    }

    private func tabColumn(tab: SessionManager.AppTab, title: String, outline: String, filled: String) -> some View {
        let active = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: active ? filled : outline)
                    .font(.system(size: iconPointSize, weight: .bold))
                    .foregroundStyle(active ? Color.coastalCoral : inactiveColor)
                Text(title)
                    .font(.system(size: labelPointSize, weight: .bold))
                    .foregroundStyle(active ? Color.coastalCoral : inactiveColor)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var logFAB: some View {
        Button {
            selection = .rate
        } label: {
            PalmTreeShape()
                .fill(Color.white)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .frame(width: 64, height: 64)
        .background(Color.coastalInk, in: Circle())
        .overlay(
            Circle()
                .stroke(Color.coastalSand, lineWidth: 4)
        )
        .shadow(color: Color.coastalInk.opacity(0.35), radius: 12, y: 6)
        .accessibilityLabel("Log spot")
    }
}
