# CaptureBox MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** iOS 18 SwiftUI 앱 `CaptureBox`를 만들어 최근 1년의 스크린샷과 저장 이미지 후보를 온디바이스로 분석하고, 앱 내부 보관함에서 6개 카테고리와 미분류로 자동 정리한다.

**Architecture:** 앱은 SwiftUI 화면, ViewModel, 서비스, 로컬 저장소로 나눈다. PhotoKit은 후보 이미지 수집과 썸네일/원본 요청만 담당하고, Vision은 OCR/QR/바코드 분석만 담당하며, 분류는 순수 Swift 규칙 엔진으로 테스트 가능하게 만든다. MVP에서는 Photos 원본 수정, 광고, 서버 업로드, Gemma 4 E2B를 제외한다.

**Tech Stack:** Swift 6, SwiftUI, Photos/PhotoKit, Vision, SwiftData, XCTest, iOS 18, Xcode 16 이상.

---

## 파일 구조

새 Xcode 프로젝트 루트는 `CaptureBox/`로 둔다.

- Create: `CaptureBox/CaptureBoxApp.swift` - 앱 진입점과 SwiftData 컨테이너 연결
- Create: `CaptureBox/App/AppState.swift` - 온보딩, 권한, 스캔 완료 여부 같은 앱 전역 상태
- Create: `CaptureBox/Models/CaptureCategory.swift` - MVP 카테고리 enum
- Create: `CaptureBox/Models/CapturedImageItem.swift` - 분석된 이미지 모델
- Create: `CaptureBox/Models/ScanSession.swift` - 스캔 세션 모델
- Create: `CaptureBox/Models/VisionAnalysisResult.swift` - OCR/코드 감지 결과
- Create: `CaptureBox/Services/ClassificationService.swift` - 규칙 기반 분류 엔진
- Create: `CaptureBox/Services/PhotoLibraryService.swift` - PhotoKit 권한과 이미지 fetch
- Create: `CaptureBox/Services/VisionAnalysisService.swift` - Vision OCR/코드 분석
- Create: `CaptureBox/Services/LocalStore.swift` - SwiftData 저장/조회
- Create: `CaptureBox/Services/ScanCoordinator.swift` - 스캔 진행, 취소, 저장 조율
- Create: `CaptureBox/ViewModels/OnboardingViewModel.swift`
- Create: `CaptureBox/ViewModels/ScanViewModel.swift`
- Create: `CaptureBox/ViewModels/LibraryViewModel.swift`
- Create: `CaptureBox/ViewModels/SearchViewModel.swift`
- Create: `CaptureBox/Views/RootView.swift`
- Create: `CaptureBox/Views/OnboardingView.swift`
- Create: `CaptureBox/Views/ScanProgressView.swift`
- Create: `CaptureBox/Views/ScanSummaryView.swift`
- Create: `CaptureBox/Views/LibraryView.swift`
- Create: `CaptureBox/Views/CategoryDetailView.swift`
- Create: `CaptureBox/Views/ImageDetailView.swift`
- Create: `CaptureBox/Views/SearchView.swift`
- Create: `CaptureBox/Views/SettingsView.swift`
- Create: `CaptureBox/Resources/InfoPlist.strings` - 권한 문구
- Create: `CaptureBoxTests/ClassificationServiceTests.swift`
- Create: `CaptureBoxTests/SearchIndexTests.swift`
- Create: `CaptureBoxTests/ScanCoordinatorTests.swift`

---

### Task 1: Xcode 프로젝트 생성과 기본 설정

**Files:**
- Create: `CaptureBox.xcodeproj`
- Create: `CaptureBox/CaptureBoxApp.swift`
- Create: `CaptureBox/Views/RootView.swift`
- Create: `CaptureBox/Resources/InfoPlist.strings`
- Test: Xcode build

- [ ] **Step 1: Xcode에서 iOS App 프로젝트 생성**

Run in Xcode:

```text
File > New > Project > iOS > App
Product Name: CaptureBox
Team: 개인/조직 개발자 팀
Organization Identifier: com.capturebox
Interface: SwiftUI
Language: Swift
Testing System: XCTest
Minimum Deployments: iOS 18.0
```

Expected: `CaptureBox.xcodeproj`, `CaptureBox/`, `CaptureBoxTests/`가 생성된다.

- [ ] **Step 2: 권한 문구 추가**

Xcode target `CaptureBox`의 Info 설정에 아래 키를 추가한다.

```text
Privacy - Photo Library Usage Description
스크린샷과 저장 이미지를 기기 안에서 분석해 자동으로 정리하기 위해 사진 접근 권한이 필요합니다.

Privacy - Photo Library Additions Usage Description
향후 사용자가 요청할 때 Photos 앨범을 만들기 위해 필요할 수 있습니다. MVP에서는 사진 앱을 수정하지 않습니다.
```

Expected: 사진 권한 요청 시 한국어 목적 문구가 표시된다.

- [ ] **Step 3: 앱 진입점 작성**

Replace `CaptureBox/CaptureBoxApp.swift`:

```swift
import SwiftData
import SwiftUI

@main
struct CaptureBoxApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            CapturedImageItem.self,
            ScanSession.self
        ])
    }
}
```

- [ ] **Step 4: 임시 RootView 작성**

Replace `CaptureBox/Views/RootView.swift`:

```swift
import SwiftUI

struct RootView: View {
    var body: some View {
        Text("CaptureBox")
            .font(.title)
            .padding()
    }
}

#Preview {
    RootView()
}
```

- [ ] **Step 5: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add CaptureBox.xcodeproj CaptureBox CaptureBoxTests
git commit -m "chore: create CaptureBox iOS project"
```

---

### Task 2: 핵심 모델 정의

**Files:**
- Create: `CaptureBox/Models/CaptureCategory.swift`
- Create: `CaptureBox/Models/VisionAnalysisResult.swift`
- Create: `CaptureBox/Models/CapturedImageItem.swift`
- Create: `CaptureBox/Models/ScanSession.swift`
- Test: `CaptureBoxTests/ModelTests.swift`

- [ ] **Step 1: 모델 테스트 작성**

Create `CaptureBoxTests/ModelTests.swift`:

```swift
import XCTest
@testable import CaptureBox

final class ModelTests: XCTestCase {
    func testCategoryKoreanTitles() {
        XCTAssertEqual(CaptureCategory.coupon.title, "쿠폰")
        XCTAssertEqual(CaptureCategory.payment.title, "계좌/결제")
        XCTAssertEqual(CaptureCategory.unknown.title, "미분류")
    }

