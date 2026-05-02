import UIKit
import Vision

extension VisionClient {
    static let live = VisionClient { image in
        guard let cgImage = image.cgImage else { return .empty }

        async let text = recognizeText(cgImage)
        async let codes = detectCodes(cgImage)
        let resultText = await text
        let resultCodes = await codes

        return VisionAnalysisResult(
            recognizedText: resultText,
            detectedCodes: resultCodes,
            hasBarcodeOrQRCode: !resultCodes.isEmpty
        )
    }
}

private func recognizeText(_ cgImage: CGImage) async -> String {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["ko-KR", "en-US"]

    do {
        try VNImageRequestHandler(cgImage: cgImage).perform([request])
        let observations = request.results ?? []
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        return lines.joined(separator: "\n")
    } catch {
        return ""
    }
}

private func detectCodes(_ cgImage: CGImage) async -> [String] {
    let request = VNDetectBarcodesRequest()

    do {
        try VNImageRequestHandler(cgImage: cgImage).perform([request])
        let observations = request.results ?? []
        return observations.compactMap(\.payloadStringValue)
    } catch {
        return []
    }
}
