import XCTest
@testable import App

final class EligibilityPolicyTests: XCTestCase {
    func testVerifiedLocalBand() {
        let policy = EligibilityPolicy()
        let state = policy.deriveState(input: EligibilityInput(
            accountTrustScore: 80,
            localityScore: 85,
            abuseRiskScore: 20,
            postingFrozen: false,
            underReview: false
        ))
        XCTAssertEqual(state, .verifiedLocal)
    }

    func testRestrictedWhenPostingFrozen() {
        let policy = EligibilityPolicy()
        let state = policy.deriveState(input: EligibilityInput(
            accountTrustScore: 95,
            localityScore: 95,
            abuseRiskScore: 10,
            postingFrozen: true,
            underReview: false
        ))
        XCTAssertEqual(state, .restricted)
    }

    func testUnderReviewRiskThreshold() {
        let policy = EligibilityPolicy()
        let state = policy.deriveState(input: EligibilityInput(
            accountTrustScore: 70,
            localityScore: 75,
            abuseRiskScore: 75,
            postingFrozen: false,
            underReview: false
        ))
        XCTAssertEqual(state, .underReview)
    }
}