    func testPaymentCategoryIsSensitive() {
        XCTAssertTrue(CaptureCategory.payment.isSensitive)
        XCTAssertFalse(CaptureCategory.coupon.isSensitive)
    }
}
```

- [ ] **Step 2: 실패 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/ModelTests
```

Expected: `Cannot find 'CaptureCategory' in scope`

- [ ] **Step 3: 카테고리 모델 작성**

Create `CaptureBox/Models/CaptureCategory.swift`:

```swift
import Foundation

enum CaptureCategory: String, CaseIterable, Codable, Identifiable {
    case coupon
    case receipt
    case delivery
    case ticketReservation
    case addressMap
    case payment
    case unknown

    var id: String { rawValue }

    var title: String {
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

    var isSensitive: Bool {
        self == .payment
    }
}
```

- [ ] **Step 4: 분석 결과 모델 작성**

Create `CaptureBox/Models/VisionAnalysisResult.swift`:

```swift
import Foundation

struct VisionAnalysisResult: Equatable, Codable {
    var recognizedText: String
    var detectedCodes: [String]
    var hasBarcodeOrQRCode: Bool

    static let empty = VisionAnalysisResult(
        recognizedText: "",
        detectedCodes: [],
        hasBarcodeOrQRCode: false
    )
}
```

- [ ] **Step 5: SwiftData 이미지 모델 작성**

Create `CaptureBox/Models/CapturedImageItem.swift`:

```swift
import Foundation
import SwiftData

enum CaptureSourceKind: String, Codable {
    case screenshot
    case savedImageCandidate
    case manualSelection
}

enum ReviewStatus: String, Codable {
    case new
    case confirmed
    case changedByUser
    case ignored
}

@Model
final class CapturedImageItem {
    @Attribute(.unique) var assetLocalIdentifier: String
    var sourceKindRawValue: String
    var creationDate: Date?
    var addedDate: Date?
    var thumbnailCacheKey: String
    var recognizedText: String
    var detectedCodes: [String]
    var categoryRawValue: String
    var confidence: Double
    var reviewStatusRawValue: String
    var isSensitive: Bool
    var lastAnalyzedAt: Date

    init(
        assetLocalIdentifier: String,
        sourceKind: CaptureSourceKind,
        creationDate: Date?,
        addedDate: Date?,
        thumbnailCacheKey: String,
        recognizedText: String,
        detectedCodes: [String],
        category: CaptureCategory,
        confidence: Double,
        reviewStatus: ReviewStatus,
        isSensitive: Bool,
        lastAnalyzedAt: Date
    ) {
        self.assetLocalIdentifier = assetLocalIdentifier
        self.sourceKindRawValue = sourceKind.rawValue
        self.creationDate = creationDate
        self.addedDate = addedDate
        self.thumbnailCacheKey = thumbnailCacheKey
        self.recognizedText = recognizedText
        self.detectedCodes = detectedCodes
        self.categoryRawValue = category.rawValue
        self.confidence = confidence
        self.reviewStatusRawValue = reviewStatus.rawValue
        self.isSensitive = isSensitive
        self.lastAnalyzedAt = lastAnalyzedAt
    }

    var sourceKind: CaptureSourceKind {
        CaptureSourceKind(rawValue: sourceKindRawValue) ?? .savedImageCandidate
    }

    var category: CaptureCategory {
        CaptureCategory(rawValue: categoryRawValue) ?? .unknown
    }

    var reviewStatus: ReviewStatus {
        ReviewStatus(rawValue: reviewStatusRawValue) ?? .new
    }

    func updateCategory(_ category: CaptureCategory) {
        categoryRawValue = category.rawValue
        reviewStatusRawValue = ReviewStatus.changedByUser.rawValue
        isSensitive = category.isSensitive
    }
}
```

- [ ] **Step 6: SwiftData 스캔 세션 모델 작성**

Create `CaptureBox/Models/ScanSession.swift`:

```swift
import Foundation
import SwiftData

enum ScanRange: String, Codable {
    case recentYear
    case allTime
}

@Model
final class ScanSession {
    var id: UUID
    var rangeRawValue: String
    var startedAt: Date
    var finishedAt: Date?
    var candidateCount: Int
    var analyzedCount: Int
    var classifiedCount: Int
    var unknownCount: Int
    var cancelled: Bool

    init(
        id: UUID = UUID(),
        range: ScanRange,
        startedAt: Date = Date(),
        finishedAt: Date? = nil,
        candidateCount: Int = 0,
        analyzedCount: Int = 0,
        classifiedCount: Int = 0,
        unknownCount: Int = 0,
        cancelled: Bool = false
    ) {
        self.id = id
        self.rangeRawValue = range.rawValue
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.candidateCount = candidateCount
        self.analyzedCount = analyzedCount
        self.classifiedCount = classifiedCount
        self.unknownCount = unknownCount
        self.cancelled = cancelled
    }

    var range: ScanRange {
        ScanRange(rawValue: rangeRawValue) ?? .recentYear
    }
}
```

- [ ] **Step 7: 테스트 통과 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/ModelTests
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 8: Commit**

```bash
git add CaptureBox/Models CaptureBoxTests/ModelTests.swift
git commit -m "feat: add capture data models"
```

---

### Task 3: 규칙 기반 분류 엔진

**Files:**
- Create: `CaptureBox/Services/ClassificationService.swift`
- Test: `CaptureBoxTests/ClassificationServiceTests.swift`

- [ ] **Step 1: 실패하는 분류 테스트 작성**

Create `CaptureBoxTests/ClassificationServiceTests.swift`:

```swift
import XCTest
@testable import CaptureBox

final class ClassificationServiceTests: XCTestCase {
    let service = ClassificationService()

    func testClassifiesCoupon() {
        let result = service.classify(
            analysis: VisionAnalysisResult(
                recognizedText: "스타벅스 쿠폰 할인 유효기간 2026.05.31",
                detectedCodes: ["QR"],
                hasBarcodeOrQRCode: true
            ),
            sourceKind: .screenshot
        )

        XCTAssertEqual(result.category, .coupon)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.7)
        XCTAssertFalse(result.isSensitive)
    }

    func testClassifiesDelivery() {
        let result = service.classify(
            analysis: VisionAnalysisResult(
                recognizedText: "택배 배송조회 운송장번호 1234567890 출고 완료",
                detectedCodes: [],
                hasBarcodeOrQRCode: false
            ),
            sourceKind: .savedImageCandidate
        )

        XCTAssertEqual(result.category, .delivery)
    }

    func testClassifiesPaymentAsSensitive() {
        let result = service.classify(
            analysis: VisionAnalysisResult(
                recognizedText: "국민은행 계좌 이체 입금 결제",
                detectedCodes: [],
                hasBarcodeOrQRCode: false
            ),
            sourceKind: .screenshot
        )

        XCTAssertEqual(result.category, .payment)
        XCTAssertTrue(result.isSensitive)
    }

    func testLowSignalGoesUnknown() {
        let result = service.classify(
            analysis: VisionAnalysisResult(
                recognizedText: "오늘 메모 참고",
                detectedCodes: [],
                hasBarcodeOrQRCode: false
            ),
            sourceKind: .screenshot
        )

        XCTAssertEqual(result.category, .unknown)
        XCTAssertLessThan(result.confidence, 0.55)
    }
}
```

- [ ] **Step 2: 실패 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/ClassificationServiceTests
```

Expected: `Cannot find 'ClassificationService' in scope`

- [ ] **Step 3: 분류 서비스 작성**

Create `CaptureBox/Services/ClassificationService.swift`:

```swift
import Foundation

struct ClassificationResult: Equatable {
    let category: CaptureCategory
    let confidence: Double
    let reason: String
    let isSensitive: Bool
}

struct ClassificationService {
    private let threshold = 0.55

    func classify(
        analysis: VisionAnalysisResult,
        sourceKind: CaptureSourceKind
    ) -> ClassificationResult {
        let text = analysis.recognizedText.lowercased()
        var scores: [CaptureCategory: Int] = [:]
        var reasons: [CaptureCategory: [String]] = [:]

        addScore(for: .coupon, text: text, keywords: ["쿠폰", "할인", "적립", "유효기간", "만료", "coupon", "discount"], scores: &scores, reasons: &reasons)
        addScore(for: .receipt, text: text, keywords: ["영수증", "합계", "총액", "승인번호", "주문번호", "receipt", "total"], scores: &scores, reasons: &reasons)
        addScore(for: .delivery, text: text, keywords: ["배송", "택배", "운송장", "송장번호", "배송조회", "출고", "tracking", "shipment"], scores: &scores, reasons: &reasons)
        addScore(for: .ticketReservation, text: text, keywords: ["티켓", "예매", "예약", "좌석", "탑승권", "체크인", "게이트", "booking", "ticket"], scores: &scores, reasons: &reasons)
        addScore(for: .addressMap, text: text, keywords: ["주소", "지도", "길찾기", "도로명", "위치", "map", "address"], scores: &scores, reasons: &reasons)
        addScore(for: .payment, text: text, keywords: ["계좌", "이체", "입금", "은행", "카드", "결제", "account", "bank"], scores: &scores, reasons: &reasons)

        if analysis.hasBarcodeOrQRCode {
            scores[.coupon, default: 0] += 2
            reasons[.coupon, default: []].append("QR/바코드 감지")
            scores[.ticketReservation, default: 0] += 1
            reasons[.ticketReservation, default: []].append("QR/바코드 감지")
        }

        guard let best = scores.max(by: { $0.value < $1.value }) else {
            return ClassificationResult(category: .unknown, confidence: 0, reason: "분류 신호 없음", isSensitive: false)
        }

        let confidence = min(Double(best.value) / 6.0, 1.0)
        guard confidence >= threshold else {
            return ClassificationResult(category: .unknown, confidence: confidence, reason: "분류 신뢰도 낮음", isSensitive: false)
        }

        let category = best.key
        return ClassificationResult(
            category: category,
            confidence: confidence,
            reason: reasons[category, default: []].joined(separator: ", "),
            isSensitive: category.isSensitive
        )
    }

    private func addScore(
        for category: CaptureCategory,
        text: String,
        keywords: [String],
        scores: inout [CaptureCategory: Int],
        reasons: inout [CaptureCategory: [String]]
    ) {
        for keyword in keywords where text.contains(keyword.lowercased()) {
            scores[category, default: 0] += 1
            reasons[category, default: []].append(keyword)
        }
    }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/ClassificationServiceTests
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add CaptureBox/Services/ClassificationService.swift CaptureBoxTests/ClassificationServiceTests.swift
git commit -m "feat: add rule based classification"
```

---

### Task 4: PhotoKit 후보 수집 서비스

**Files:**
- Create: `CaptureBox/Services/PhotoLibraryService.swift`
- Test: Build only, manual simulator permission check

- [ ] **Step 1: PhotoKit 서비스 작성**

Create `CaptureBox/Services/PhotoLibraryService.swift`:

```swift
import Foundation
import Photos
import UIKit

struct PhotoAssetCandidate: Identifiable, Equatable {
    let id: String
    let asset: PHAsset
    let sourceKind: CaptureSourceKind

    var creationDate: Date? { asset.creationDate }
    var addedDate: Date? {
        if #available(iOS 16.0, *) {
            return asset.addedDate
        }
        return asset.creationDate
    }
}

@MainActor
final class PhotoLibraryService: ObservableObject {
    @Published private(set) var authorizationStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    func refreshAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        return status
    }

    func presentLimitedLibraryPicker() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let controller = scene.windows.first?.rootViewController else {
            return
        }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: controller)
    }

    nonisolated func fetchCandidates(range: ScanRange) -> [PhotoAssetCandidate] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = predicate(for: range)

        let screenshots = fetchScreenshots(options: options)
        let savedCandidates = fetchSavedImageCandidates(options: options, excluding: Set(screenshots.map(\.id)))

        return screenshots + savedCandidates
    }

    nonisolated func requestImage(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    private nonisolated func predicate(for range: ScanRange) -> NSPredicate {
        let mediaPredicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        guard range == .recentYear,
              let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) else {
            return mediaPredicate
        }
        let datePredicate = NSPredicate(format: "creationDate >= %@", startDate as NSDate)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [mediaPredicate, datePredicate])
    }

    private nonisolated func fetchScreenshots(options: PHFetchOptions) -> [PhotoAssetCandidate] {
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var candidates: [PhotoAssetCandidate] = []
        result.enumerateObjects { asset, _, _ in
            if asset.mediaSubtypes.contains(.photoScreenshot) {
                candidates.append(PhotoAssetCandidate(id: asset.localIdentifier, asset: asset, sourceKind: .screenshot))
            }
        }
        return candidates
    }

    private nonisolated func fetchSavedImageCandidates(options: PHFetchOptions, excluding ids: Set<String>) -> [PhotoAssetCandidate] {
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var candidates: [PhotoAssetCandidate] = []
        result.enumerateObjects { asset, _, _ in
            guard !ids.contains(asset.localIdentifier) else { return }
            guard asset.mediaSubtypes.isEmpty else { return }
            guard asset.pixelWidth >= 600, asset.pixelHeight >= 600 else { return }
            candidates.append(PhotoAssetCandidate(id: asset.localIdentifier, asset: asset, sourceKind: .savedImageCandidate))
        }
        return candidates
    }
}
```

- [ ] **Step 2: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add CaptureBox/Services/PhotoLibraryService.swift
git commit -m "feat: add photo library candidate fetching"
```

