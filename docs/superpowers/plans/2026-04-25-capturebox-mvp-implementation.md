# CaptureBox MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** TCA 기반 iOS 18 SwiftUI 앱 `CaptureBox`를 만들어 최근 1년의 스크린샷과 저장 이미지 후보를 온디바이스로 분석하고, 앱 내부 보관함에서 6개 카테고리와 미분류로 자동 정리한다.

**Architecture:** 전체 앱 구조는 TCA로 일원화한다. SwiftUI View는 `StoreOf<Feature>`만 관찰하고 액션을 보낸다. 상태 전이와 비동기 흐름은 Feature/Reducer가 담당하며, PhotoKit/Vision/SwiftData 접근은 TCA Dependency Client와 Repository 구현체로 분리한다.

**Tech Stack:** Swift 6, SwiftUI, The Composable Architecture, Photos/PhotoKit, Vision, SwiftData, XCTest, iOS 18, Xcode 16 이상.

---

## 1. 아키텍처 결정

MVP는 기존 MV + Service + Coordinator 계획 대신 아래 구조를 사용한다.

```text
SwiftUI Views
  ↓
TCA Store
  ↓
Feature / Reducer
  ↓
Dependency Clients
  ↓
Repository / Live Services
  ↓
PhotoKit / Vision / SwiftData
```

핵심 원칙:

- 모든 화면 상태는 TCA `State`에 둔다.
- 모든 사용자 이벤트와 비동기 결과는 TCA `Action`으로 표현한다.
- 긴 스캔 플로우는 `ScanFeature`의 Effect로 처리한다.
- 기존 계획의 `ScanCoordinator`는 만들지 않는다.
- 기존 계획의 화면별 ViewModel은 만들지 않는다.
- Repository는 저장소 추상화로 둔다.
- PhotoKit, Vision, Classification, Repository는 TCA Dependency로 주입한다.
- SwiftUI View는 비즈니스 로직을 갖지 않는다.

## 2. 파일 구조

새 Xcode 프로젝트 루트는 `CaptureBox/`로 둔다.

```text
CaptureBox/
  CaptureBoxApp.swift
  App/
    AppFeature.swift
    AppView.swift
  Domain/
    CaptureCategory.swift
    CapturedImage.swift
    ScanModels.swift
    VisionAnalysisResult.swift
  Features/
    Onboarding/
      OnboardingFeature.swift
      OnboardingView.swift
    Library/
      LibraryFeature.swift
      LibraryView.swift
    Scan/
      ScanFeature.swift
      ScanView.swift
    Search/
      SearchFeature.swift
      SearchView.swift
    ImageDetail/
      ImageDetailFeature.swift
      ImageDetailView.swift
    Settings/
      SettingsFeature.swift
      SettingsView.swift
  Dependencies/
    PhotoLibraryClient.swift
    VisionClient.swift
    ClassificationClient.swift
    CapturedImageRepository.swift
  Live/
    LivePhotoLibraryClient.swift
    LiveVisionClient.swift
    RuleBasedClassificationClient.swift
    SwiftDataCapturedImageRepository.swift
  Persistence/
    CapturedImageRecord.swift
    ScanSessionRecord.swift
  Views/
    AssetThumbnailView.swift
  Resources/
    InfoPlist.strings

CaptureBoxTests/
  DomainTests.swift
  ClassificationClientTests.swift
  LibraryFeatureTests.swift
  ScanFeatureTests.swift
  SearchFeatureTests.swift
```

## 3. Dependency 설계

`PhotoLibraryClient`

- 사진 권한 상태 확인
- 사진 권한 요청
- 제한된 사진 선택 관리
- 최근 1년/전체 기간 후보 asset 조회
- 썸네일/분석용 이미지 요청

`VisionClient`

- OCR 텍스트 추출
- QR/바코드 payload 추출

`ClassificationClient`

- `VisionAnalysisResult`와 source 정보를 받아 카테고리, 신뢰도, 민감 여부 산출
- MVP에서는 규칙 기반 구현 사용

`CapturedImageRepository`

- 분석 결과 upsert
- 전체 항목 조회
- 카테고리별 조회
- OCR 검색
- 사용자 카테고리 수정
- 스캔 세션 저장

## 4. Feature 설계

`AppFeature`

- 앱 루트 상태
- 온보딩 완료 여부
- 탭/라우팅
- 하위 Feature 조합

`OnboardingFeature`

- 권한 안내
- 사진 권한 요청
- 전체 접근/선택 접근 상태 반영
- 온보딩 완료 액션

`LibraryFeature`

- 카테고리별 개수
- 보관함 목록
- 스캔 화면 표시
- 검색/설정/상세 진입

`ScanFeature`

- 최근 1년 스캔
- 전체 기간 스캔
- 후보 수집
- OCR/QR 분석
- 분류
- 저장
- 진행률
- 취소
- 요약
- 오류 상태

`SearchFeature`

- 검색어
- OCR 텍스트 검색 결과
- 결과 상세 진입

`ImageDetailFeature`

- 이미지 상세
- OCR 텍스트 표시
- 카테고리 수동 변경
- 민감 정보 표시

`SettingsFeature`

- 권한 상태 표시
- 선택한 사진 관리
- 전체 기간 스캔 진입
- 개인정보 설명

---

### Task 1: Xcode 프로젝트 생성과 TCA 의존성 추가

**Files:**
- Create: `CaptureBox.xcodeproj`
- Create: `CaptureBox/CaptureBoxApp.swift`
- Create: `CaptureBox/App/AppFeature.swift`
- Create: `CaptureBox/App/AppView.swift`
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

- [ ] **Step 2: TCA 패키지 추가**

Run in Xcode:

```text
File > Add Package Dependencies...
Package URL: https://github.com/pointfreeco/swift-composable-architecture
Dependency Rule: Up to Next Major Version
Add package product: ComposableArchitecture
Target: CaptureBox
```

Expected: 앱 타겟에서 `import ComposableArchitecture`가 가능하다.

- [ ] **Step 3: 권한 문구 추가**

Xcode target `CaptureBox`의 Info 설정에 아래 키를 추가한다.

```text
Privacy - Photo Library Usage Description
스크린샷과 저장 이미지를 기기 안에서 분석해 자동으로 정리하기 위해 사진 접근 권한이 필요합니다.

Privacy - Photo Library Additions Usage Description
향후 사용자가 요청할 때 Photos 앨범을 만들기 위해 필요할 수 있습니다. MVP에서는 사진 앱을 수정하지 않습니다.
```

