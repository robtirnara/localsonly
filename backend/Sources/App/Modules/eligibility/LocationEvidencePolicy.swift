import Foundation

enum LocationEvidencePolicy {
    // Precise coordinates are used in-memory for check execution only.
    // Durable storage is limited to coarse summaries and decision metadata.
    static let persistRawCoordinates = false
    static let temporaryPipelineTTLDays = 1
    static let snapshotRetentionDays = 180

    static let allowedCoarseOutcomes: Set<String> = [
        "in_city",
        "near_boundary",
        "outside_city"
    ]
}
