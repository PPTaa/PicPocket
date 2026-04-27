# 스크린샷 정리 앱 기획서

작성일: 2026-04-24
플랫폼: iOS 전용
최소 타겟: iOS 18
수익화 방향: AdMob 또는 유사 인앱 광고
현재 단계: 초기 아이디어 브레인스토밍 및 MVP 기획

## 한 줄 아이디어

아이폰 사용자가 찍어둔 스크린샷을 자동으로 찾아 쿠폰, 영수증, 티켓, 배송 정보, 주소, 계좌/결제 메모, 나중에 볼 항목 등으로 분류하고 정리해주는 iOS 앱.

## 제품 가설

사람들은 스크린샷을 자주 찍지만 거의 정리하지 않는다. 그런데 스크린샷 안에는 생각보다 유용한 정보가 많다.

- 쿠폰
- QR 코드
- 바코드
- 예약 내역
- 티켓
- 영수증
- 배송 조회 번호
- 주소
- 계좌번호
- 결제 정보
- 쇼핑 비교 자료
- 나중에 다시 보려고 저장한 글이나 이미지

이 앱의 핵심은 지저분한 스크린샷 더미를 실용적인 정보 보관함으로 바꾸는 것이다.

단순한 "사진 정리 앱"보다는 아래 포지셔닝이 더 좋다.

> 스크린샷 속 쓸모 있는 정보를 자동으로 모아주는 스마트 보관함.

## 타겟 사용자

- 스크린샷을 자주 찍는 아이폰 사용자
- 온라인 쇼핑을 자주 하는 사용자
- 쿠폰, 티켓, 영수증, 배송 정보, 예약 내역을 스크린샷으로 저장하는 사용자
- 사진 앱에서 직접 앨범을 만들고 정리하는 것이 귀찮은 사용자
- 필요한 스크린샷을 나중에 찾지 못해 불편함을 느낀 사용자

## 핵심 사용 흐름

1. 사용자가 앱을 실행한다.
2. 앱이 사진 접근 권한이 필요한 이유를 설명한다.
3. 사용자가 사진 접근을 허용한다.
4. 앱이 사진 보관함에서 스크린샷만 가져온다.
5. 앱이 스크린샷을 분석해 카테고리별로 분류한다.
6. 사용자는 추천 분류 결과를 확인한다.
7. 사용자는 앱 안에서만 정리된 상태로 사용할 수도 있고, 원하면 Apple Photos 안에 실제 앨범을 생성할 수도 있다.

## iOS / PhotoKit 구현 가능성

이 아이디어는 Apple의 PhotoKit을 사용하면 iOS에서 구현 가능하다.

중요한 기술 메모:

- 스크린샷은 `PHAssetMediaSubtype.photoScreenshot`으로 식별할 수 있다.
- 사진 라이브러리 접근은 `PHPhotoLibrary`를 통해 권한을 요청하고 처리한다.
- 앱은 `PHAssetCollectionChangeRequest`를 사용해 Photos 앱 안에 앨범을 만들 수 있다.
- 앱은 기존 사진 에셋을 특정 앨범에 추가할 수 있다.
- 앱은 `PHCollectionListChangeRequest`를 사용해 Photos의 폴더 또는 컬렉션 리스트를 만들 수 있다.
- 다만 Photos의 폴더는 사진 자체를 직접 담는 공간이라기보다 앨범들을 묶는 컨테이너에 가깝다.
- Photos에서 사진을 앨범에 추가해도 원본 사진이 "최근 항목"이나 전체 라이브러리에서 사라지는 것은 아니다.
- 즉, 파일을 실제로 이동한다기보다는 사진 에셋을 앨범에 연결하는 방식에 가깝다.
- 자동 삭제나 대량 삭제는 사용자 신뢰와 App Review 리스크가 크므로 MVP에는 넣지 않는 것이 좋다.
- 사용자가 "선택한 사진만 허용"한 경우에는 선택된 사진만 접근할 수 있으므로 제한된 상태에서도 앱이 동작해야 한다.

