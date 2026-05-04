import Foundation

enum FeedKind: String, CaseIterable {
    case friendActivity = "friend_activity"
    case placeAggregateSummary = "place_aggregate_summary"
    case cityPopular = "city_popular"
}

enum FeedPolicy {
    static let supportedKinds: Set<FeedKind> = [
        .friendActivity,
        .placeAggregateSummary,
        .cityPopular
    ]

    // v1 intentionally avoids advanced ranking and ML-heavy ordering.
    static let rankingMode = "simple_trending"
}
