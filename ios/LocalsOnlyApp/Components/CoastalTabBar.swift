import SwiftUI

/// Bottom navigation matching AIDesigner `user-feed` HTML shell:
/// - Bar: `bg-card/95` + blur, `rounded-t-[40px]`, `shadow-[0_-10px_40px_rgba(0,0,0,0.05)]`, `pt-4 pb-8 px-6`.
/// - Tabs: `text-xs font-bold`; active `text-ocean` + filled SF Symbols; inactive `text-concrete` + bold weight.
/// - FAB: `absolute -top-12`, `w-16 h-16 bg-sky`, `border-4 border-sand`, `ph-bold ph-plus text-ocean` (no caption).
/// Tab routing unchanged: Home→`.feed`, Explore→`.ranks`, FAB→`.rate`, Saved→`.saved`, Profile→`.profile`.
struct CoastalTabBar: View {
    @Binding var selection: SessionManager.AppTab

    private let activeColor = Color.feedCanvasOcean
    private let inactiveColor = Color.feedCanvasConcrete
    private let iconPointSize: CGFloat = 22
    private let labelPointSize: CGFloat = 10

    /// Tighter than canvas `rounded-t-[40px]` so the strip reads smaller on device.
    private let barTopRadius: CGFloat = 28

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: 0) {
                tabColumn(tab: .feed, title: "Home", outline: "house", filled: "house.fill")
                tabColumn(tab: .ranks, title: "Explore", outline: "safari", filled: "safari.fill")
                Color.clear
                    .frame(maxWidth: .infinity)
                tabColumn(tab: .saved, title: "Saved", outline: "bookmark", filled: "bookmark.fill")
                tabColumn(tab: .profile, title: "Profile", outline: "person", filled: "person.fill")
            }

            rateFAB
                .offset(y: -22)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background {
            let radii = RectangleCornerRadii(topLeading: barTopRadius, bottomLeading: 0, bottomTrailing: 0, topTrailing: barTopRadius)
            let shape = UnevenRoundedRectangle(cornerRadii: radii, style: .continuous)
            shape
                .fill(.ultraThinMaterial)
                .overlay {
                    shape.fill(Color.feedCanvasCard.opacity(0.52))
                }
                .clipShape(shape)
                .ignoresSafeArea(edges: .bottom)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: -6)
        /// `safeAreaInset` often proposes **unbounded vertical height**; `ZStack` expands to fill it — hug intrinsic height only.
        .fixedSize(horizontal: false, vertical: true)
    }

    private func tabColumn(tab: SessionManager.AppTab, title: String, outline: String, filled: String) -> some View {
        let active = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: active ? filled : outline)
                    .font(.system(size: iconPointSize, weight: .bold))
                    .foregroundStyle(active ? activeColor : inactiveColor)
                Text(title)
                    .font(.system(size: labelPointSize, weight: .bold, design: .rounded))
                    .foregroundStyle(active ? activeColor : inactiveColor)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var rateFAB: some View {
        Button {
            selection = .rate
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.feedCanvasOcean)
        }
        .buttonStyle(.plain)
        .frame(width: 54, height: 54)
        .background(Color.feedCanvasSky, in: Circle())
        .overlay(
            Circle()
                .stroke(Color.feedCanvasSand, lineWidth: 3)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 4)
        .accessibilityLabel("Add review")
    }
}