필요할 가능성이 높은 권한 설명:

- `NSPhotoLibraryUsageDescription`: 스크린샷을 읽고 분류하기 위한 사진 접근 설명.
- `NSPhotoLibraryAddUsageDescription`: 사용자의 사진 라이브러리에 앨범을 만들거나 사진을 추가하기 위한 설명.

## 추천 MVP

초기 버전은 유용성이 높고 리스크가 낮은 범위로 시작하는 것이 좋다.

## MVP 범위

- 사진 접근 권한 요청
- 사진 보관함에서 스크린샷만 가져오기
- 앱 내부에서 스마트 폴더 형태로 스크린샷 분류해 보여주기
- 소수의 실용적인 카테고리로 자동 분류
- 사용자가 확인한 뒤 Photos 앨범 생성
- 검색 기능
- 분류 확신도가 낮은 스크린샷을 따로 모아 검토 큐로 보여주기

## 초기 카테고리

- 쿠폰
- 영수증
- 티켓 및 예약
- 배송 및 운송장
- 주소 및 지도
- 계좌/결제 메모
- 상품 비교
- 나중에 볼 것
- 미분류 / 검토 필요

## MVP 이후 추가하면 좋은 기능

- OCR 기반 텍스트 검색
- QR 코드 및 바코드 인식
- 쿠폰, 티켓, 예약 내역의 만료일 감지
- 만료 예정 쿠폰이나 다가오는 예약 알림
- 중복 또는 유사 스크린샷 감지
- 여러 장 한 번에 처리하는 일괄 작업
- 오늘 정리한 스크린샷 요약
- 민감한 카테고리 Face ID 잠금
- Shortcuts / App Intents 연동
- iOS 18 이상에서 Control Center 빠른 실행 버튼
- Gemma 4 E2B 같은 온디바이스 LLM을 활용한 정밀 분류 옵션

## 분류 방식

가능하면 온디바이스 처리부터 우선한다.

사용할 수 있는 신호:

- 스크린샷 OCR 텍스트
- 날짜 감지
- 가격 감지
- 배송 조회 번호 감지
- QR 코드 및 바코드 감지
- 앱 또는 이미지 메타데이터
- 이미지 비율과 화면 레이아웃
- MVP 단계에서는 키워드 기반 분류
- 이후 필요하면 경량 ML 분류 모델 적용

MVP에서는 단순 키워드 기반으로 시작해도 충분하다.

예시 키워드:

- 쿠폰: 쿠폰, 할인, 적립, 바코드, QR, 유효기간, 만료
- 영수증: 영수증, 결제, 합계, 총액, 주문번호, 승인번호
- 티켓/예약: 티켓, 예매, 예약, 좌석, 탑승권, 체크인, 게이트
- 배송: 배송, 운송장, 택배, 송장번호, 배송조회, 출고
- 주소/지도: 주소, 지도, 길찾기, 도로명, 위치
- 계좌/결제: 계좌, 이체, 입금, 결제, 카드, 은행
- 상품 비교: 장바구니, 가격, 옵션, 상품명, 리뷰
- 나중에 볼 것: 저장, 메모, 읽기, 참고, 캡처

## 수익화 가설

이 앱은 자주 열어보는 가벼운 유틸리티가 되면 광고 수익화와 잘 맞는다.

광고를 넣기 좋은 위치:

- 스크린샷 그룹 또는 목록 섹션 사이 네이티브 광고
- 중요하지 않은 탐색 화면 하단 배너 광고
- 정리 또는 검토 세션 완료 후 전면 광고
- 무료 일일 한도를 초과한 대량 정리에 보상형 광고

피해야 할 광고 위치:

- 사용자가 앱의 가치를 보기 전
- 사진 권한 요청 흐름 중간
- 스크린샷 검토나 분류 작업 도중
- 삭제 또는 민감한 작업 근처
- 너무 잦은 전면 광고

