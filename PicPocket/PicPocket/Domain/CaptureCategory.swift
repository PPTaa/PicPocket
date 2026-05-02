import Foundation

enum CaptureCategory: String, CaseIterable, Codable, Equatable, Identifiable {
    case coupon
    case receipt
    case delivery
    case ticketReservation
    case addressMap
    case payment
    case unknown

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .coupon: "쿠폰"
        case .receipt: "영수증"
        case .delivery: "배송"
        case .ticketReservation: "티켓/예약"
        case .addressMap: "주소/지도"
        case .payment: "계좌/결제"
        case .unknown: "미분류"
        }
    }

    nonisolated var isSensitive: Bool {
        self == .payment
    }
}
