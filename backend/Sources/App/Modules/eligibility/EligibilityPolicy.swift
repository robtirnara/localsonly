import Foundation

struct EligibilityInput {
    let accountTrustScore: Double
    let localityScore: Double
    let abuseRiskScore: Double
    let postingFrozen: Bool
    let underReview: Bool
}

struct EligibilityPolicy {
    // Thresholds are intentionally centralized for quick policy tuning.
    let verifiedTrustMinimum = 70.0
    let verifiedLocalityMinimum = 75.0
    let provisionalTrustMinimum = 40.0
    let provisionalLocalityMinimum = 45.0
    let riskRestrictedThreshold = 85.0
    let riskReviewThreshold = 70.0

    func deriveState(input: EligibilityInput) -> EligibilityState {
        if input.postingFrozen { return .restricted }
        if input.underReview { return .underReview }
        if input.abuseRiskScore >= riskRestrictedThreshold { return .restricted }
        if input.abuseRiskScore >= riskReviewThreshold { return .underReview }

        if input.accountTrustScore >= verifiedTrustMinimum &&
            input.localityScore >= verifiedLocalityMinimum {
            return .verifiedLocal
        }

        if input.accountTrustScore >= provisionalTrustMinimum &&
            input.localityScore >= provisionalLocalityMinimum {
            return .provisionalLocal
        }

        return .browseOnly
    }
}