가능한 프리미엄 모델:

- 기본 무료 + 광고
- 유료 업그레이드로 광고 제거
- 유료 업그레이드로 무제한 일괄 처리
- 유료 업그레이드로 Face ID 보안 폴더
- 유료 업그레이드로 고급 OCR 검색
- 유료 업그레이드로 쿠폰/티켓 만료 알림

## 신뢰와 개인정보 원칙

이 앱은 사용자의 사진을 다루기 때문에 신뢰가 가장 중요하다.

제품 원칙:

- 왜 사진 접근이 필요한지 명확하게 설명한다.
- MVP에서는 OCR과 분류를 가능한 한 온디바이스로 처리한다.
- 기본적으로 스크린샷을 서버에 업로드하지 않는다.
- 클라우드 AI 분석을 추가한다면 반드시 명시적 동의를 받는다.
- 사진을 자동으로 삭제하지 않는다.
- Photos 앨범 생성 전에는 사용자가 미리 보고 확인하게 한다.
- "앱 안에서 정리"와 "Photos 앱에 앨범 생성"을 명확히 구분한다.
- 계좌/결제 같은 민감 카테고리는 특히 조심스럽게 다룬다.

## UX 방향

앱은 시끄러운 클리너 앱이 아니라 조용하고 믿을 수 있는 생활 유틸리티처럼 느껴져야 한다.

추천 화면 구조:

- Inbox: 아직 검토하지 않은 스크린샷
- Smart Folders: 자동 분류된 스크린샷
- Search: OCR 텍스트 검색
- Clean Up: 추천 분류 확인 및 일괄 처리
- Settings: 권한, 개인정보, 광고 제거, Photos 앨범 동기화

첫 실행 흐름:

1. 짧은 설명: "스크린샷 속 필요한 정보를 자동으로 찾아 정리합니다."
2. 사진 접근 권한 요청
3. 스크린샷 스캔
4. 분류된 결과 미리보기
5. Photos 앱에 앨범을 만들지 여부 선택

## 기술 방향

예상 기술 스택:

- SwiftUI: UI 구현
- The Composable Architecture: 앱 상태, 화면 상태, 비동기 effect, 테스트 구조 일원화
- Photos / PhotoKit: 스크린샷 접근 및 앨범 관리
- Vision framework: OCR, QR 코드, 바코드 인식
- App Intents / Shortcuts: iOS 18 이후 빠른 실행 및 자동화
- SwiftData: 로컬 분류 메타데이터 저장
- AdMob iOS SDK: 광고 수익화
- 추후 Gemma 4 E2B / LiteRT-LM: 온디바이스 AI 정밀 분류

아키텍처 방향:

- 전체 앱 구조는 TCA 중심으로 일원화한다.
- SwiftUI View는 `StoreOf<Feature>`를 관찰하고 Action을 보내는 역할만 한다.
- 화면별 ViewModel은 만들지 않는다.
- 긴 스캔 흐름을 처리하는 별도 `ScanCoordinator`는 만들지 않고 `ScanFeature`의 Effect로 처리한다.
- PhotoKit, Vision, Classification, Repository는 TCA Dependency Client로 주입한다.
- 저장소 접근은 `CapturedImageRepository`로 추상화한다.
- Live 구현은 PhotoKit, Vision, SwiftData를 직접 호출한다.
- 테스트에서는 Dependency를 교체해 권한, 후보 이미지, OCR 결과, 저장 결과를 제어한다.

기본 구조:

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

주요 Feature:

- `AppFeature`: 앱 루트 상태, 온보딩 완료 여부, 하위 Feature 조합
- `OnboardingFeature`: 사진 권한 요청과 온보딩 완료
- `LibraryFeature`: 카테고리별 보관함, 스캔 화면 표시, 검색/설정 진입
- `ScanFeature`: 최근 1년/전체 기간 스캔, OCR, 분류, 저장, 취소, 진행률
- `SearchFeature`: OCR 텍스트 검색
- `ImageDetailFeature`: 상세 정보 표시와 카테고리 수동 변경
- `SettingsFeature`: 권한 상태, 선택한 사진 관리, 개인정보 설명

