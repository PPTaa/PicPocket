import Foundation
import SwiftData

@MainActor
final class RepositoryContainer {
    static let shared = RepositoryContainer()

    let modelContainer: ModelContainer

    private init() {
        modelContainer = try! ModelContainer(
            for: CapturedImageRecord.self, ScanSessionRecord.self
        )
    }
}

extension CapturedImageRepository {
    static let live = CapturedImageRepository(
        upsert: { image in
            try await MainActor.run {
                let context = RepositoryContainer.shared.modelContainer.mainContext
                let id = image.assetLocalIdentifier
                let descriptor = FetchDescriptor<CapturedImageRecord>(
                    predicate: #Predicate { $0.assetLocalIdentifier == id }
                )

                if let existing = try context.fetch(descriptor).first {
                    existing.updateAnalysis(from: image)
                } else {
                    context.insert(CapturedImageRecord(image: image))
                }

                try context.save()
            }
        },
        all: {
            try await MainActor.run {
                let context = RepositoryContainer.shared.modelContainer.mainContext
                let descriptor = FetchDescriptor<CapturedImageRecord>(
                    sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
                )
                return try context.fetch(descriptor).map(\.domain)
            }
        },
        items: { category in
            try await MainActor.run {
                let context = RepositoryContainer.shared.modelContainer.mainContext
                let rawValue = category.rawValue
                let descriptor = FetchDescriptor<CapturedImageRecord>(
                    predicate: #Predicate { $0.categoryRawValue == rawValue },
                    sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
                )
                return try context.fetch(descriptor).map(\.domain)
            }
        },
        search: { query in
            try await MainActor.run {
                let context = RepositoryContainer.shared.modelContainer.mainContext
                let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !normalized.isEmpty else { return [] }
                let descriptor = FetchDescriptor<CapturedImageRecord>(
                    sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
                )
                let all = try context.fetch(descriptor).map(\.domain)
                return all.filter {
                    $0.recognizedText.lowercased().contains(normalized)
                        || $0.category.title.lowercased().contains(normalized)
                }
            }
        },
        updateCategory: { localIdentifier, category in
            try await MainActor.run {
                let context = RepositoryContainer.shared.modelContainer.mainContext
                let descriptor = FetchDescriptor<CapturedImageRecord>(
                    predicate: #Predicate { $0.assetLocalIdentifier == localIdentifier }
                )
                guard let record = try context.fetch(descriptor).first else { return }
                record.categoryRawValue = category.rawValue
                record.reviewStatusRawValue = ReviewStatus.changedByUser.rawValue
                record.isSensitive = category.isSensitive
                try context.save()
            }
        },
        saveScanSession: { summary in
            try await MainActor.run {
                let context = RepositoryContainer.shared.modelContainer.mainContext
                context.insert(ScanSessionRecord(summary: summary))
                try context.save()
            }
        }
    )
}
