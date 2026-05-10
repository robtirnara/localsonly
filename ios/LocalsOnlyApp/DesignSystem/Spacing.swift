import SwiftUI

enum Spacing {
    /// Extra bottom padding for scroll content above `CoastalTabBar` — the elevated FAB
    /// overlaps the layout bounds, so `safeAreaInset` alone under-reserves space.
    static let tabBarScrollBottomInset: CGFloat = 52

    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