주요 Dependency Client:

- `PhotoLibraryClient`: 권한, 후보 이미지 조회, 썸네일/분석용 이미지 요청
- `VisionClient`: OCR, QR 코드, 바코드 감지
- `ClassificationClient`: 규칙 기반 카테고리 분류
- `CapturedImageRepository`: SwiftData 기반 저장/조회/검색/카테고리 수정

예상 로컬 데이터 모델:

`CapturedImage`

- `assetLocalIdentifier`
- `sourceKind`
- `creationDate`
- `addedDate`
- `recognizedText`
- `detectedCodes`
- `category`
- `confidence`
- `reviewStatus`
- `isSensitive`
- `lastAnalyzedAt`

`CaptureCategory`

- `coupon`
- `receipt`
- `delivery`
- `ticketReservation`
- `addressMap`
- `payment`
- `unknown`

`ScanProgress`

- `phase`
- `candidateCount`
- `analyzedCount`
- `classifiedCount`
- `unknownCount`

SwiftData 저장 모델:

- `CapturedImageRecord`
- `ScanSessionRecord`

SwiftData 모델은 앱 내부 저장 형식이고, 화면과 Feature에서는 도메인 모델인 `CapturedImage`를 사용한다.

## 추후 개발 사항: Gemma 4 E2B 온디바이스 AI 분류

MVP에서는 Gemma 4 E2B를 필수 기능으로 넣지 않는다. 초기 버전은 PhotoKit, Vision OCR, QR/바코드 인식, 키워드/정규식 기반 분류만으로 충분히 검증한다.

다만 v1.1 또는 v2 단계에서 Gemma 4 E2B 같은 온디바이스 LLM을 선택형 고급 기능으로 추가하는 방향은 매우 좋다. 이 기능은 "서버에 사진을 올리지 않고 기기 안에서 더 똑똑하게 분류한다"는 강한 개인정보 메시지를 만들 수 있다.

추천 사용 방식:

- 모든 스크린샷을 Gemma로 처리하지 않는다.
- Vision OCR과 규칙 기반 분류를 먼저 수행한다.
- 분류 신뢰도가 낮은 스크린샷만 Gemma에 넘긴다.
- 가능하면 원본 이미지보다 OCR 텍스트, 감지된 QR/바코드 여부, 날짜/가격/키워드 후보를 구조화해서 전달한다.
- Gemma의 응답은 자유 텍스트가 아니라 JSON 형태로 받는다.
- 사용자가 "온디바이스 AI 정밀 분류"를 켰을 때만 모델을 다운로드한다.

예상 프롬프트 방향:

```text
다음 스크린샷 OCR 텍스트와 감지 정보를 보고 카테고리를 하나만 선택해줘.
카테고리: coupon, receipt, ticket, delivery, address, payment, product_compare, read_later, unknown
반환 형식은 JSON만 사용해.
필드: category, confidence, reason, detectedDate, sensitive
```

예상 JSON 응답:

```json
{
  "category": "coupon",
  "confidence": 0.86,
  "reason": "할인, 쿠폰, 유효기간 키워드와 바코드가 감지됨",
  "detectedDate": "2026-05-31",
  "sensitive": false
}
```

구현 메모:

