import Foundation

extension ClassificationClient {
    static let live = ClassificationClient { analysis, _ in
        let text = analysis.recognizedText.lowercased()
        var scores: [CaptureCategory: Int] = [:]
        var reasons: [CaptureCategory: [String]] = [:]

        func add(_ category: CaptureCategory, _ keywords: [String]) {
            for keyword in keywords where text.contains(keyword.lowercased()) {
                scores[category, default: 0] += 1
                reasons[category, default: []].append(keyword)
            }
        }

        add(.coupon, ["쿠폰", "할인", "적립", "유효기간", "만료", "coupon", "discount"])
        add(.receipt, ["영수증", "합계", "총액", "승인번호", "주문번호", "receipt", "total"])
        add(.delivery, ["배송", "택배", "운송장", "송장번호", "배송조회", "출고", "tracking"])
        add(.ticketReservation, ["티켓", "예매", "예약", "좌석", "탑승권", "체크인", "게이트", "booking"])
        add(.addressMap, ["주소", "지도", "길찾기", "도로명", "위치", "map", "address"])
        add(.payment, ["계좌", "이체", "입금", "은행", "카드", "결제", "account", "bank"])

        if analysis.hasBarcodeOrQRCode {
            scores[.coupon, default: 0] += 2
            reasons[.coupon, default: []].append("QR/바코드")
            scores[.ticketReservation, default: 0] += 1
            reasons[.ticketReservation, default: []].append("QR/바코드")
        }

        guard let best = scores.max(by: { $0.value < $1.value }) else {
            return ClassificationResult(category: .unknown, confidence: 0, reason: "분류 신호 없음", isSensitive: false)
        }

        let confidence = min(Double(best.value) / 6.0, 1.0)
        guard confidence >= 0.55 else {
            return ClassificationResult(category: .unknown, confidence: confidence, reason: "분류 신뢰도 낮음", isSensitive: false)
        }

        return ClassificationResult(
            category: best.key,
            confidence: confidence,
            reason: reasons[best.key, default: []].joined(separator: ", "),
            isSensitive: best.key.isSensitive
        )
    }
}