- [ ] **Step 4: AppFeature 기본 뼈대 작성**

Create `CaptureBox/App/AppFeature.swift`:

```swift
import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var hasCompletedOnboarding = false
        var onboarding = OnboardingFeature.State()
        var library = LibraryFeature.State()
    }

    enum Action: Equatable {
        case appStarted
        case onboarding(OnboardingFeature.Action)
        case library(LibraryFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        Scope(state: \.library, action: \.library) {
            LibraryFeature()
        }
        Reduce { state, action in
            switch action {
            case .appStarted:
                state.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                return .none

            case .onboarding(.delegate(.completed)):
                state.hasCompletedOnboarding = true
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                return .none

            case .onboarding, .library:
                return .none
            }
        }
    }
}
```

- [ ] **Step 5: 임시 하위 Feature 작성**

Create `CaptureBox/Features/Onboarding/OnboardingFeature.swift`:

```swift
import ComposableArchitecture

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {}

    enum Action: Equatable {
        case startButtonTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case completed
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .startButtonTapped:
                return .send(.delegate(.completed))
            case .delegate:
                return .none
            }
        }
    }
}
```

Create `CaptureBox/Features/Library/LibraryFeature.swift`:

```swift
import ComposableArchitecture

@Reducer
struct LibraryFeature {
    @ObservableState
    struct State: Equatable {}

    enum Action: Equatable {}

    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
```

- [ ] **Step 6: AppView 작성**

Create `CaptureBox/App/AppView.swift`:

```swift
import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                LibraryView(store: store.scope(state: \.library, action: \.library))
            } else {
                OnboardingView(store: store.scope(state: \.onboarding, action: \.onboarding))
            }
        }
        .task {
            await store.send(.appStarted).finish()
        }
    }
}
```

Create `CaptureBox/Features/Onboarding/OnboardingView.swift`:

```swift
import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("스크린샷과 저장 이미지를\n기기 안에서 정리합니다")
                .font(.largeTitle.bold())
            Text("사진은 서버로 업로드하지 않고 기기 안에서만 분석합니다.")
                .foregroundStyle(.secondary)
            Spacer()
            Button("사진 접근 허용하기") {
                store.send(.startButtonTapped)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
    }
}
```

Create `CaptureBox/Features/Library/LibraryView.swift`:

```swift
import ComposableArchitecture
import SwiftUI

struct LibraryView: View {
    let store: StoreOf<LibraryFeature>

    var body: some View {
        NavigationStack {
            Text("보관함")
                .navigationTitle("보관함")
        }
    }
}
```

- [ ] **Step 7: 앱 진입점 작성**

Replace `CaptureBox/CaptureBoxApp.swift`:

```swift
import ComposableArchitecture
import SwiftUI

@main
struct CaptureBoxApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(initialState: AppFeature.State()) {
                    AppFeature()
                }
            )
        }
    }
}
```

- [ ] **Step 8: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 9: Commit**

```bash
git add CaptureBox.xcodeproj CaptureBox CaptureBoxTests
git commit -m "chore: create TCA CaptureBox project"
```

---

### Task 2: 도메인 모델 정의

**Files:**
- Create: `CaptureBox/Domain/CaptureCategory.swift`
- Create: `CaptureBox/Domain/CapturedImage.swift`
- Create: `CaptureBox/Domain/ScanModels.swift`
- Create: `CaptureBox/Domain/VisionAnalysisResult.swift`
- Test: `CaptureBoxTests/DomainTests.swift`

- [ ] **Step 1: 도메인 테스트 작성**

Create `CaptureBoxTests/DomainTests.swift`:

```swift
import XCTest
@testable import CaptureBox

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
```

- [ ] **Step 2: 실패 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/DomainTests
```

Expected: `Cannot find 'CaptureCategory' in scope`

- [ ] **Step 3: CaptureCategory 작성**

Create `CaptureBox/Domain/CaptureCategory.swift`:

```swift
import Foundation

