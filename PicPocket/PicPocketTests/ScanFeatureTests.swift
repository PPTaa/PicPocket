import ComposableArchitecture
import UIKit
import XCTest
@testable import PicPocket

@MainActor
final class ScanFeatureTests: XCTestCase {
    func testRecentYearScanUsesCandidatesSourceKindAndSaves() async {
        let candidate = PhotoAssetCandidate(
            id: "asset-1",
            sourceKind: .savedImageCandidate,
            creationDate: Date(timeIntervalSince1970: 10),
            addedDate: Date(timeIntervalSince1970: 11)
        )
        var saved: [CapturedImage] = []

        let store = TestStore(initialState: ScanFeature.State()) {
            ScanFeature()
        } withDependencies: {
            $0.photoLibraryClient.fetchCandidates = { range in
                XCTAssertEqual(range, .recentYear)
                return [candidate]
            }
            $0.photoLibraryClient.requestImage = { _, _ in UIImage() }
            $0.visionClient.analyze = { _ in
                VisionAnalysisResult(
                    recognizedText: "쿠폰 할인 유효기간",
                    detectedCodes: ["QR"],
                    hasBarcodeOrQRCode: true
                )
            }
            $0.classificationClient.classify = { analysis, sourceKind in
                XCTAssertEqual(sourceKind, .savedImageCandidate)
                XCTAssertEqual(analysis.recognizedText, "쿠폰 할인 유효기간")
                return ClassificationResult(category: .coupon, confidence: 0.9, reason: "test", isSensitive: false)
            }
            $0.capturedImageRepository.upsert = { image in
                saved.append(image)
            }
            $0.capturedImageRepository.saveScanSession = { _ in }
        }
        store.exhaustivity = .off

        await store.send(.startButtonTapped(.recentYear)) {
            $0.range = .recentYear
            $0.progress.phase = .findingImages
        }
        await store.receive(.candidatesResponse(.success([candidate]))) {
            $0.progress.phase = .analyzing
            $0.progress.candidateCount = 1
        }
        await store.receive(.imageProcessed(saved[0])) {
            $0.progress.analyzedCount = 1
            $0.progress.classifiedCount = 1
        }

        XCTAssertEqual(saved.first?.sourceKind, .savedImageCandidate)
        XCTAssertEqual(saved.first?.category, .coupon)
    }
}
