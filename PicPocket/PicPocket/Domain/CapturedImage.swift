import Foundation

enum CaptureSourceKind: String, Codable, Equatable, Sendable {
    case screenshot
    case savedImageCandidate
    case manualSelection
}

enum ReviewStatus: String, Codable, Equatable, Sendable {
    case new
    case confirmed
    case changedByUser
    case ignored
}

struct CapturedImage: Equatable, Identifiable, Codable, Sendable {
    var id: String { assetLocalIdentifier }
    var assetLocalIdentifier: String
    var sourceKind: CaptureSourceKind
    var creationDate: Date?
    var addedDate: Date?
    var recognizedText: String
    var detectedCodes: [String]
    var category: CaptureCategory
    var confidence: Double
    var reviewStatus: ReviewStatus
    var isSensitive: Bool
    var lastAnalyzedAt: Date
}