enum CaptureCategory: String, CaseIterable, Codable, Equatable, Identifiable {
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

- [ ] **Step 4: 나머지 도메인 모델 작성**

Create `CaptureBox/Domain/VisionAnalysisResult.swift`:

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

Create `CaptureBox/Domain/CapturedImage.swift`:

```swift
import Foundation

enum CaptureSourceKind: String, Codable, Equatable {
    case screenshot
    case savedImageCandidate
    case manualSelection
}

enum ReviewStatus: String, Codable, Equatable {
    case new
    case confirmed
    case changedByUser
    case ignored
}

struct CapturedImage: Equatable, Identifiable, Codable {
    var id: String { assetLocalIdentifier }
    var assetLocalIdentifier: String
    var sourceKind: CaptureSourceKind
    var creationDate: Date?
    var addedDate: Date?
    var recognizedText: String
    var detectedCodes: [String]
    var category: CaptureCategory
    var confidence: Double
    var reviewStatus: ReviewStatus
    var isSensitive: Bool
    var lastAnalyzedAt: Date
}
```

Create `CaptureBox/Domain/ScanModels.swift`:

```swift
import Foundation

enum ScanRange: String, Codable, Equatable {
    case recentYear
    case allTime
}

enum ScanPhase: Equatable {
    case idle
    case findingImages
    case analyzing
    case saving
    case completed
    case cancelled
    case failed(String)

    var title: String {
        switch self {
        case .idle: "대기 중"
        case .findingImages: "이미지 찾는 중"
        case .analyzing: "분석 중"
        case .saving: "저장 중"
        case .completed: "완료"
        case .cancelled: "취소됨"
        case .failed: "실패"
        }
    }
}

struct ScanProgress: Equatable {
    var phase: ScanPhase = .idle
    var candidateCount = 0
    var analyzedCount = 0
    var classifiedCount = 0
    var unknownCount = 0
}

struct PhotoAssetCandidate: Equatable, Identifiable {
    var id: String
    var sourceKind: CaptureSourceKind
    var creationDate: Date?
    var addedDate: Date?
}
```

- [ ] **Step 5: 테스트 통과 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/DomainTests
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add CaptureBox/Domain CaptureBoxTests/DomainTests.swift
git commit -m "feat: add capture domain models"
```

---

### Task 3: Dependency Client와 Repository 인터페이스 작성

**Files:**
- Create: `CaptureBox/Dependencies/PhotoLibraryClient.swift`
- Create: `CaptureBox/Dependencies/VisionClient.swift`
- Create: `CaptureBox/Dependencies/ClassificationClient.swift`
- Create: `CaptureBox/Dependencies/CapturedImageRepository.swift`

- [ ] **Step 1: PhotoLibraryClient 작성**

Create `CaptureBox/Dependencies/PhotoLibraryClient.swift`:

```swift
import ComposableArchitecture
import Foundation
import Photos
import UIKit

struct PhotoLibraryClient {
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
```

- [ ] **Step 2: VisionClient 작성**

Create `CaptureBox/Dependencies/VisionClient.swift`:

```swift
import ComposableArchitecture
import UIKit

struct VisionClient {
    var analyze: @Sendable (_ image: UIImage) async -> VisionAnalysisResult
}

extension VisionClient: DependencyKey {
    static let liveValue = VisionClient.live
    static let testValue = VisionClient(analyze: { _ in .empty })
}

extension DependencyValues {
    var visionClient: VisionClient {
        get { self[VisionClient.self] }
        set { self[VisionClient.self] = newValue }
    }
}
```

- [ ] **Step 3: ClassificationClient 작성**

Create `CaptureBox/Dependencies/ClassificationClient.swift`:

```swift
import ComposableArchitecture
import Foundation

struct ClassificationResult: Equatable {
    var category: CaptureCategory
    var confidence: Double
    var reason: String
    var isSensitive: Bool
}

struct ClassificationClient {
    var classify: @Sendable (_ analysis: VisionAnalysisResult, _ sourceKind: CaptureSourceKind) -> ClassificationResult
}

extension ClassificationClient: DependencyKey {
    static let liveValue = ClassificationClient.live
    static let testValue = ClassificationClient(
        classify: { _, _ in
            ClassificationResult(category: .unknown, confidence: 0, reason: "test", isSensitive: false)
        }
    )
}

extension DependencyValues {
    var classificationClient: ClassificationClient {
        get { self[ClassificationClient.self] }
        set { self[ClassificationClient.self] = newValue }
    }
}
```

- [ ] **Step 4: CapturedImageRepository 작성**

Create `CaptureBox/Dependencies/CapturedImageRepository.swift`:

```swift
import ComposableArchitecture
import Foundation

struct CapturedImageRepository {
    var upsert: @Sendable (_ image: CapturedImage) async throws -> Void
    var all: @Sendable () async throws -> [CapturedImage]
    var items: @Sendable (_ category: CaptureCategory) async throws -> [CapturedImage]
    var search: @Sendable (_ query: String) async throws -> [CapturedImage]
    var updateCategory: @Sendable (_ assetLocalIdentifier: String, _ category: CaptureCategory) async throws -> Void
}

extension CapturedImageRepository: DependencyKey {
    static let liveValue = CapturedImageRepository.live
    static let testValue = CapturedImageRepository(
        upsert: { _ in },
        all: { [] },
        items: { _ in [] },
        search: { _ in [] },
        updateCategory: { _, _ in }
    )
}

extension DependencyValues {
    var capturedImageRepository: CapturedImageRepository {
        get { self[CapturedImageRepository.self] }
        set { self[CapturedImageRepository.self] = newValue }
    }
}
```

- [ ] **Step 5: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: live 구현이 아직 없어 `type 'PhotoLibraryClient' has no member 'live'` 류의 오류가 난다.

- [ ] **Step 6: Commit은 하지 않는다**

Task 4에서 live 구현을 추가한 뒤 함께 커밋한다.

---

### Task 4: Live 구현과 SwiftData Persistence

**Files:**
- Create: `CaptureBox/Persistence/CapturedImageRecord.swift`
- Create: `CaptureBox/Persistence/ScanSessionRecord.swift`
- Create: `CaptureBox/Live/LivePhotoLibraryClient.swift`
- Create: `CaptureBox/Live/LiveVisionClient.swift`
- Create: `CaptureBox/Live/RuleBasedClassificationClient.swift`
- Create: `CaptureBox/Live/SwiftDataCapturedImageRepository.swift`
- Modify: `CaptureBox/CaptureBoxApp.swift`
- Test: `CaptureBoxTests/ClassificationClientTests.swift`

- [ ] **Step 1: Classification 테스트 작성**

Create `CaptureBoxTests/ClassificationClientTests.swift`:

```swift
import XCTest
@testable import CaptureBox

final class ClassificationClientTests: XCTestCase {
    func testCouponWithQRCode() {
        let client = ClassificationClient.live
        let result = client.classify(
            VisionAnalysisResult(
                recognizedText: "스타벅스 쿠폰 할인 유효기간 2026.05.31",
                detectedCodes: ["QR"],
                hasBarcodeOrQRCode: true
            ),
            .screenshot
        )

        XCTAssertEqual(result.category, .coupon)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.55)
        XCTAssertFalse(result.isSensitive)
    }

    func testPaymentIsSensitive() {
        let client = ClassificationClient.live
        let result = client.classify(
            VisionAnalysisResult(
                recognizedText: "국민은행 계좌 이체 입금 결제",
                detectedCodes: [],
                hasBarcodeOrQRCode: false
            ),
            .screenshot
        )

        XCTAssertEqual(result.category, .payment)
        XCTAssertTrue(result.isSensitive)
    }
}
```

- [ ] **Step 2: SwiftData record 작성**

Create `CaptureBox/Persistence/CapturedImageRecord.swift`:

```swift
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
}
```

Create `CaptureBox/Persistence/ScanSessionRecord.swift`:

```swift
import Foundation
import SwiftData

@Model
final class ScanSessionRecord {
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
}
```

- [ ] **Step 3: RuleBasedClassificationClient 작성**

Create `CaptureBox/Live/RuleBasedClassificationClient.swift`:

```swift
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
```

- [ ] **Step 4: Vision live 작성**

Create `CaptureBox/Live/LiveVisionClient.swift`:

```swift
import UIKit
import Vision

extension VisionClient {
    static let live = VisionClient { image in
        guard let cgImage = image.cgImage else { return .empty }

        async let text = recognizeText(cgImage)
        async let codes = detectCodes(cgImage)
        let resultText = await text
        let resultCodes = await codes

        return VisionAnalysisResult(
            recognizedText: resultText,
            detectedCodes: resultCodes,
            hasBarcodeOrQRCode: !resultCodes.isEmpty
        )
    }
}