- iOS 앱에서는 LiteRT-LM 또는 Google AI Edge 계열 런타임을 검토한다.
- SwiftUI 앱에서 바로 쓰기 어려운 경우 C++ / Objective-C++ 브릿지를 사용한다.
- 브릿지 구현은 향후 개발자가 직접 할 수 있으므로 기획 단계에서 배제하지 않는다.
- 모델 파일 크기가 클 수 있으므로 앱 번들에 기본 포함하기보다 선택 다운로드를 우선 검토한다.
- 모델 로딩 시간, 메모리, 발열, 배터리 사용량을 실제 기기에서 반드시 측정한다.
- 구형 iPhone에서는 비활성화하거나 "고성능 기기 권장" 안내를 제공할 수 있다.
- App Store 심사를 위해 다운로드 모델의 역할, 개인정보 처리, 오프라인 추론 여부를 명확히 설명한다.

제품 내 포지셔닝:

- 기본 정리: 빠르고 가벼운 로컬 분류
- AI 정밀 분류: 더 애매한 스크린샷까지 이해하는 온디바이스 고급 기능
- 프리미엄 후보: 광고 제거와 함께 묶거나, 무료 사용자는 일일 AI 정밀 분류 횟수를 제한할 수 있다.

## 주요 제품 리스크

- 사용자가 전체 사진 접근 권한을 꺼릴 수 있다.
- 초기 OCR 및 분류 정확도가 낮을 수 있다.
- 앱이 저품질 광고 앱처럼 보이면 App Store Review 리스크가 생길 수 있다.
- 광고 빈도가 높으면 신뢰가 무너질 수 있다.
- Photos 앨범 동작이 사용자의 "파일 이동" 기대와 다를 수 있다.
- 유사한 사진 정리 앱이 이미 존재하므로 차별화가 필요하다.

## 리스크 완화 방법

- 선택한 사진만 허용한 상태에서도 기본 기능이 동작하게 한다.
- 다만 전체 접근 권한을 허용하면 자동 정리가 더 잘 된다는 점을 설명한다.
- MVP에서는 모든 처리를 로컬 중심으로 설계한다.
- 사용자가 첫 번째 가치를 경험한 뒤에만 광고를 노출한다.
- Photos 라이브러리를 수정하는 모든 작업은 확인 단계를 둔다.
- MVP에서는 삭제 기능을 제외한다.
- UI를 차분하고 고급스럽게 만든다.
- 카테고리는 실생활에서 바로 쓸모 있는 항목으로 좁힌다.

## 초기 성공 지표

- 사진 접근 권한 허용률
- 사용자당 스캔된 스크린샷 수
- 자동 분류된 스크린샷 수
- 사용자가 수정하지 않고 받아들인 분류 비율
- 생성된 Photos 앨범 수
- 일간 활성 사용자 수
- 주간 정리 세션 수
- 활성 사용자당 광고 노출 수
- 광고 제거 또는 프리미엄 전환율

## 앱 이름

선정된 이름:

- `PicPocket`

브랜드 방향:

- 앱 표시 이름: `PicPocket`
- 프로젝트명: `PicPocket`
- 핵심 카피: 사진 속 필요한 것만 쏙
- 설명 카피: 스크린샷과 저장 이미지 속 쿠폰, 영수증, 배송, 예약 정보를 기기 안에서 정리합니다.

이름 후보 기록:

영문 후보:

- SnapSort
- Screenshot Wallet
- ScreenShelf
- SnapFolder
- ShotKeeper
- PicPocket
- ClipShot
- SortShot

한국어 후보:

- 스샷정리
- 캡처지갑
- 스샷함
- 픽포켓
- 스샷폴더
- 캡처보관함
- 스크린샷 지갑

## 아직 결정해야 할 질문

- 첫 시장을 한국어 전용으로 할 것인가, 영어 전용으로 할 것인가, 아니면 처음부터 다국어로 갈 것인가?
- 민감 카테고리의 Face ID 잠금을 v1.1에 넣을 것인가, v2로 미룰 것인가?
- 삭제/정리 기능을 나중에 추가할 것인가, 아니면 계속 분류와 보관 중심으로 갈 것인가?
- 광고는 v1.1부터 넣을 것인가, 리텐션 검증 이후 더 늦게 넣을 것인가?
- 광고 제거 인앱 결제를 광고 도입과 함께 넣을 것인가?
- 무료 사용자의 일괄 처리 한도를 둘 것인가?
- Gemma 4 E2B 온디바이스 AI 정밀 분류를 프리미엄 기능으로 둘 것인가?

