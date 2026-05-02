import Foundation
import SwiftData

@Model
final class CapturedImageRecord {
    @Attribute(.unique) var assetLocalIdentifier: String
    var sourceKindRawValue: String
    var creationDate: Date?
    var addedDate: Date?
    var recognizedText: String
    var detectedCodes: [String]
    var categoryRawValue: String
    var confidence: Double
    var reviewStatusRawValue: String
    var isSensitive: Bool
    var lastAnalyzedAt: Date

    init(image: CapturedImage) {
        assetLocalIdentifier = image.assetLocalIdentifier
        sourceKindRawValue = image.sourceKind.rawValue
        creationDate = image.creationDate
        addedDate = image.addedDate
        recognizedText = image.recognizedText
        detectedCodes = image.detectedCodes
        categoryRawValue = image.category.rawValue
        confidence = image.confidence
        reviewStatusRawValue = image.reviewStatus.rawValue
        isSensitive = image.isSensitive
        lastAnalyzedAt = image.lastAnalyzedAt
    }

    var domain: CapturedImage {
        CapturedImage(
            assetLocalIdentifier: assetLocalIdentifier,
            sourceKind: CaptureSourceKind(rawValue: sourceKindRawValue) ?? .savedImageCandidate,
            creationDate: creationDate,
            addedDate: addedDate,
            recognizedText: recognizedText,
            detectedCodes: detectedCodes,
            category: CaptureCategory(rawValue: categoryRawValue) ?? .unknown,
            confidence: confidence,
            reviewStatus: ReviewStatus(rawValue: reviewStatusRawValue) ?? .new,
            isSensitive: isSensitive,
            lastAnalyzedAt: lastAnalyzedAt
        )
    }

    func updateAnalysis(from image: CapturedImage) {
        sourceKindRawValue = image.sourceKind.rawValue
        creationDate = image.creationDate
        addedDate = image.addedDate
        recognizedText = image.recognizedText
        detectedCodes = image.detectedCodes
        if reviewStatusRawValue != ReviewStatus.changedByUser.rawValue {
            categoryRawValue = image.category.rawValue
            confidence = image.confidence
            isSensitive = image.isSensitive
        }
        lastAnalyzedAt = image.lastAnalyzedAt
    }
}
