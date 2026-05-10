import SwiftUI
import UIKit

@main
struct LocalsOnlyApp: App {
    init() {
        Self.configureTabBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    /// Matches AIDesigner HTML (`bg-[#fffaf5]` + orange shadow); avoids default system tab strip gray.
    private static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 1.0, green: 250 / 255, blue: 245 / 255, alpha: 1.0)
        appearance.shadowColor = UIColor(white: 0, alpha: 0.06)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