---

### Task 5: Vision OCR 및 코드 감지

**Files:**
- Create: `CaptureBox/Services/VisionAnalysisService.swift`
- Test: Build only, manual fixture test with real images

- [ ] **Step 1: Vision 서비스 작성**

Create `CaptureBox/Services/VisionAnalysisService.swift`:

```swift
import Foundation
import UIKit
import Vision

struct VisionAnalysisService {
    func analyze(image: UIImage) async -> VisionAnalysisResult {
        guard let cgImage = image.cgImage else {
            return .empty
        }

        async let text = recognizeText(cgImage: cgImage)
        async let codes = detectCodes(cgImage: cgImage)

        let recognizedText = await text
        let detectedCodes = await codes

        return VisionAnalysisResult(
            recognizedText: recognizedText,
            detectedCodes: detectedCodes,
            hasBarcodeOrQRCode: !detectedCodes.isEmpty
        )
    }

    private func recognizeText(cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["ko-KR", "en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }

    private func detectCodes(cgImage: CGImage) async -> [String] {
        await withCheckedContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, _ in
                let observations = request.results as? [VNBarcodeObservation] ?? []
                let payloads = observations.compactMap(\.payloadStringValue)
                continuation.resume(returning: payloads)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add CaptureBox/Services/VisionAnalysisService.swift
git commit -m "feat: add on device vision analysis"
```

---

### Task 6: 로컬 저장소와 검색

**Files:**
- Create: `CaptureBox/Services/LocalStore.swift`
- Test: `CaptureBoxTests/SearchIndexTests.swift`

- [ ] **Step 1: 검색 테스트 작성**

Create `CaptureBoxTests/SearchIndexTests.swift`:

```swift
import SwiftData
import XCTest
@testable import CaptureBox

@MainActor
final class SearchIndexTests: XCTestCase {
    func testSearchMatchesRecognizedTextAndCategory() throws {
        let container = try ModelContainer(
            for: CapturedImageItem.self, ScanSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let store = LocalStore(modelContext: container.mainContext)

        let item = CapturedImageItem(
            assetLocalIdentifier: "asset-1",
            sourceKind: .screenshot,
            creationDate: Date(),
            addedDate: Date(),
            thumbnailCacheKey: "asset-1",
            recognizedText: "쿠폰 할인 유효기간",
            detectedCodes: [],
            category: .coupon,
            confidence: 0.8,
            reviewStatus: .new,
            isSensitive: false,
            lastAnalyzedAt: Date()
        )

        try store.upsert(item)

        XCTAssertEqual(try store.search(query: "할인").count, 1)
        XCTAssertEqual(try store.search(query: "쿠폰").count, 1)
        XCTAssertEqual(try store.search(query: "배송").count, 0)
    }
}
```

- [ ] **Step 2: 실패 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/SearchIndexTests
```

Expected: `Cannot find 'LocalStore' in scope`

- [ ] **Step 3: LocalStore 작성**

Create `CaptureBox/Services/LocalStore.swift`:

```swift
import Foundation
import SwiftData

@MainActor
final class LocalStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func upsert(_ item: CapturedImageItem) throws {
        let id = item.assetLocalIdentifier
        let descriptor = FetchDescriptor<CapturedImageItem>(
            predicate: #Predicate { $0.assetLocalIdentifier == id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.sourceKindRawValue = item.sourceKindRawValue
            existing.creationDate = item.creationDate
            existing.addedDate = item.addedDate
            existing.thumbnailCacheKey = item.thumbnailCacheKey
            existing.recognizedText = item.recognizedText
            existing.detectedCodes = item.detectedCodes
            if existing.reviewStatus != .changedByUser {
                existing.categoryRawValue = item.categoryRawValue
                existing.confidence = item.confidence
                existing.isSensitive = item.isSensitive
            }
            existing.lastAnalyzedAt = item.lastAnalyzedAt
        } else {
            modelContext.insert(item)
        }

