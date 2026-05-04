import SwiftUI

extension Font {
    static let heroTitle = Font.system(.largeTitle, design: .serif).weight(.bold)
    static let sectionTitle = Font.system(.title2, design: .serif).weight(.semibold)
    static let cardTitle = Font.system(.headline, design: .default).weight(.semibold)
    static let bodyCopy = Font.system(.body, design: .default)
    static let captionCopy = Font.system(.caption, design: .default)
    static let microLabel = Font.system(.caption2, design: .default).weight(.medium)
}