private func recognizeText(_ cgImage: CGImage) async -> String {
    await withCheckedContinuation { continuation in
        let request = VNRecognizeTextRequest { request, _ in
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            continuation.resume(returning: lines.joined(separator: "\n"))
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["ko-KR", "en-US"]

        do {
            try VNImageRequestHandler(cgImage: cgImage).perform([request])
        } catch {
            continuation.resume(returning: "")
        }
    }
}

private func detectCodes(_ cgImage: CGImage) async -> [String] {
    await withCheckedContinuation { continuation in
        let request = VNDetectBarcodesRequest { request, _ in
            let observations = request.results as? [VNBarcodeObservation] ?? []
            continuation.resume(returning: observations.compactMap(\.payloadStringValue))
        }

        do {
            try VNImageRequestHandler(cgImage: cgImage).perform([request])
        } catch {
            continuation.resume(returning: [])
        }
    }
}
```

- [ ] **Step 5: PhotoLibrary live 작성**

Create `CaptureBox/Live/LivePhotoLibraryClient.swift`:

```swift
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
                ) { image, _ in
                    continuation.resume(returning: image)
                }
            }
        },
        presentLimitedLibraryPicker: {
            await MainActor.run {
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let controller = scene.windows.first?.rootViewController else {
                    return
                }
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: controller)
            }
        }
    )
}

private func predicate(for range: ScanRange) -> NSPredicate {
    let mediaPredicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
    guard range == .recentYear,
          let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) else {
        return mediaPredicate
    }
    let datePredicate = NSPredicate(format: "creationDate >= %@", startDate as NSDate)
    return NSCompoundPredicate(andPredicateWithSubpredicates: [mediaPredicate, datePredicate])
}
```

- [ ] **Step 6: SwiftData repository live 작성**

Create `CaptureBox/Live/SwiftDataCapturedImageRepository.swift`:

```swift
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
            await MainActor.run {
                let context = RepositoryContainer.shared.modelContainer.mainContext
                let id = image.assetLocalIdentifier
                let descriptor = FetchDescriptor<CapturedImageRecord>(
                    predicate: #Predicate { $0.assetLocalIdentifier == id }
                )

                if let existing = try? context.fetch(descriptor).first {
                    existing.sourceKindRawValue = image.sourceKind.rawValue
                    existing.creationDate = image.creationDate
                    existing.addedDate = image.addedDate
                    existing.recognizedText = image.recognizedText
                    existing.detectedCodes = image.detectedCodes
                    if existing.reviewStatusRawValue != ReviewStatus.changedByUser.rawValue {
                        existing.categoryRawValue = image.category.rawValue
                        existing.confidence = image.confidence
                        existing.isSensitive = image.isSensitive
                    }
                    existing.lastAnalyzedAt = image.lastAnalyzedAt
                } else {
                    context.insert(CapturedImageRecord(image: image))
                }

                try? context.save()
            }
        },
        all: {
            await MainActor.run {
                let context = RepositoryContainer.shared.modelContainer.mainContext
                let descriptor = FetchDescriptor<CapturedImageRecord>(
                    sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
                )
                return (try? context.fetch(descriptor).map(\.domain)) ?? []
            }
        },
        items: { category in
            await MainActor.run {
                let context = RepositoryContainer.shared.modelContainer.mainContext
                let rawValue = category.rawValue
                let descriptor = FetchDescriptor<CapturedImageRecord>(
                    predicate: #Predicate { $0.categoryRawValue == rawValue },
                    sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
                )
                return (try? context.fetch(descriptor).map(\.domain)) ?? []
            }
        },
        search: { query in
            await MainActor.run {
                let context = RepositoryContainer.shared.modelContainer.mainContext
                let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !normalized.isEmpty else { return [] }
                let descriptor = FetchDescriptor<CapturedImageRecord>(
                    sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
                )
                let all = (try? context.fetch(descriptor).map(\.domain)) ?? []
                return all.filter {
                    $0.recognizedText.lowercased().contains(normalized)
                        || $0.category.title.lowercased().contains(normalized)
                }
            }
        },
        updateCategory: { localIdentifier, category in
            await MainActor.run {
                let context = RepositoryContainer.shared.modelContainer.mainContext
                let descriptor = FetchDescriptor<CapturedImageRecord>(
                    predicate: #Predicate { $0.assetLocalIdentifier == localIdentifier }
                )
                guard let record = try? context.fetch(descriptor).first else { return }
                record.categoryRawValue = category.rawValue
                record.reviewStatusRawValue = ReviewStatus.changedByUser.rawValue
                record.isSensitive = category.isSensitive
                try? context.save()
            }
        }
    )
}
```

- [ ] **Step 7: CaptureBoxApp에서 SwiftData container 연결**

Replace `CaptureBox/CaptureBoxApp.swift`:

```swift
import ComposableArchitecture
import SwiftUI

@main
struct CaptureBoxApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(initialState: AppFeature.State()) {
                    AppFeature()
                }
            )
        }
        .modelContainer(RepositoryContainer.shared.modelContainer)
    }
}
```

- [ ] **Step 8: 테스트와 빌드 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/ClassificationClientTests
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: both commands succeed.

- [ ] **Step 9: Commit**

```bash
git add CaptureBox/Dependencies CaptureBox/Live CaptureBox/Persistence CaptureBox/CaptureBoxApp.swift CaptureBoxTests/ClassificationClientTests.swift
git commit -m "feat: add TCA dependencies and live clients"
```

---

### Task 5: OnboardingFeature 권한 플로우

**Files:**
- Modify: `CaptureBox/Features/Onboarding/OnboardingFeature.swift`
- Modify: `CaptureBox/Features/Onboarding/OnboardingView.swift`
- Test: `CaptureBoxTests/OnboardingFeatureTests.swift`

- [ ] **Step 1: OnboardingFeature 테스트 작성**

Create `CaptureBoxTests/OnboardingFeatureTests.swift`:

```swift
import ComposableArchitecture
import Photos
import XCTest
@testable import CaptureBox

