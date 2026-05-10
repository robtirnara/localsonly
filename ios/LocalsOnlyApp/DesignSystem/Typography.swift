import SwiftUI

extension Font {
    /// Large marketing / feed headers (sans, heavy — matches reference UI scale).
    static let heroTitle = Font.system(.largeTitle, design: .default).weight(.heavy)
    static let sectionTitle = Font.system(.title2, design: .default).weight(.bold)
    static let cardTitle = Font.system(.headline, design: .default).weight(.semibold)
    static let bodyCopy = Font.system(.body, design: .default)
    static let captionCopy = Font.system(.caption, design: .default)
    static let microLabel = Font.system(.caption2, design: .default).weight(.medium)
}
