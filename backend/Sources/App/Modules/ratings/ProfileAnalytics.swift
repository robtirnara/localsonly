import Foundation

struct ProfileAnalytics: Codable {
    let averageScore: Double
    let numberOfRatings: Int
    let tagBreakdown: [String: Int]
    let scoreDistribution: [String: Int]
    let topPlaces: [UUID]
}

enum ProfileAnalyticsPolicy {
    static let allowedMetrics: Set<String> = [
        "average_score",
        "number_of_ratings",
        "tag_breakdown",
        "score_distribution",
        "top_places"
    ]
}
