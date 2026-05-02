import Foundation

enum ScanRange: String, Codable, Equatable, Sendable {
    case recentYear
    case allTime
}

enum ScanPhase: Equatable, Sendable {
    case idle
    case findingImages
    case analyzing
    case saving
    case completed
    case cancelled
    case failed(String)

    var title: String {
        switch self {
        case .idle: "대기 중"
        case .findingImages: "이미지 찾는 중"
        case .analyzing: "분석 중"
        case .saving: "저장 중"
        case .completed: "완료"
        case .cancelled: "취소됨"
        case .failed: "실패"
        }
    }
}

struct ScanProgress: Equatable, Sendable {
    var phase: ScanPhase = .idle
    var candidateCount = 0
    var analyzedCount = 0
    var classifiedCount = 0
    var unknownCount = 0
}

struct PhotoAssetCandidate: Equatable, Identifiable, Sendable {
    var id: String
    var sourceKind: CaptureSourceKind
    var creationDate: Date?
    var addedDate: Date?
}
