import ComposableArchitecture
import Foundation

struct ClassificationResult: Equatable, Sendable {
    var category: CaptureCategory
    var confidence: Double
    var reason: String
    var isSensitive: Bool
}

struct ClassificationClient: Sendable {
    var classify: @Sendable (_ analysis: VisionAnalysisResult, _ sourceKind: CaptureSourceKind) -> ClassificationResult
}

extension ClassificationClient: DependencyKey {
    static let liveValue = ClassificationClient.live
    static let testValue = ClassificationClient(
        classify: { _, _ in
            ClassificationResult(category: .unknown, confidence: 0, reason: "test", isSensitive: false)
        }
    )
}

extension DependencyValues {
    var classificationClient: ClassificationClient {
        get { self[ClassificationClient.self] }
        set { self[ClassificationClient.self] = newValue }
    }
}