@MainActor
final class OnboardingFeatureTests: XCTestCase {
    func testAuthorizedCompletesOnboarding() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        } withDependencies: {
            $0.photoLibraryClient.requestAuthorization = { .authorized }
        }

        await store.send(.photoAccessButtonTapped) {
            $0.isRequestingPermission = true
        }
        await store.receive(.photoAuthorizationResponse(.authorized)) {
            $0.isRequestingPermission = false
            $0.authorizationStatus = .authorized
        }
        await store.receive(.delegate(.completed))
    }
}
```

- [ ] **Step 2: OnboardingFeature 구현**

Replace `CaptureBox/Features/Onboarding/OnboardingFeature.swift`:

```swift
import ComposableArchitecture
import Photos

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var authorizationStatus: PHAuthorizationStatus = .notDetermined
        var isRequestingPermission = false
    }

    enum Action: Equatable {
        case photoAccessButtonTapped
        case photoAuthorizationResponse(PHAuthorizationStatus)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case completed
        }
    }

    @Dependency(\.photoLibraryClient) var photoLibraryClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .photoAccessButtonTapped:
                state.isRequestingPermission = true
                return .run { send in
                    await send(.photoAuthorizationResponse(await photoLibraryClient.requestAuthorization()))
                }

            case let .photoAuthorizationResponse(status):
                state.isRequestingPermission = false
                state.authorizationStatus = status
                if status == .authorized || status == .limited {
                    return .send(.delegate(.completed))
                }
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
```

- [ ] **Step 3: OnboardingView 구현**

Replace `CaptureBox/Features/Onboarding/OnboardingView.swift`:

```swift
import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("스크린샷과 저장 이미지를\n기기 안에서 정리합니다")
                .font(.largeTitle.bold())
            Text("쿠폰, 영수증, 배송, 예약, 주소, 결제 메모를 자동으로 찾아 앱 내부 보관함에 정리합니다. 사진은 서버로 업로드하지 않습니다.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 12) {
                Label("선택한 사진만 허용해도 사용할 수 있어요", systemImage: "checkmark.circle")
                Label("전체 접근을 허용하면 자동 분류가 더 잘 됩니다", systemImage: "sparkles")
                Label("MVP에서는 Photos 원본을 삭제하거나 이동하지 않습니다", systemImage: "lock.shield")
            }
            .font(.callout)
            Spacer()
            Button {
                store.send(.photoAccessButtonTapped)
            } label: {
                Text(store.isRequestingPermission ? "권한 요청 중" : "사진 접근 허용하기")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(store.isRequestingPermission)
        }
        .padding(24)
    }
}
```

- [ ] **Step 4: 테스트 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/OnboardingFeatureTests
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add CaptureBox/Features/Onboarding CaptureBoxTests/OnboardingFeatureTests.swift
git commit -m "feat: add TCA onboarding permission flow"
```

---

### Task 6: ScanFeature 구현

**Files:**
- Create: `CaptureBox/Features/Scan/ScanFeature.swift`
- Create: `CaptureBox/Features/Scan/ScanView.swift`
- Test: `CaptureBoxTests/ScanFeatureTests.swift`

- [ ] **Step 1: ScanFeature 테스트 작성**

Create `CaptureBoxTests/ScanFeatureTests.swift`:

```swift
import ComposableArchitecture
import UIKit
import XCTest
@testable import CaptureBox

@MainActor
final class ScanFeatureTests: XCTestCase {
    func testRecentYearScanClassifiesAndSaves() async {
        let candidate = PhotoAssetCandidate(
            id: "asset-1",
            sourceKind: .screenshot,
            creationDate: Date(timeIntervalSince1970: 10),
            addedDate: Date(timeIntervalSince1970: 10)
        )
        var saved: [CapturedImage] = []

        let store = TestStore(initialState: ScanFeature.State()) {
            ScanFeature()
        } withDependencies: {
            $0.photoLibraryClient.fetchCandidates = { _ in [candidate] }
            $0.photoLibraryClient.requestImage = { _, _ in UIImage() }
            $0.visionClient.analyze = { _ in
                VisionAnalysisResult(
                    recognizedText: "쿠폰 할인 유효기간",
                    detectedCodes: ["QR"],
                    hasBarcodeOrQRCode: true
                )
            }
            $0.classificationClient.classify = { _, _ in
                ClassificationResult(category: .coupon, confidence: 0.8, reason: "쿠폰", isSensitive: false)
            }
            $0.capturedImageRepository.upsert = { image in
                saved.append(image)
            }
        }

        await store.send(.startButtonTapped(.recentYear)) {
            $0.progress.phase = .findingImages
            $0.range = .recentYear
        }
        await store.receive(.candidatesResponse(.success([candidate]))) {
            $0.progress.candidateCount = 1
        }
        await store.receive(.candidateAnalyzed(candidate, VisionAnalysisResult(recognizedText: "쿠폰 할인 유효기간", detectedCodes: ["QR"], hasBarcodeOrQRCode: true), ClassificationResult(category: .coupon, confidence: 0.8, reason: "쿠폰", isSensitive: false))) {
            $0.progress.analyzedCount = 1
            $0.progress.classifiedCount = 1
        }
        await store.receive(.scanCompleted) {
            $0.progress.phase = .completed
        }

        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.category, .coupon)
    }
}
```

- [ ] **Step 2: ScanFeature 구현**

Create `CaptureBox/Features/Scan/ScanFeature.swift`:

