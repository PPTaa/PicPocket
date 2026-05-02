import Photos
import UIKit

extension PhotoLibraryClient {
    static let live = PhotoLibraryClient(
        authorizationStatus: {
            PHPhotoLibrary.authorizationStatus(for: .readWrite)
        },
        requestAuthorization: {
            await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        },
        fetchCandidates: { range in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = predicate(for: range)

            let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var screenshots: [PhotoAssetCandidate] = []
            var savedImages: [PhotoAssetCandidate] = []

            result.enumerateObjects { asset, _, _ in
                let candidate = PhotoAssetCandidate(
                    id: asset.localIdentifier,
                    sourceKind: asset.mediaSubtypes.contains(.photoScreenshot) ? .screenshot : .savedImageCandidate,
                    creationDate: asset.creationDate,
                    addedDate: asset.creationDate
                )

                if asset.mediaSubtypes.contains(.photoScreenshot) {
                    screenshots.append(candidate)
                } else if asset.mediaSubtypes.isEmpty, asset.pixelWidth >= 600, asset.pixelHeight >= 600 {
                    savedImages.append(candidate)
                }
            }

            return screenshots + savedImages
        },
        requestImage: { localIdentifier, targetSize in
            await withCheckedContinuation { continuation in
                let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
                guard let asset = result.firstObject else {
                    continuation.resume(returning: nil)
                    return
                }

                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .fast
                options.isNetworkAccessAllowed = true

                PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFit,
                    options: options
                ) { image, info in
                    if let degraded = info?[PHImageResultIsDegradedKey] as? Bool, degraded {
                        return
                    }
                    continuation.resume(returning: image)
                }
            }
        },
        presentLimitedLibraryPicker: {
            await MainActor.run {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
        }
    )
}

nonisolated private func predicate(for range: ScanRange) -> NSPredicate {
    let mediaPredicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
    guard range == .recentYear,
          let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) else {
        return mediaPredicate
    }
    let datePredicate = NSPredicate(format: "creationDate >= %@", startDate as NSDate)
    return NSCompoundPredicate(andPredicateWithSubpredicates: [mediaPredicate, datePredicate])
}
