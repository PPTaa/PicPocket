import ComposableArchitecture
import UIKit

struct VisionClient: Sendable {
    var analyze: @Sendable (_ image: UIImage) async -> VisionAnalysisResult
}

extension VisionClient: DependencyKey {
    static let liveValue = VisionClient.live
    static let testValue = VisionClient(analyze: { _ in .empty })
}

extension DependencyValues {
    var visionClient: VisionClient {
        get { self[VisionClient.self] }
        set { self[VisionClient.self] = newValue }
    }
}
