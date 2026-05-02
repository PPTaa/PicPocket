import ComposableArchitecture
import Foundation
import Photos
import UIKit

struct PhotoLibraryClient: Sendable {
    var authorizationStatus: @Sendable () -> PHAuthorizationStatus
    var requestAuthorization: @Sendable () async -> PHAuthorizationStatus
    var fetchCandidates: @Sendable (_ range: ScanRange) async throws -> [PhotoAssetCandidate]
    var requestImage: @Sendable (_ localIdentifier: String, _ targetSize: CGSize) async -> UIImage?
    var presentLimitedLibraryPicker: @Sendable () async -> Void
}

extension PhotoLibraryClient: DependencyKey {
    static let liveValue = PhotoLibraryClient.live
    static let testValue = PhotoLibraryClient(
        authorizationStatus: { .authorized },
        requestAuthorization: { .authorized },
        fetchCandidates: { _ in [] },
        requestImage: { _, _ in nil },
        presentLimitedLibraryPicker: {}
    )
}

extension DependencyValues {
    var photoLibraryClient: PhotoLibraryClient {
        get { self[PhotoLibraryClient.self] }
        set { self[PhotoLibraryClient.self] = newValue }
    }
}
