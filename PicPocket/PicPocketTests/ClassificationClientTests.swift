import XCTest
@testable import PicPocket

final class ClassificationClientTests: XCTestCase {
    func testCouponWithQRCode() {
        let client = ClassificationClient.live
        let result = client.classify(
            VisionAnalysisResult(
                recognizedText: "스타벅스 쿠폰 할인 유효기간 2026.05.31",
                detectedCodes: ["QR"],
                hasBarcodeOrQRCode: true
            ),
            .screenshot
        )

        XCTAssertEqual(result.category, .coupon)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.55)
        XCTAssertFalse(result.isSensitive)
    }

    func testPaymentIsSensitive() {
        let client = ClassificationClient.live
        let result = client.classify(
            VisionAnalysisResult(
                recognizedText: "국민은행 계좌 이체 입금 결제",
                detectedCodes: [],
                hasBarcodeOrQRCode: false
            ),
            .screenshot
        )

        XCTAssertEqual(result.category, .payment)
        XCTAssertTrue(result.isSensitive)
    }
}