```swift
import ComposableArchitecture
import Foundation
import UIKit

@Reducer
struct ScanFeature {
    @ObservableState
    struct State: Equatable {
        var range: ScanRange = .recentYear
        var progress = ScanProgress()
        var isSummaryVisible = false
    }

    enum Action: Equatable {
        case startButtonTapped(ScanRange)
        case cancelButtonTapped
        case candidatesResponse(Result<[PhotoAssetCandidate], String>)
        case candidateAnalyzed(PhotoAssetCandidate, VisionAnalysisResult, ClassificationResult)
        case candidateSkipped(PhotoAssetCandidate)
        case scanCompleted
        case delegate(Delegate)

        enum Delegate: Equatable {
            case finished
        }
    }

    @Dependency(\.photoLibraryClient) var photoLibraryClient
    @Dependency(\.visionClient) var visionClient
    @Dependency(\.classificationClient) var classificationClient
    @Dependency(\.capturedImageRepository) var repository

    enum CancelID { case scan }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .startButtonTapped(range):
                state.range = range
                state.progress = ScanProgress(phase: .findingImages)
                return .run { send in
                    do {
                        let candidates = try await photoLibraryClient.fetchCandidates(range)
                        await send(.candidatesResponse(.success(candidates)))
                        for candidate in candidates {
                            try Task.checkCancellation()
                            guard let image = await photoLibraryClient.requestImage(candidate.id, CGSize(width: 1600, height: 1600)) else {
                                await send(.candidateSkipped(candidate))
                                continue
                            }
                            let analysis = await visionClient.analyze(image)
                            let classification = classificationClient.classify(analysis, candidate.sourceKind)
                            let captured = CapturedImage(
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
                            try await repository.upsert(captured)
                            await send(.candidateAnalyzed(candidate, analysis, classification))
                        }
                        await send(.scanCompleted)
                    } catch is CancellationError {
                        await send(.cancelButtonTapped)
                    } catch {
                        await send(.candidatesResponse(.failure("스캔에 실패했습니다.")))
                    }
                }
                .cancellable(id: CancelID.scan, cancelInFlight: true)

            case let .candidatesResponse(.success(candidates)):
                state.progress.candidateCount = candidates.count
                state.progress.phase = .analyzing
                return .none

            case let .candidatesResponse(.failure(message)):
                state.progress.phase = .failed(message)
                return .none

            case let .candidateAnalyzed(_, _, classification):
                state.progress.analyzedCount += 1
                if classification.category == .unknown {
                    state.progress.unknownCount += 1
                } else {
                    state.progress.classifiedCount += 1
                }
                return .none

            case .candidateSkipped:
                return .none

            case .scanCompleted:
                state.progress.phase = .completed
                state.isSummaryVisible = true
                return .send(.delegate(.finished))

            case .cancelButtonTapped:
                state.progress.phase = .cancelled
                return .cancel(id: CancelID.scan)

            case .delegate:
                return .none
            }
        }
    }
}
```

- [ ] **Step 3: ScanView 작성**

Create `CaptureBox/Features/Scan/ScanView.swift`:

```swift
import ComposableArchitecture
import SwiftUI

struct ScanView: View {
    let store: StoreOf<ScanFeature>

    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)
            Text(store.progress.phase.title)
                .font(.title2.bold())
            Text("\(store.progress.analyzedCount) / \(store.progress.candidateCount)개 분석")
                .foregroundStyle(.secondary)
            Button("최근 1년 스캔") {
                store.send(.startButtonTapped(.recentYear))
            }
            .buttonStyle(.borderedProminent)
            Button("취소") {
                store.send(.cancelButtonTapped)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
```

- [ ] **Step 4: 테스트 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/ScanFeatureTests
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add CaptureBox/Features/Scan CaptureBoxTests/ScanFeatureTests.swift
git commit -m "feat: add TCA scan feature"
```

---

### Task 7: LibraryFeature와 보관함 화면

**Files:**
- Modify: `CaptureBox/Features/Library/LibraryFeature.swift`
- Modify: `CaptureBox/Features/Library/LibraryView.swift`
- Test: `CaptureBoxTests/LibraryFeatureTests.swift`

- [ ] **Step 1: LibraryFeature 테스트 작성**

Create `CaptureBoxTests/LibraryFeatureTests.swift`:

```swift
import ComposableArchitecture
import XCTest
@testable import CaptureBox

@MainActor
final class LibraryFeatureTests: XCTestCase {
    func testLoadItemsBuildsCounts() async {
        let image = CapturedImage(
            assetLocalIdentifier: "asset-1",
            sourceKind: .screenshot,
            creationDate: nil,
            addedDate: nil,
            recognizedText: "쿠폰",
            detectedCodes: [],
            category: .coupon,
            confidence: 0.8,
            reviewStatus: .new,
            isSensitive: false,
            lastAnalyzedAt: Date()
        )

        let store = TestStore(initialState: LibraryFeature.State()) {
            LibraryFeature()
        } withDependencies: {
            $0.capturedImageRepository.all = { [image] }
        }

        await store.send(.task)
        await store.receive(.itemsResponse(.success([image]))) {
            $0.items = [image]
            $0.categoryCounts[.coupon] = 1
        }
    }
}
```

- [ ] **Step 2: LibraryFeature 구현**

Replace `CaptureBox/Features/Library/LibraryFeature.swift`:

```swift
import ComposableArchitecture

@Reducer
struct LibraryFeature {
    @ObservableState
    struct State: Equatable {
        var items: [CapturedImage] = []
        var categoryCounts: [CaptureCategory: Int] = [:]
        var scan: ScanFeature.State?
    }

    enum Action: Equatable {
        case task
        case itemsResponse(Result<[CapturedImage], String>)
        case scanButtonTapped
        case scan(PresentationAction<ScanFeature.Action>)
    }

    @Dependency(\.capturedImageRepository) var repository

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    do {
                        await send(.itemsResponse(.success(try await repository.all())))
                    } catch {
                        await send(.itemsResponse(.failure("보관함을 불러오지 못했습니다.")))
                    }
                }

            case let .itemsResponse(.success(items)):
                state.items = items
                state.categoryCounts = Dictionary(grouping: items, by: \.category).mapValues(\.count)
                return .none

            case .itemsResponse(.failure):
                return .none

            case .scanButtonTapped:
                state.scan = ScanFeature.State()
                return .none

            case .scan(.presented(.delegate(.finished))):
                state.scan = nil
                return .send(.task)

            case .scan:
                return .none
            }
        }
        .ifLet(\.$scan, action: \.scan) {
            ScanFeature()
        }
    }
}
```

- [ ] **Step 3: LibraryView 구현**

Replace `CaptureBox/Features/Library/LibraryView.swift`:

```swift
import ComposableArchitecture
import SwiftUI

struct LibraryView: View {
    @Bindable var store: StoreOf<LibraryFeature>

