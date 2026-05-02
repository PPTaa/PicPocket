import XCTest
@testable import PicPocket

final class DomainTests: XCTestCase {
    func testCategoryTitles() {
        XCTAssertEqual(CaptureCategory.coupon.title, "쿠폰")
        XCTAssertEqual(CaptureCategory.receipt.title, "영수증")
        XCTAssertEqual(CaptureCategory.delivery.title, "배송")
        XCTAssertEqual(CaptureCategory.ticketReservation.title, "티켓/예약")
        XCTAssertEqual(CaptureCategory.addressMap.title, "주소/지도")
        XCTAssertEqual(CaptureCategory.payment.title, "계좌/결제")
        XCTAssertEqual(CaptureCategory.unknown.title, "미분류")
    }

    func testPaymentIsSensitive() {
        XCTAssertTrue(CaptureCategory.payment.isSensitive)
        XCTAssertFalse(CaptureCategory.coupon.isSensitive)
    }
}
