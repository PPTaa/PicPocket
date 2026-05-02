import ComposableArchitecture
import Foundation
import UIKit

struct ScanFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var range: ScanRange = .recentYear
        var progress = ScanProgress()
        var summary: ScanSessionSummary?
        var errorMessage: String?
        var isScanning: Bool {
            progress.phase == .findingImages || progress.phase == .analyzing || progress.phase == .saving
        }
    }

    enum Action: Equatable {
        case rangeSelected(ScanRange)
        case startButtonTapped(ScanRange)
        case candidatesResponse(Result<[PhotoAssetCandidate], EquatableError>)
        case imageProcessed(CapturedImage)
        case scanCompleted(Date)
        case scanFailed(String)
        case cancelButtonTapped
    }

    @Dependency(\.photoLibraryClient) var photoLibraryClient
    @Dependency(\.visionClient) var visionClient
    @Dependency(\.classificationClient) var classificationClient
    @Dependency(\.capturedImageRepository) var repository
    @Dependency(\.date.now) var now

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
            case let .rangeSelected(range):
                state.range = range
                return .none

            case let .startButtonTapped(range):
                state.range = range
                state.errorMessage = nil
                state.summary = nil
                state.progress = ScanProgress(phase: .findingImages)
                return .run { send in
                    do {
                        await send(.candidatesResponse(.success(try await photoLibraryClient.fetchCandidates(range))))
                    } catch {
                        await send(.candidatesResponse(.failure(EquatableError(error.localizedDescription))))
                    }
                }

            case let .candidatesResponse(.success(candidates)):
                state.progress.phase = candidates.isEmpty ? .completed : .analyzing
                state.progress.candidateCount = candidates.count
                guard !candidates.isEmpty else {
                    state.summary = ScanSessionSummary(
                        range: state.range,
                        startedAt: now,
                        finishedAt: now,
                        candidateCount: 0,
                        analyzedCount: 0,
                        classifiedCount: 0,
                        unknownCount: 0,
                        cancelled: false
                    )
                    return .none
                }
                let range = state.range
                let startedAt = now
                let classify = classificationClient.classify
                return .run { send in
                    for candidate in candidates {
                        guard let image = await photoLibraryClient.requestImage(candidate.id, CGSize(width: 1024, height: 1024)) else {
                            continue
                        }
                        let analysis = await visionClient.analyze(image)
                        let classification = classify(analysis, candidate.sourceKind)
                        let capturedImage = CapturedImage(
                            assetLocalIdentifier: candidate.id,
                            sourceKind: candidate.sourceKind,
                            creationDate: candidate.creationDate,
                            addedDate: candidate.addedDate,
                            recognizedText: analysis.recognizedText,
                            detectedCodes: analysis.detectedCodes,
                            category: classification.category,
                            confidence: classification.confidence,
                            reviewStatus: .new,
                            isSensitive: classification.isSensitive,
                            lastAnalyzedAt: Date()
                        )
                        try await repository.upsert(capturedImage)
                        await send(.imageProcessed(capturedImage))
                    }
                    try await repository.saveScanSession(
                        ScanSessionSummary(
                            range: range,
                            startedAt: startedAt,
                            finishedAt: Date(),
                            candidateCount: candidates.count,
                            analyzedCount: candidates.count,
                            classifiedCount: 0,
                            unknownCount: 0,
                            cancelled: false
                        )
                    )
                    await send(.scanCompleted(Date()))
                } catch: { error, send in
                    await send(.scanFailed(error.localizedDescription))
                }

            case let .candidatesResponse(.failure(error)):
                state.progress.phase = .failed(error.message)
                state.errorMessage = error.message
                return .none

            case let .imageProcessed(image):
                state.progress.analyzedCount += 1
                if image.category == .unknown {
                    state.progress.unknownCount += 1
                } else {
                    state.progress.classifiedCount += 1
                }
                return .none

            case let .scanCompleted(finishedAt):
                state.progress.phase = .completed
                state.summary = ScanSessionSummary(
                    range: state.range,
                    startedAt: finishedAt,
                    finishedAt: finishedAt,
                    candidateCount: state.progress.candidateCount,
                    analyzedCount: state.progress.analyzedCount,
                    classifiedCount: state.progress.classifiedCount,
                    unknownCount: state.progress.unknownCount,
                    cancelled: false
                )
                return .none

            case .scanFailed(let message):
                state.progress.phase = .failed(message)
                state.errorMessage = message
                return .none

            case .cancelButtonTapped:
                state.progress.phase = .cancelled
                state.summary = ScanSessionSummary(
                    range: state.range,
                    startedAt: now,
                    finishedAt: now,
                    candidateCount: state.progress.candidateCount,
                    analyzedCount: state.progress.analyzedCount,
                    classifiedCount: state.progress.classifiedCount,
                    unknownCount: state.progress.unknownCount,
                    cancelled: true
                )
                return .none
        }
    }
}
