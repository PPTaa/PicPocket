import ComposableArchitecture
import SwiftUI

struct ScanView: View {
    let store: StoreOf<ScanFeature>

    var body: some View {
        MockupScreen(title: "스캔") {
            VStack(spacing: 32) {
                rangePicker

                MockupCard(radius: MockupStyle.largeRadius) {
                    VStack(spacing: 24) {
                        if store.isScanning {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .controlSize(.large)
                                .tint(MockupStyle.accent)
                                .frame(width: 140, height: 140)
                                .background {
                                    Circle()
                                        .stroke(MockupStyle.surfaceMuted, lineWidth: 8)
                                }

                            Text(runningTitle)
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundStyle(MockupStyle.text)

                            Text("\(store.progress.analyzedCount) / \(max(store.progress.candidateCount, 0))")
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundStyle(MockupStyle.accent)
                                .monospacedDigit()

                            Text("분석 중에는 앱을 끄지 말아주세요.")
                                .font(.system(size: 14))
                                .foregroundStyle(MockupStyle.secondaryText)

                            Button("중단하기") {
                                store.send(.cancelButtonTapped)
                            }
                            .buttonStyle(MockupSecondaryButtonStyle())
                        } else {
                            Text("🔍")
                                .font(.system(size: 64))
                                .padding(.bottom, -8)

                            Text("분석할 이미지 찾기")
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundStyle(MockupStyle.text)

                            Text(scanDescription)
                                .font(.system(size: 14))
                                .foregroundStyle(MockupStyle.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)

                            progressStats

                            if let summary = store.summary {
                                Text("최근 스캔: 후보 \(summary.candidateCount)개, 분류 \(summary.classifiedCount)개")
                                    .font(.system(size: 13))
                                    .foregroundStyle(MockupStyle.secondaryText)
                            }

                            Button("분석 시작하기") {
                                store.send(.startButtonTapped(store.range))
                            }
                            .buttonStyle(MockupPrimaryButtonStyle())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 560, alignment: .center)
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 6) {
            rangeButton("최근 1년", .recentYear)
            rangeButton("전체 기간", .allTime)
        }
        .padding(6)
        .background(MockupStyle.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func rangeButton(_ title: String, _ range: ScanRange) -> some View {
        Button {
            store.send(.rangeSelected(range))
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(store.range == range ? MockupStyle.text : MockupStyle.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if store.range == range {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(MockupStyle.surface)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(store.isScanning)
    }

    private var progressStats: some View {
        HStack {
            stat("후보", store.progress.candidateCount)
            stat("분석", store.progress.analyzedCount)
            stat("분류", store.progress.classifiedCount)
            stat("미분류", store.progress.unknownCount)
        }
        .padding(.vertical, 8)
    }

    private func stat(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold))
                .monospacedDigit()
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MockupStyle.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var runningTitle: String {
        switch store.progress.phase {
        case .findingImages: "이미지 수집 중..."
        case .analyzing: "텍스트 분석 중..."
        case .saving: "저장 중..."
        default: store.progress.phase.title
        }
    }

    private var scanDescription: String {
        switch store.range {
        case .recentYear: "최근 1년 동안 찍은 스크린샷과\n저장된 이미지를 분석합니다."
        case .allTime: "전체 기간의 스크린샷과\n저장된 이미지를 분석합니다."
        }
    }
}