        try modelContext.save()
    }

    func allItems() throws -> [CapturedImageItem] {
        let descriptor = FetchDescriptor<CapturedImageItem>(
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func items(in category: CaptureCategory) throws -> [CapturedImageItem] {
        let rawValue = category.rawValue
        let descriptor = FetchDescriptor<CapturedImageItem>(
            predicate: #Predicate { $0.categoryRawValue == rawValue },
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func search(query: String) throws -> [CapturedImageItem] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return [] }
        return try allItems().filter { item in
            item.recognizedText.lowercased().contains(normalized)
                || item.category.title.lowercased().contains(normalized)
        }
    }

    func updateCategory(assetLocalIdentifier: String, category: CaptureCategory) throws {
        let descriptor = FetchDescriptor<CapturedImageItem>(
            predicate: #Predicate { $0.assetLocalIdentifier == assetLocalIdentifier }
        )
        guard let item = try modelContext.fetch(descriptor).first else { return }
        item.updateCategory(category)
        try modelContext.save()
    }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/SearchIndexTests
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add CaptureBox/Services/LocalStore.swift CaptureBoxTests/SearchIndexTests.swift
git commit -m "feat: add local store and search"
```

---

### Task 7: 스캔 코디네이터

**Files:**
- Create: `CaptureBox/Services/ScanCoordinator.swift`
- Test: `CaptureBoxTests/ScanCoordinatorTests.swift`

- [ ] **Step 1: 스캔 상태 타입 작성**

Create `CaptureBox/Services/ScanCoordinator.swift`:

```swift
import Foundation
import UIKit

enum ScanPhase: Equatable {
    case idle
    case findingImages
    case readingText
    case classifying
    case saving
    case completed
    case cancelled
    case failed(String)

    var title: String {
        switch self {
        case .idle: "대기 중"
        case .findingImages: "이미지 찾는 중"
        case .readingText: "텍스트 읽는 중"
        case .classifying: "분류 중"
        case .saving: "저장 중"
        case .completed: "완료"
        case .cancelled: "취소됨"
        case .failed: "실패"
        }
    }
}

struct ScanProgressState: Equatable {
    var phase: ScanPhase
    var candidateCount: Int
    var analyzedCount: Int
    var classifiedCount: Int
    var unknownCount: Int
}

@MainActor
final class ScanCoordinator: ObservableObject {
    @Published private(set) var progress = ScanProgressState(
        phase: .idle,
        candidateCount: 0,
        analyzedCount: 0,
        classifiedCount: 0,
        unknownCount: 0
    )

    private let photoLibraryService: PhotoLibraryService
    private let visionAnalysisService: VisionAnalysisService
    private let classificationService: ClassificationService
    private let localStore: LocalStore
    private var isCancelled = false

    init(
        photoLibraryService: PhotoLibraryService,
        visionAnalysisService: VisionAnalysisService,
        classificationService: ClassificationService,
        localStore: LocalStore
    ) {
        self.photoLibraryService = photoLibraryService
        self.visionAnalysisService = visionAnalysisService
        self.classificationService = classificationService
        self.localStore = localStore
    }

    func cancel() {
        isCancelled = true
        progress.phase = .cancelled
    }

    func start(range: ScanRange) async {
        isCancelled = false
        progress = ScanProgressState(phase: .findingImages, candidateCount: 0, analyzedCount: 0, classifiedCount: 0, unknownCount: 0)

        let candidates = photoLibraryService.fetchCandidates(range: range)
        progress.candidateCount = candidates.count

        for candidate in candidates {
            if isCancelled { break }
            progress.phase = .readingText

            guard let image = await photoLibraryService.requestImage(
                for: candidate.asset,
                targetSize: CGSize(width: 1600, height: 1600)
            ) else {
                continue
            }

            let analysis = await visionAnalysisService.analyze(image: image)
            progress.phase = .classifying
            let classification = classificationService.classify(analysis: analysis, sourceKind: candidate.sourceKind)

            let item = CapturedImageItem(
                assetLocalIdentifier: candidate.id,
                sourceKind: candidate.sourceKind,
                creationDate: candidate.creationDate,
                addedDate: candidate.addedDate,
                thumbnailCacheKey: candidate.id,
                recognizedText: analysis.recognizedText,
                detectedCodes: analysis.detectedCodes,
                category: classification.category,
                confidence: classification.confidence,
                reviewStatus: .new,
                isSensitive: classification.isSensitive,
                lastAnalyzedAt: Date()
            )

            progress.phase = .saving
            do {
                try localStore.upsert(item)
                progress.analyzedCount += 1
                if classification.category == .unknown {
                    progress.unknownCount += 1
                } else {
                    progress.classifiedCount += 1
                }
            } catch {
                progress.phase = .failed("분석 결과 저장에 실패했습니다.")
                return
            }
        }

        progress.phase = isCancelled ? .cancelled : .completed
    }
}
```

- [ ] **Step 2: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add CaptureBox/Services/ScanCoordinator.swift
git commit -m "feat: add scan coordinator"
```

---

### Task 8: 온보딩과 권한 UI

**Files:**
- Create: `CaptureBox/App/AppState.swift`
- Create: `CaptureBox/ViewModels/OnboardingViewModel.swift`
- Modify: `CaptureBox/Views/RootView.swift`
- Create: `CaptureBox/Views/OnboardingView.swift`

- [ ] **Step 1: AppState 작성**

Create `CaptureBox/App/AppState.swift`:

```swift
import Foundation
import SwiftUI

@Observable
final class AppState {
    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}
```

- [ ] **Step 2: OnboardingViewModel 작성**

Create `CaptureBox/ViewModels/OnboardingViewModel.swift`:

```swift
import Foundation
import Photos

@MainActor
@Observable
final class OnboardingViewModel {
    private let photoLibraryService: PhotoLibraryService
    var authorizationStatus: PHAuthorizationStatus

    init(photoLibraryService: PhotoLibraryService) {
        self.photoLibraryService = photoLibraryService
        authorizationStatus = photoLibraryService.authorizationStatus
    }

    func requestAccess() async {
        authorizationStatus = await photoLibraryService.requestAuthorization()
    }

    var canContinue: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }
}
```

- [ ] **Step 3: OnboardingView 작성**

Create `CaptureBox/Views/OnboardingView.swift`:

```swift
import Photos
import SwiftUI

struct OnboardingView: View {
    @Bindable var appState: AppState
    @State var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            Text("스크린샷과 저장 이미지를\n기기 안에서 정리합니다")
                .font(.largeTitle.bold())

            Text("쿠폰, 영수증, 배송, 예약, 주소, 결제 메모를 자동으로 찾아 앱 내부 보관함에 정리합니다. 사진은 서버로 업로드하지 않습니다.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Label("선택한 사진만 허용해도 사용할 수 있어요", systemImage: "checkmark.circle")
                Label("전체 접근을 허용하면 자동 분류가 더 잘 됩니다", systemImage: "sparkles")
                Label("MVP에서는 Photos 원본을 삭제하거나 이동하지 않습니다", systemImage: "lock.shield")
            }
            .font(.callout)

            Spacer()

            Button {
                Task {
                    await viewModel.requestAccess()
                    if viewModel.canContinue {
                        appState.hasCompletedOnboarding = true
                    }
                }
            } label: {
                Text(buttonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
    }

    private var buttonTitle: String {
        switch viewModel.authorizationStatus {
        case .authorized, .limited: "보관함 시작하기"
        case .denied, .restricted: "사진 권한이 필요합니다"
        case .notDetermined: "사진 접근 허용하기"
        @unknown default: "사진 접근 허용하기"
        }
    }
}
```

- [ ] **Step 4: RootView를 온보딩 라우터로 수정**

Replace `CaptureBox/Views/RootView.swift`:

```swift
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appState = AppState()
    @StateObject private var photoLibraryService = PhotoLibraryService()

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                LibraryView()
            } else {
                OnboardingView(
                    appState: appState,
                    viewModel: OnboardingViewModel(photoLibraryService: photoLibraryService)
                )
            }
        }
    }
}
```

- [ ] **Step 5: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `LibraryView`가 아직 생성되지 않아 실패한다.

- [ ] **Step 6: 임시 LibraryView 작성**

Create `CaptureBox/Views/LibraryView.swift`:

```swift
import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            Text("보관함")
                .navigationTitle("보관함")
        }
    }
}
```

- [ ] **Step 7: 빌드 통과 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Commit**

```bash
git add CaptureBox/App CaptureBox/ViewModels/OnboardingViewModel.swift CaptureBox/Views/RootView.swift CaptureBox/Views/OnboardingView.swift CaptureBox/Views/LibraryView.swift
git commit -m "feat: add onboarding and photo permission flow"
```

---

### Task 9: 스캔 진행과 요약 UI

**Files:**
- Create: `CaptureBox/ViewModels/ScanViewModel.swift`
- Create: `CaptureBox/Views/ScanProgressView.swift`
- Create: `CaptureBox/Views/ScanSummaryView.swift`
- Modify: `CaptureBox/Views/LibraryView.swift`

- [ ] **Step 1: ScanViewModel 작성**

Create `CaptureBox/ViewModels/ScanViewModel.swift`:

```swift
import Foundation

@MainActor
@Observable
final class ScanViewModel {
    private let coordinator: ScanCoordinator
    var progress: ScanProgressState { coordinator.progress }
    var didFinish = false

    init(coordinator: ScanCoordinator) {
        self.coordinator = coordinator
    }

    func startRecentYearScan() {
        Task {
            await coordinator.start(range: .recentYear)
            didFinish = coordinator.progress.phase == .completed
        }
    }

    func startAllTimeScan() {
        Task {
            await coordinator.start(range: .allTime)
            didFinish = coordinator.progress.phase == .completed
        }
    }

    func cancel() {
        coordinator.cancel()
    }
}
```

- [ ] **Step 2: ScanProgressView 작성**

Create `CaptureBox/Views/ScanProgressView.swift`:

```swift
import SwiftUI

struct ScanProgressView: View {
    @State var viewModel: ScanViewModel

    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)

            Text(viewModel.progress.phase.title)
                .font(.title2.bold())

            Text("\(viewModel.progress.analyzedCount) / \(viewModel.progress.candidateCount)개 분석")
                .foregroundStyle(.secondary)

            Button("취소") {
                viewModel.cancel()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .task {
            viewModel.startRecentYearScan()
        }
    }
}
```

- [ ] **Step 3: ScanSummaryView 작성**

Create `CaptureBox/Views/ScanSummaryView.swift`:

```swift
import SwiftUI

struct ScanSummaryView: View {
    let progress: ScanProgressState
    let onOpenLibrary: () -> Void
    let onScanAllTime: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("정리 준비 완료")
                .font(.largeTitle.bold())

            Text("최근 1년에서 \(progress.candidateCount)개 후보를 찾고 \(progress.classifiedCount)개를 분류했어요.")
                .foregroundStyle(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    Text("분류됨")
                    Text("\(progress.classifiedCount)")
                }
                GridRow {
                    Text("미분류")
                    Text("\(progress.unknownCount)")
                }
                GridRow {
                    Text("분석됨")
                    Text("\(progress.analyzedCount)")
                }
            }

            Spacer()

            Button("보관함으로 이동", action: onOpenLibrary)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            Button("전체 기간 스캔", action: onScanAllTime)
                .buttonStyle(.bordered)
        }
        .padding(24)
    }
}
```

- [ ] **Step 4: LibraryView에 첫 스캔 버튼 연결**

Replace `CaptureBox/Views/LibraryView.swift`:

```swift
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingScan = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("아직 분석 결과가 없습니다")
                    .font(.title3.bold())
                Text("최근 1년의 스크린샷과 저장 이미지를 기기 안에서 분석해 보관함을 만듭니다.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("첫 스캔 시작") {
                    isShowingScan = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("보관함")
            .sheet(isPresented: $isShowingScan) {
                let photoService = PhotoLibraryService()
                let store = LocalStore(modelContext: modelContext)
                let coordinator = ScanCoordinator(
                    photoLibraryService: photoService,
                    visionAnalysisService: VisionAnalysisService(),
                    classificationService: ClassificationService(),
                    localStore: store
                )
                ScanProgressView(viewModel: ScanViewModel(coordinator: coordinator))
            }
        }
    }
}
```

- [ ] **Step 5: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add CaptureBox/ViewModels/ScanViewModel.swift CaptureBox/Views/ScanProgressView.swift CaptureBox/Views/ScanSummaryView.swift CaptureBox/Views/LibraryView.swift
git commit -m "feat: add scan progress and summary UI"
```

---

### Task 10: 보관함, 카테고리 상세, 이미지 상세

**Files:**
- Create: `CaptureBox/ViewModels/LibraryViewModel.swift`
- Modify: `CaptureBox/Views/LibraryView.swift`
- Create: `CaptureBox/Views/CategoryDetailView.swift`
- Create: `CaptureBox/Views/ImageDetailView.swift`

- [ ] **Step 1: LibraryViewModel 작성**

Create `CaptureBox/ViewModels/LibraryViewModel.swift`:

```swift
import Foundation

@MainActor
@Observable
final class LibraryViewModel {
    private let store: LocalStore
    var items: [CapturedImageItem] = []

    init(store: LocalStore) {
        self.store = store
    }

    func load() {
        items = (try? store.allItems()) ?? []
    }

    func count(for category: CaptureCategory) -> Int {
        items.filter { $0.category == category }.count
    }

    func items(for category: CaptureCategory) -> [CapturedImageItem] {
        items.filter { $0.category == category }
    }
}
```

- [ ] **Step 2: CategoryDetailView 작성**

Create `CaptureBox/Views/CategoryDetailView.swift`:

```swift
import SwiftUI

struct CategoryDetailView: View {
    let category: CaptureCategory
    let items: [CapturedImageItem]

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items, id: \.assetLocalIdentifier) { item in
                    NavigationLink {
                        ImageDetailView(item: item)
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                VStack {
                                    Image(systemName: "photo")
                                    Text(item.category.title)
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                            }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(category.title)
    }
}
```

- [ ] **Step 3: ImageDetailView 작성**

Create `CaptureBox/Views/ImageDetailView.swift`:

```swift
import SwiftUI

struct ImageDetailView: View {
    @Bindable var item: CapturedImageItem

    var body: some View {
        Form {
            Section("분류") {
                Picker("카테고리", selection: Binding(
                    get: { item.category },
                    set: { item.updateCategory($0) }
                )) {
                    ForEach(CaptureCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
            }

            Section("분석 정보") {
                LabeledContent("신뢰도", value: "\(Int(item.confidence * 100))%")
                LabeledContent("민감 정보", value: item.isSensitive ? "예" : "아니오")
                LabeledContent("코드 감지", value: item.detectedCodes.isEmpty ? "없음" : "\(item.detectedCodes.count)개")
            }

            Section("OCR 텍스트") {
                Text(item.recognizedText.isEmpty ? "인식된 텍스트가 없습니다." : item.recognizedText)
                    .textSelection(.enabled)
            }
        }
        .navigationTitle(item.category.title)
    }
}
```

- [ ] **Step 4: LibraryView를 카테고리 카드 목록으로 수정**

Replace `CaptureBox/Views/LibraryView.swift`:

```swift
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingScan = false
    @State private var viewModel: LibraryViewModel?

    var body: some View {
        NavigationStack {
            List {
                ForEach(CaptureCategory.allCases) { category in
                    let count = viewModel?.count(for: category) ?? 0
                    NavigationLink {
                        CategoryDetailView(
                            category: category,
                            items: viewModel?.items(for: category) ?? []
                        )
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(category.title)
                                    .font(.headline)
                                if category.isSensitive {
                                    Text("민감 정보")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("\(count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("보관함")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink("검색") {
                        SearchView()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("스캔") {
                        isShowingScan = true
                    }
                }
            }
            .onAppear {
                let model = LibraryViewModel(store: LocalStore(modelContext: modelContext))
                model.load()
                viewModel = model
            }
            .sheet(isPresented: $isShowingScan, onDismiss: {
                viewModel?.load()
            }) {
                let photoService = PhotoLibraryService()
                let store = LocalStore(modelContext: modelContext)
                let coordinator = ScanCoordinator(
                    photoLibraryService: photoService,
                    visionAnalysisService: VisionAnalysisService(),
                    classificationService: ClassificationService(),
                    localStore: store
                )
                ScanProgressView(viewModel: ScanViewModel(coordinator: coordinator))
            }
        }
    }
}
```

- [ ] **Step 5: 임시 SearchView 작성**

Create `CaptureBox/Views/SearchView.swift`:

```swift
import SwiftUI

struct SearchView: View {
    var body: some View {
        Text("검색")
            .navigationTitle("검색")
    }
}
```

- [ ] **Step 6: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
git add CaptureBox/ViewModels/LibraryViewModel.swift CaptureBox/Views/LibraryView.swift CaptureBox/Views/CategoryDetailView.swift CaptureBox/Views/ImageDetailView.swift CaptureBox/Views/SearchView.swift
git commit -m "feat: add library and detail views"
```

---

### Task 11: OCR 검색 화면

**Files:**
- Create: `CaptureBox/ViewModels/SearchViewModel.swift`
- Modify: `CaptureBox/Views/SearchView.swift`

- [ ] **Step 1: SearchViewModel 작성**

Create `CaptureBox/ViewModels/SearchViewModel.swift`:

```swift
import Foundation

@MainActor
@Observable
final class SearchViewModel {
    private let store: LocalStore
    var query = ""
    var results: [CapturedImageItem] = []

    init(store: LocalStore) {
        self.store = store
    }

    func search() {
        results = (try? store.search(query: query)) ?? []
    }
}
```

- [ ] **Step 2: SearchView 작성**

Replace `CaptureBox/Views/SearchView.swift`:

```swift
import SwiftData
import SwiftUI

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SearchViewModel?

    var body: some View {
        List {
            if let viewModel {
                ForEach(viewModel.results, id: \.assetLocalIdentifier) { item in
                    NavigationLink {
                        ImageDetailView(item: item)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.category.title)
                                .font(.headline)
                            Text(item.recognizedText)
                                .lineLimit(2)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("검색")
        .searchable(text: Binding(
            get: { viewModel?.query ?? "" },
            set: {
                viewModel?.query = $0
                viewModel?.search()
            }
        ), prompt: "쿠폰, 배송, 운송장, 주소")
        .onAppear {
            viewModel = SearchViewModel(store: LocalStore(modelContext: modelContext))
        }
    }
}
```

- [ ] **Step 3: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add CaptureBox/ViewModels/SearchViewModel.swift CaptureBox/Views/SearchView.swift
git commit -m "feat: add OCR text search UI"
```

---

### Task 12: 설정 화면과 권한 관리

**Files:**
- Create: `CaptureBox/Views/SettingsView.swift`
- Modify: `CaptureBox/Views/LibraryView.swift`

- [ ] **Step 1: SettingsView 작성**

Create `CaptureBox/Views/SettingsView.swift`:

```swift
import Photos
import SwiftUI

struct SettingsView: View {
    @StateObject private var photoLibraryService = PhotoLibraryService()

    var body: some View {
        Form {
            Section("사진 권한") {
                LabeledContent("현재 상태", value: statusTitle)
                if photoLibraryService.authorizationStatus == .limited {
                    Button("선택한 사진 관리") {
                        photoLibraryService.presentLimitedLibraryPicker()
                    }
                }
            }

            Section("개인정보") {
                Text("CaptureBox는 MVP에서 스크린샷과 저장 이미지를 서버로 업로드하지 않습니다. 분석은 기기 안에서만 진행되며 Photos 원본을 삭제하거나 이동하지 않습니다.")
            }
        }
        .navigationTitle("설정")
        .onAppear {
            photoLibraryService.refreshAuthorizationStatus()
        }
    }

    private var statusTitle: String {
        switch photoLibraryService.authorizationStatus {
        case .authorized: "전체 접근"
        case .limited: "선택한 사진만"
        case .denied: "거부됨"
        case .restricted: "제한됨"
        case .notDetermined: "아직 요청하지 않음"
        @unknown default: "알 수 없음"
        }
    }
}
```

- [ ] **Step 2: LibraryView에 설정 링크 추가**

Modify toolbar in `CaptureBox/Views/LibraryView.swift`:

```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        NavigationLink("검색") {
            SearchView()
        }
    }
    ToolbarItem(placement: .topBarTrailing) {
        Menu {
            Button("스캔") {
                isShowingScan = true
            }
            NavigationLink("설정") {
                SettingsView()
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
```

- [ ] **Step 3: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add CaptureBox/Views/SettingsView.swift CaptureBox/Views/LibraryView.swift
git commit -m "feat: add settings and permission management"
```

---

### Task 13: 실제 썸네일 표시

**Files:**
- Create: `CaptureBox/ViewModels/ThumbnailViewModel.swift`
- Create: `CaptureBox/Views/AssetThumbnailView.swift`
- Modify: `CaptureBox/Views/CategoryDetailView.swift`

- [ ] **Step 1: 썸네일 ViewModel 작성**

Create `CaptureBox/ViewModels/ThumbnailViewModel.swift`:

```swift
import Photos
import SwiftUI

@MainActor
@Observable
final class ThumbnailViewModel {
    var image: UIImage?

    func load(assetLocalIdentifier: String) async {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetLocalIdentifier], options: nil)
        guard let asset = result.firstObject else { return }
        let service = PhotoLibraryService()
        image = await service.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300))
    }
}
```

- [ ] **Step 2: AssetThumbnailView 작성**

Create `CaptureBox/Views/AssetThumbnailView.swift`:

```swift
import SwiftUI

struct AssetThumbnailView: View {
    let assetLocalIdentifier: String
    @State private var viewModel = ThumbnailViewModel()

    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task {
            await viewModel.load(assetLocalIdentifier: assetLocalIdentifier)
        }
    }
}
```

- [ ] **Step 3: CategoryDetailView에서 실제 썸네일 사용**

Replace grid cell in `CaptureBox/Views/CategoryDetailView.swift`:

```swift
NavigationLink {
    ImageDetailView(item: item)
} label: {
    AssetThumbnailView(assetLocalIdentifier: item.assetLocalIdentifier)
        .aspectRatio(1, contentMode: .fit)
}
```

- [ ] **Step 4: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add CaptureBox/ViewModels/ThumbnailViewModel.swift CaptureBox/Views/AssetThumbnailView.swift CaptureBox/Views/CategoryDetailView.swift
git commit -m "feat: show photo thumbnails"
```

---

### Task 14: 수동 QA와 MVP 마감 점검

**Files:**
- Modify: `docs/qa/mvp-manual-test.md`

- [ ] **Step 1: QA 문서 작성**

Create `docs/qa/mvp-manual-test.md`:

```markdown
# CaptureBox MVP 수동 QA

## 권한

- [ ] 첫 실행에서 사진 권한 안내가 한국어로 보인다.
- [ ] 선택한 사진만 허용해도 앱이 보관함으로 진입한다.
- [ ] 전체 접근 허용 시 최근 1년 스캔이 시작된다.
- [ ] 설정 화면에서 권한 상태가 올바르게 표시된다.

## 스캔

- [ ] 최근 1년 스캔이 시작된다.
- [ ] 스캔 중 현재 단계와 분석 개수가 표시된다.
- [ ] 취소 버튼을 누르면 스캔이 취소된다.
- [ ] iCloud 사진이 있어도 앱이 크래시하지 않는다.

## 분류

- [ ] 쿠폰 이미지가 쿠폰으로 분류된다.
- [ ] 영수증 이미지가 영수증으로 분류된다.
- [ ] 배송 이미지가 배송으로 분류된다.
- [ ] 티켓/예약 이미지가 티켓/예약으로 분류된다.
- [ ] 주소/지도 이미지가 주소/지도로 분류된다.
- [ ] 계좌/결제 이미지가 계좌/결제로 분류되고 민감 정보로 표시된다.
- [ ] 애매한 이미지는 미분류로 들어간다.

## 검색

- [ ] OCR 텍스트 일부로 검색하면 결과가 나온다.
- [ ] 카테고리명으로 검색하면 결과가 나온다.
- [ ] 결과가 없을 때 빈 상태가 어색하지 않다.

## 비범위 확인

- [ ] Photos 앱에 새 앨범이 생성되지 않는다.
- [ ] Photos 원본이 삭제되지 않는다.
- [ ] 광고가 보이지 않는다.
- [ ] 서버 업로드 동의나 로그인 요구가 없다.
```

- [ ] **Step 2: 전체 테스트 실행**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 3: 실제 기기 수동 테스트**

Run on a physical iPhone with iOS 18 or later:

```text
Xcode > Product > Destination > connected iPhone
Xcode > Product > Run
```

Expected:

- 권한 요청이 정상 표시된다.
- 실제 사진 라이브러리에서 스크린샷 후보가 수집된다.
- OCR 분석 중 앱이 크래시하지 않는다.
- 스캔 중 발열과 속도가 MVP 검증 가능한 수준이다.

- [ ] **Step 4: Commit**

```bash
git add docs/qa/mvp-manual-test.md
git commit -m "docs: add MVP manual QA checklist"
```

---

## 자체 리뷰

### 스펙 커버리지

- 사진 접근 권한: Task 4, Task 8, Task 12
- 최근 1년 스캔: Task 4, Task 7, Task 9
- 스크린샷과 저장 이미지 후보: Task 4
- OCR/QR/바코드 분석: Task 5
- 규칙 기반 자동 분류: Task 3
- 6개 카테고리와 미분류: Task 2, Task 3, Task 10
- 앱 내부 보관함: Task 6, Task 10
- OCR 검색: Task 6, Task 11
- 상세 화면 카테고리 변경: Task 10
- 첫 스캔 요약: Task 9
- Photos 원본 수정 제외: Task 12, Task 14
- 광고 제외: Task 14
- Gemma 4 E2B 제외: Task 14

### 범위 확인

이 계획은 MVP 하나에 집중한다. App Store 출시 메타데이터, AdMob, Photos 앨범 생성, Face ID, 만료일 알림, Gemma 4 E2B는 포함하지 않는다.

### 구현 주의사항

- `PHAsset.addedDate` 사용 가능 여부는 Xcode의 실제 SDK에서 확인한다. 컴파일 오류가 나면 `creationDate` fallback만 사용한다.
- SwiftData 모델에서 enum은 rawValue 저장 방식을 유지한다.
- 사용자가 카테고리를 직접 바꾼 항목은 재스캔으로 덮어쓰지 않는다.
- Vision OCR은 한국어/영어 혼합 이미지를 실제 기기에서 반드시 테스트한다.
- 성능 문제가 있으면 `ScanCoordinator`에 배치 처리와 백프레셔를 추가한다.
