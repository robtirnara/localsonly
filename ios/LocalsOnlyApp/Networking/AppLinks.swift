import Foundation

/// Public URLs for in-app links. Set non-nil values when the marketing or policy pages are live.
enum AppLinks {
    static let privacyPolicy: URL? = nil
    static let termsOfService: URL? = nil
    /// Optional explainer for local contributor / eligibility (replaces in-repo docs when hosted).
    static let localContributorInfo: URL? = nil
}