    var body: some View {
        NavigationStack {
            List {
                ForEach(CaptureCategory.allCases) { category in
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
                        Text("\(store.categoryCounts[category, default: 0])")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("보관함")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink("검색") {
                        SearchView(store: Store(initialState: SearchFeature.State()) {
                            SearchFeature()
                        })
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("스캔") {
                        store.send(.scanButtonTapped)
                    }
                }
            }
            .task {
                await store.send(.task).finish()
            }
            .sheet(item: $store.scope(state: \.scan, action: \.scan)) { scanStore in
                ScanView(store: scanStore)
            }
        }
    }
}
```

- [ ] **Step 4: 테스트와 빌드 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/LibraryFeatureTests
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: both commands succeed after Task 8 creates `SearchFeature`.

- [ ] **Step 5: Commit은 Task 8 후 함께 진행**

Task 8에서 `SearchFeature`를 추가한 뒤 Library와 Search를 함께 커밋한다.

---

### Task 8: SearchFeature와 OCR 검색

**Files:**
- Create: `CaptureBox/Features/Search/SearchFeature.swift`
- Create: `CaptureBox/Features/Search/SearchView.swift`
- Test: `CaptureBoxTests/SearchFeatureTests.swift`

- [ ] **Step 1: SearchFeature 테스트 작성**

Create `CaptureBoxTests/SearchFeatureTests.swift`:

```swift
import ComposableArchitecture
import XCTest
@testable import CaptureBox

@MainActor
final class SearchFeatureTests: XCTestCase {
    func testSearchReturnsResults() async {
        let image = CapturedImage(
            assetLocalIdentifier: "asset-1",
            sourceKind: .screenshot,
            creationDate: nil,
            addedDate: nil,
            recognizedText: "배송 운송장",
            detectedCodes: [],
            category: .delivery,
            confidence: 0.8,
            reviewStatus: .new,
            isSensitive: false,
            lastAnalyzedAt: Date()
        )

        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.capturedImageRepository.search = { query in
                query == "배송" ? [image] : []
            }
        }

        await store.send(.queryChanged("배송")) {
            $0.query = "배송"
        }
        await store.receive(.searchResponse(.success([image]))) {
            $0.results = [image]
        }
    }
}
```

- [ ] **Step 2: SearchFeature 구현**

Create `CaptureBox/Features/Search/SearchFeature.swift`:

```swift
import ComposableArchitecture

@Reducer
struct SearchFeature {
    @ObservableState
    struct State: Equatable {
        var query = ""
        var results: [CapturedImage] = []
    }

    enum Action: Equatable {
        case queryChanged(String)
        case searchResponse(Result<[CapturedImage], String>)
    }

    @Dependency(\.capturedImageRepository) var repository

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .queryChanged(query):
                state.query = query
                return .run { send in
                    do {
                        await send(.searchResponse(.success(try await repository.search(query))))
                    } catch {
                        await send(.searchResponse(.failure("검색에 실패했습니다.")))
                    }
                }

            case let .searchResponse(.success(results)):
                state.results = results
                return .none

            case .searchResponse(.failure):
                state.results = []
                return .none
            }
        }
    }
}
```

- [ ] **Step 3: SearchView 구현**

Create `CaptureBox/Features/Search/SearchView.swift`:

```swift
import ComposableArchitecture
import SwiftUI

struct SearchView: View {
    @Bindable var store: StoreOf<SearchFeature>

    var body: some View {
        List {
            ForEach(store.results) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.category.title)
                        .font(.headline)
                    Text(item.recognizedText)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("검색")
        .searchable(text: $store.query.sending(\.queryChanged), prompt: "쿠폰, 배송, 운송장, 주소")
    }
}
```

- [ ] **Step 4: 테스트와 빌드 확인**

Run:

```bash
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/SearchFeatureTests
xcodebuild test -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CaptureBoxTests/LibraryFeatureTests
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: all commands succeed.

- [ ] **Step 5: Commit**

```bash
git add CaptureBox/Features/Library CaptureBox/Features/Search CaptureBoxTests/LibraryFeatureTests.swift CaptureBoxTests/SearchFeatureTests.swift
git commit -m "feat: add TCA library and search features"
```

---

### Task 9: ImageDetailFeature와 카테고리 수정

**Files:**
- Create: `CaptureBox/Features/ImageDetail/ImageDetailFeature.swift`
- Create: `CaptureBox/Features/ImageDetail/ImageDetailView.swift`
- Modify: `CaptureBox/Features/Search/SearchView.swift`
- Test: build

- [ ] **Step 1: ImageDetailFeature 작성**

Create `CaptureBox/Features/ImageDetail/ImageDetailFeature.swift`:

```swift
import ComposableArchitecture

@Reducer
struct ImageDetailFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var id: String { item.id }
        var item: CapturedImage
    }

    enum Action: Equatable {
        case categoryChanged(CaptureCategory)
        case categorySaved(Result<CaptureCategory, String>)
    }

    @Dependency(\.capturedImageRepository) var repository

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .categoryChanged(category):
                state.item.category = category
                state.item.reviewStatus = .changedByUser
                state.item.isSensitive = category.isSensitive
                let id = state.item.assetLocalIdentifier
                return .run { send in
                    do {
                        try await repository.updateCategory(id, category)
                        await send(.categorySaved(.success(category)))
                    } catch {
                        await send(.categorySaved(.failure("카테고리를 저장하지 못했습니다.")))
                    }
                }

            case .categorySaved:
                return .none
            }
        }
    }
}
```

- [ ] **Step 2: ImageDetailView 작성**

Create `CaptureBox/Features/ImageDetail/ImageDetailView.swift`:

```swift
import ComposableArchitecture
import SwiftUI

struct ImageDetailView: View {
    @Bindable var store: StoreOf<ImageDetailFeature>

    var body: some View {
        Form {
            Section("분류") {
                Picker(
                    "카테고리",
                    selection: $store.item.category.sending(\.categoryChanged)
                ) {
                    ForEach(CaptureCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
            }

            Section("분석 정보") {
                LabeledContent("신뢰도", value: "\(Int(store.item.confidence * 100))%")
                LabeledContent("민감 정보", value: store.item.isSensitive ? "예" : "아니오")
                LabeledContent("코드 감지", value: store.item.detectedCodes.isEmpty ? "없음" : "\(store.item.detectedCodes.count)개")
            }

            Section("OCR 텍스트") {
                Text(store.item.recognizedText.isEmpty ? "인식된 텍스트가 없습니다." : store.item.recognizedText)
                    .textSelection(.enabled)
            }
        }
        .navigationTitle(store.item.category.title)
    }
}
```

- [ ] **Step 3: SearchView에서 상세 진입 추가**

Replace row in `CaptureBox/Features/Search/SearchView.swift`:

```swift
NavigationLink {
    ImageDetailView(
        store: Store(initialState: ImageDetailFeature.State(item: item)) {
            ImageDetailFeature()
        }
    )
} label: {
    VStack(alignment: .leading, spacing: 4) {
        Text(item.category.title)
            .font(.headline)
        Text(item.recognizedText)
            .font(.caption)
            .lineLimit(2)
            .foregroundStyle(.secondary)
    }
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
git add CaptureBox/Features/ImageDetail CaptureBox/Features/Search/SearchView.swift
git commit -m "feat: add TCA image detail editing"
```

---

### Task 10: SettingsFeature와 권한 상태

