import SwiftUI
import UIKit

// MARK: - Semantic fonts (AIDesigner: SF Rounded, bold labels, no “paper” default weights)

extension Font {
    private static func lo(_ style: Font.TextStyle, weight: Font.Weight) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    private static func lo(size: CGFloat, weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let heroTitle = lo(.largeTitle, weight: .heavy)
    static let sectionTitle = lo(.title2, weight: .bold)
    static let cardTitle = lo(.headline, weight: .bold)
    static let bodyCopy = lo(.body, weight: .semibold)
    static let captionCopy = lo(.caption, weight: .semibold)
    static let microLabel = lo(.caption2, weight: .bold)

    static let profileDisplayName = lo(size: 24, weight: .heavy)
    static let profileHandle = lo(size: 13, weight: .semibold)
    static let profileBio = lo(size: 14, weight: .semibold)
    static let profileEyebrow = lo(size: 11, weight: .bold)
    static let tasteMapCategory = lo(size: 11, weight: .heavy)
    static let tasteProfileCardTitle = lo(size: 17, weight: .bold)
    static let profileRankingsHeading = lo(size: 20, weight: .bold)
    static let profileTabLabel = lo(size: 13, weight: .bold)
    static let profileTabLabelInactive = lo(size: 13, weight: .semibold)
    static let profileQuickActionTitle = lo(size: 14, weight: .bold)
    static let profileQuickActionMeta = lo(size: 11, weight: .semibold)

    /// Inline canvas text (prefer semantic tokens when possible).
    static func lo(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        lo(size: size, weight: weight)
    }
}

// MARK: - UIKit (navigation, fields, lists)

extension UIFont {
    static func loRounded(size: CGFloat, weight: UIFont.Weight = .semibold) -> UIFont {
        let system = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = system.fontDescriptor.withDesign(.rounded) else { return system }
        return UIFont(descriptor: descriptor, size: size)
    }
}

enum AppTypography {
    static func configure() {
        let navTitle = UIFont.loRounded(size: 17, weight: .bold)
        let navLarge = UIFont.loRounded(size: 34, weight: .heavy)

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.titleTextAttributes = [.font: navTitle]
        navAppearance.largeTitleTextAttributes = [.font: navLarge]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance

        UITextField.appearance().font = UIFont.loRounded(size: 17, weight: .semibold)
        UITextView.appearance().font = UIFont.loRounded(size: 16, weight: .semibold)

        let segmentAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.loRounded(size: 13, weight: .bold)]
        UISegmentedControl.appearance().setTitleTextAttributes(segmentAttrs, for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes(segmentAttrs, for: .selected)

        UILabel.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).font =
            UIFont.loRounded(size: 16, weight: .semibold)
    }
}

// MARK: - SwiftUI defaults

extension View {
    /// Rounded design for views that inherit environment font (e.g. `Label`, some `Form` rows).
    func loAppTypography() -> some View {
        fontDesign(.rounded)
    }
}
