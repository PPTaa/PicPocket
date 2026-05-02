import ComposableArchitecture
import Foundation

struct CapturedImageRepository: Sendable {
    var upsert: @Sendable (_ image: CapturedImage) async throws -> Void
    var all: @Sendable () async throws -> [CapturedImage]
    var items: @Sendable (_ category: CaptureCategory) async throws -> [CapturedImage]
    var search: @Sendable (_ query: String) async throws -> [CapturedImage]
    var updateCategory: @Sendable (_ assetLocalIdentifier: String, _ category: CaptureCategory) async throws -> Void
    var saveScanSession: @Sendable (_ session: ScanSessionSummary) async throws -> Void
}

struct ScanSessionSummary: Equatable, Sendable {
    var range: ScanRange
    var startedAt: Date
    var finishedAt: Date
    var candidateCount: Int
    var analyzedCount: Int
    var classifiedCount: Int
    var unknownCount: Int
    var cancelled: Bool
}

extension CapturedImageRepository: DependencyKey {
    static let liveValue = CapturedImageRepository.live
    static let testValue = CapturedImageRepository(
        upsert: { _ in },
        all: { [] },
        items: { _ in [] },
        search: { _ in [] },
        updateCategory: { _, _ in },
        saveScanSession: { _ in }
    )
}

extension DependencyValues {
    var capturedImageRepository: CapturedImageRepository {
        get { self[CapturedImageRepository.self] }
        set { self[CapturedImageRepository.self] = newValue }
    }
}
