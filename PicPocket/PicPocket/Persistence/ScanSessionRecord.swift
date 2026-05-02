import Foundation
import SwiftData

@Model
final class ScanSessionRecord {
    var id: UUID
    var rangeRawValue: String
    var startedAt: Date
    var finishedAt: Date?
    var candidateCount: Int
    var analyzedCount: Int
    var classifiedCount: Int
    var unknownCount: Int
    var cancelled: Bool

    init(summary: ScanSessionSummary) {
        id = UUID()
        rangeRawValue = summary.range.rawValue
        startedAt = summary.startedAt
        finishedAt = summary.finishedAt
        candidateCount = summary.candidateCount
        analyzedCount = summary.analyzedCount
        classifiedCount = summary.classifiedCount
        unknownCount = summary.unknownCount
        cancelled = summary.cancelled
    }
}
