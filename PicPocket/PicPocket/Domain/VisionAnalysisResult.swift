import Foundation

struct VisionAnalysisResult: Equatable, Codable, Sendable {
    var recognizedText: String
    var detectedCodes: [String]
    var hasBarcodeOrQRCode: Bool

    nonisolated static let empty = VisionAnalysisResult(
        recognizedText: "",
        detectedCodes: [],
        hasBarcodeOrQRCode: false
    )
}