## 현재 승인된 MVP 결정

- MVP 목표는 자동 분류 검증이다.
- 앱 이름/프로젝트명은 `PicPocket`을 사용한다.
- 구현 아키텍처는 TCA 중심으로 일원화한다.
- Repository 레이어를 둔다.
- 화면별 ViewModel과 별도 `ScanCoordinator`는 만들지 않는다.
- 대상은 스크린샷과 저장 이미지다.
- 첫 스캔은 최근 1년 기본, 전체 기간은 옵션이다.
- 카테고리는 쿠폰, 영수증, 배송, 티켓/예약, 주소/지도, 계좌/결제, 미분류로 시작한다.
- Photos 앨범 생성은 MVP에서 제외한다.
- 사진 삭제와 이동은 MVP에서 제외한다.
- OCR 텍스트 검색은 MVP에 포함한다.
- 광고는 MVP에서 제외한다.
- 권한은 선택 접근과 전체 접근을 모두 지원하되 전체 접근을 추천한다.
- Gemma 4 E2B는 추후 고급 기능으로 남긴다.

## 추천 다음 단계

MVP 설계 문서와 구현 계획서는 이미 작성되어 있다.

참고 문서:

- `docs/superpowers/specs/2026-04-25-screenshot-saved-image-mvp-design.md`
- `docs/superpowers/plans/2026-04-25-picpocket-mvp-implementation.md`

다음 단계:

1. TCA 기반 Xcode 프로젝트를 생성한다.
2. TCA 패키지를 추가한다.
3. 도메인 모델, Dependency Client, Repository 인터페이스부터 구현한다.
4. `ScanFeature`를 중심으로 PhotoKit, Vision, Classification, SwiftData 저장 흐름을 연결한다.
5. `OnboardingFeature`, `LibraryFeature`, `SearchFeature`, `ImageDetailFeature`, `SettingsFeature` 순서로 화면을 붙인다.
6. 실제 iPhone에서 사진 권한, OCR 품질, 스캔 성능을 검증한다.

## 이후 AI 에이전트를 위한 지침

Codex, Claude, Gemini 또는 다른 AI 에이전트가 이 프로젝트를 이어받는다면 아래 원칙을 따른다.

- 이 문서를 현재 제품 기획의 기준으로 사용한다.
- 세부 MVP 설계는 `docs/superpowers/specs/2026-04-25-screenshot-saved-image-mvp-design.md`를 따른다.
- 실제 구현 계획은 `docs/superpowers/plans/2026-04-25-picpocket-mvp-implementation.md`를 따른다.
- 핵심 아이디어는 "스크린샷과 저장 이미지 속 쓸모 있는 정보를 정리하는 앱"이다.
- 명시적 요청이 없다면 일반적인 사진 클리너 앱으로 방향을 바꾸지 않는다.
- 개인정보 보호, 로컬 처리, 사용자 신뢰를 최우선으로 둔다.
- 첫 버전에서는 사진 삭제 같은 파괴적 작업을 피한다.
- 구현은 SwiftUI + TCA + PhotoKit + Vision + SwiftData 기반으로 진행한다.
- TCA 구조를 유지하고 화면별 ViewModel 또는 별도 `ScanCoordinator`를 새로 만들지 않는다.
- PhotoKit, Vision, Classification, Repository는 TCA Dependency Client로 주입한다.
- 저장소 접근은 `CapturedImageRepository`를 통해 수행한다.
- 디자인을 한다면 시끄러운 광고 앱이 아니라 차분한 생활 유틸리티처럼 만든다.
- 광고를 넣는다면 사용자가 먼저 가치를 경험한 뒤 자연스러운 위치에 넣는다.