**Files:**
- Create: `CaptureBox/Features/Settings/SettingsFeature.swift`
- Create: `CaptureBox/Features/Settings/SettingsView.swift`
- Modify: `CaptureBox/Features/Library/LibraryView.swift`

- [ ] **Step 1: SettingsFeature 작성**

Create `CaptureBox/Features/Settings/SettingsFeature.swift`:

```swift
import ComposableArchitecture
import Photos

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        var authorizationStatus: PHAuthorizationStatus = .notDetermined
    }

    enum Action: Equatable {
        case task
        case authorizationStatusLoaded(PHAuthorizationStatus)
        case manageLimitedLibraryTapped
    }

    @Dependency(\.photoLibraryClient) var photoLibraryClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .send(.authorizationStatusLoaded(photoLibraryClient.authorizationStatus()))

            case let .authorizationStatusLoaded(status):
                state.authorizationStatus = status
                return .none

            case .manageLimitedLibraryTapped:
                return .run { _ in
                    await photoLibraryClient.presentLimitedLibraryPicker()
                }
            }
        }
    }
}
```

- [ ] **Step 2: SettingsView 작성**

Create `CaptureBox/Features/Settings/SettingsView.swift`:

```swift
import ComposableArchitecture
import Photos
import SwiftUI

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>

    var body: some View {
        Form {
            Section("사진 권한") {
                LabeledContent("현재 상태", value: statusTitle)
                if store.authorizationStatus == .limited {
                    Button("선택한 사진 관리") {
                        store.send(.manageLimitedLibraryTapped)
                    }
                }
            }
            Section("개인정보") {
                Text("CaptureBox는 MVP에서 스크린샷과 저장 이미지를 서버로 업로드하지 않습니다. 분석은 기기 안에서만 진행되며 Photos 원본을 삭제하거나 이동하지 않습니다.")
            }
        }
        .navigationTitle("설정")
        .task {
            await store.send(.task).finish()
        }
    }

    private var statusTitle: String {
        switch store.authorizationStatus {
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

- [ ] **Step 3: LibraryView에 설정 메뉴 추가**

Replace toolbar in `CaptureBox/Features/Library/LibraryView.swift`:

```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        NavigationLink("검색") {
            SearchView(store: Store(initialState: SearchFeature.State()) {
                SearchFeature()
            })
        }
    }
    ToolbarItem(placement: .topBarTrailing) {
        Menu {
            Button("스캔") {
                store.send(.scanButtonTapped)
            }
            NavigationLink("설정") {
                SettingsView(store: Store(initialState: SettingsFeature.State()) {
                    SettingsFeature()
                })
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
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
git add CaptureBox/Features/Settings CaptureBox/Features/Library/LibraryView.swift
git commit -m "feat: add TCA settings feature"
```

---

### Task 11: 썸네일 표시

**Files:**
- Create: `CaptureBox/Views/AssetThumbnailView.swift`
- Modify: `CaptureBox/Features/Library/LibraryView.swift`

- [ ] **Step 1: AssetThumbnailView 작성**

Create `CaptureBox/Views/AssetThumbnailView.swift`:

```swift
import ComposableArchitecture
import SwiftUI

struct AssetThumbnailView: View {
    let assetLocalIdentifier: String
    @Dependency(\.photoLibraryClient) var photoLibraryClient
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
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
            image = await photoLibraryClient.requestImage(
                assetLocalIdentifier,
                CGSize(width: 300, height: 300)
            )
        }
    }
}
```

- [ ] **Step 2: LibraryView는 MVP에서 카운트 중심 유지**

MVP 보관함은 카테고리 카운트 중심으로 둔다. 썸네일은 검색/상세 화면 확장 시 사용한다. 이 단계에서는 `AssetThumbnailView` 빌드 가능성만 확보한다.

- [ ] **Step 3: 빌드 확인**

Run:

```bash
xcodebuild -project CaptureBox.xcodeproj -scheme CaptureBox -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add CaptureBox/Views/AssetThumbnailView.swift
git commit -m "feat: add reusable asset thumbnail view"
```

---

### Task 12: QA 문서와 MVP 검증

**Files:**
- Create: `docs/qa/mvp-manual-test.md`

- [ ] **Step 1: QA 문서 작성**

Create `docs/qa/mvp-manual-test.md`:

```markdown
# CaptureBox MVP 수동 QA

## 권한

- [ ] 첫 실행에서 사진 권한 안내가 한국어로 보인다.
- [ ] 선택한 사진만 허용해도 앱이 보관함으로 진입한다.
- [ ] 전체 접근 허용 시 최근 1년 스캔이 가능하다.
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
- [ ] 결과가 없을 때 앱이 크래시하지 않는다.

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

- 사진 접근 권한: Task 3, Task 4, Task 5, Task 10
- 최근 1년 스캔: Task 4, Task 6
- 스크린샷과 저장 이미지 후보: Task 4
- OCR/QR/바코드 분석: Task 4
- 규칙 기반 자동 분류: Task 4, Task 6
- 6개 카테고리와 미분류: Task 2, Task 4, Task 6, Task 7
- 앱 내부 보관함: Task 7
- OCR 검색: Task 8
- 상세 화면 카테고리 변경: Task 9
- 첫 스캔 진행/요약: Task 6
- Photos 원본 수정 제외: Task 10, Task 12
- 광고 제외: Task 12
- Gemma 4 E2B 제외: Task 12
- TCA 일원화: Task 1부터 Task 10까지 전체 적용
- Repository 레이어: Task 3, Task 4

### 범위 확인

이 계획은 MVP 하나에 집중한다. App Store 출시 메타데이터, AdMob, Photos 앨범 생성, Face ID, 만료일 알림, Gemma 4 E2B는 포함하지 않는다.

### 구현 주의사항

- TCA와 SwiftUI Observation 기반 API를 사용한다.
- 화면별 ViewModel은 만들지 않는다.
- `ScanCoordinator`는 만들지 않는다.
- 복잡한 외부 작업은 TCA Dependency Client로 격리한다.
- 저장소는 `CapturedImageRepository`로 추상화한다.
- 사용자가 카테고리를 직접 바꾼 항목은 재스캔으로 덮어쓰지 않는다.
- Vision OCR은 한국어/영어 혼합 이미지를 실제 기기에서 반드시 테스트한다.
- 성능 문제가 있으면 `ScanFeature` effect 내부를 배치 처리로 쪼갠다.
