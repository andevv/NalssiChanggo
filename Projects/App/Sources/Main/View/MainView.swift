import SwiftUI
import UIKit
import DesignSystem
import WeatherDomain

struct MainView: View {
    let viewModel: MainViewModel

    private enum ViewPhase: Equatable {
        case loading, data, error, denied
    }

    private var viewPhase: ViewPhase {
        if viewModel.displayData != nil { return .data }
        if viewModel.locationManager.authorizationStatus == .denied
            || viewModel.locationManager.authorizationStatus == .restricted { return .denied }
        if viewModel.errorMessage != nil { return .error }
        return .loading
    }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            RadialGradient(
                colors: [Color.gold.opacity(0.06), Color.clear],
                center: UnitPoint(x: 0.2, y: 0),
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()

            if let data = viewModel.displayData {
                WeatherContentView(
                    data: data,
                    loadVersion: viewModel.loadVersion,
                    attributionMarkURL: viewModel.attributionMarkURL,
                    attributionLegalURL: viewModel.attributionLegalURL,
                    isRefreshEnabled: !viewModel.isCoolingDown,
                    onRefresh: { viewModel.refreshWeather() }
                )
                .transition(.opacity)
            } else if viewModel.locationManager.authorizationStatus == .denied
                        || viewModel.locationManager.authorizationStatus == .restricted {
                // authorizationStatus는 @Observable이므로 init 시점부터 올바른 값을 가짐
                // → 재실행 후 거부 상태여도 onChange 없이 즉시 이 뷰가 렌더링됨
                LocationPermissionDeniedView()
                    .transition(.opacity)
            } else if let errorMessage = viewModel.errorMessage {
                WeatherErrorView(message: errorMessage) {
                    viewModel.retry()
                }
                .transition(.opacity)
            } else {
                WeatherLoadingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewPhase)
        // 위치가 갱신될 때마다 날씨를 새로 불러온다
        // 위치 요청 자체는 LocationManager 내부에서 관리 (requestLocation 중복 호출 방지)
        .onChange(of: viewModel.locationManager.locationVersion) { _, _ in
            viewModel.loadWeather()
        }
        // 위치 fetch 오류 시 에러뷰로 전환 (권한 거부는 authorizationStatus로 직접 처리)
        .onChange(of: viewModel.locationManager.locationFailed) { _, failed in
            if failed { viewModel.handleLocationFailure() }
        }
        .trackScreen("메인 화면")
    }
}

// MARK: - 날씨 콘텐츠

private struct WeatherContentView: View {
    let data: WeatherDisplayData
    let loadVersion: Int
    let attributionMarkURL: URL?
    let attributionLegalURL: URL?
    let isRefreshEnabled: Bool
    let onRefresh: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var scrollOffset: CGFloat = 0
    @State private var initialScrollY: CGFloat? = nil

    // 스크롤 20pt 지점부터 60pt 구간에 걸쳐 0→1로 진행
    private var headerFade: CGFloat {
        max(0, min(1, (scrollOffset - 20) / 60))
    }

    private var hPad: CGFloat {
        sizeClass == .regular ? NCSpacing.screenH_pad : NCSpacing.screenH
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // 스크롤 오프셋 앵커: onGeometryChange는 스크롤 중에도 global 위치를 추적
                Color.clear
                    .frame(height: 0)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .global).minY
                    } action: { minY in
                        if initialScrollY == nil { initialScrollY = minY }
                        scrollOffset = max(0, (initialScrollY ?? minY) - minY)
                    }

                if sizeClass == .regular {
                    iPadLayout
                        .environment(\.ncFonts, .pad)
                } else {
                    iPhoneLayout
                        .environment(\.ncFonts, .phone)
                }

                AttributionFooter(markURL: attributionMarkURL, legalURL: attributionLegalURL)
                    .padding(.horizontal, hPad)
            }
        }
    }

    // MARK: - iPhone: 단일 컬럼

    @ViewBuilder
    private var iPhoneLayout: some View {
        VStack(alignment: .leading, spacing: NCSpacing.section) {
            HeaderSection(data: data)
                .staggeredAppear(index: 0, triggerID: loadVersion)
                .opacity(1 - headerFade)
                .scaleEffect(1 - headerFade * 0.06, anchor: .center)
                .offset(y: -headerFade * 6)
            WeatherHeroCard(data: data, isRefreshEnabled: isRefreshEnabled, onRefresh: onRefresh)
                .staggeredAppear(index: 1, triggerID: loadVersion)
            AirRainRow(data: data)
                .staggeredAppear(index: 2, triggerID: loadVersion)
            OutfitCard(data: data)
                .staggeredAppear(index: 3, triggerID: loadVersion)
            HourlyTimelineCard(data: data)
                .staggeredAppear(index: 4, triggerID: loadVersion)
            DailyForecastCard(data: data)
                .staggeredAppear(index: 5, triggerID: loadVersion)
        }
        .padding(.horizontal, NCSpacing.screenH)
        .padding(.top, NCSpacing.base)
        .padding(.bottom, NCSpacing.medium)
    }

    // MARK: - iPad: 두 컬럼

    @ViewBuilder
    private var iPadLayout: some View {
        VStack(alignment: .leading, spacing: NCSpacing.section) {
            HeaderSection(data: data)
                .staggeredAppear(index: 0, triggerID: loadVersion)
                .opacity(1 - headerFade)
                .scaleEffect(1 - headerFade * 0.06, anchor: .center)
                .offset(y: -headerFade * 6)

            HStack(alignment: .top, spacing: NCSpacing.columnGap) {
                // 왼쪽: 현재 날씨 + 시간별 예보
                VStack(spacing: NCSpacing.section) {
                    WeatherHeroCard(data: data, isRefreshEnabled: isRefreshEnabled, onRefresh: onRefresh)
                        .staggeredAppear(index: 1, triggerID: loadVersion)
                    HourlyTimelineCard(data: data)
                        .staggeredAppear(index: 2, triggerID: loadVersion)
                }
                .frame(maxWidth: .infinity)

                // 오른쪽: 대기·강수 + 옷차림 + 일별 예보
                VStack(spacing: NCSpacing.section) {
                    AirRainRow(data: data)
                        .staggeredAppear(index: 1, triggerID: loadVersion)
                    OutfitCard(data: data)
                        .staggeredAppear(index: 2, triggerID: loadVersion)
                    DailyForecastCard(data: data)
                        .staggeredAppear(index: 3, triggerID: loadVersion)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, NCSpacing.screenH_pad)
        .padding(.top, NCSpacing.base)
        .padding(.bottom, NCSpacing.medium)
    }
}

// MARK: - 헤더

private struct HeaderSection: View {
    @Environment(\.ncFonts) private var fonts
    let data: WeatherDisplayData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("날씨창고")
                    .font(fonts.monoEyebrow)
                    .foregroundStyle(Color.ink3)
                    .tracking(1.4)
                    .textCase(.uppercase)
                Spacer()
                Text(data.receiptNo)
                    .font(fonts.monoEyebrow)
                    .foregroundStyle(Color.ink3)
                    .tracking(1.4)
                    .textCase(.uppercase)
            }

            HStack(alignment: .lastTextBaseline, spacing: NCSpacing.small) {
                Text(data.location)
                    .font(fonts.locationTitle)
                    .foregroundStyle(Color.ink)
                    .tracking(-0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(data.dateLabel)
                    .font(fonts.monoBody)
                    .foregroundStyle(Color.ink3)
                    .tracking(0.5)
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - 로딩

private struct WeatherLoadingView: View {
    @State private var pulse: Double = 0.4

    var body: some View {
        VStack(spacing: NCSpacing.base) {
            WeatherIconView(.cloudSun, size: 56)
                .foregroundStyle(Color.goldDeep)
                .opacity(pulse)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: pulse
                )
            Text("날씨 정보를 불러오는 중…")
                .font(NCFont.monoBody)
                .foregroundStyle(Color.ink3)
        }
        .onAppear { pulse = 1.0 }
    }
}

// MARK: - 에러

private struct WeatherErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: NCSpacing.section) {
            WeatherIconView(.cloud, size: 48)
                .foregroundStyle(Color.ink4)
            Text(message)
                .font(NCFont.monoBody)
                .foregroundStyle(Color.ink3)
                .multilineTextAlignment(.center)
            Button(action: onRetry) {
                Text("다시 시도")
                    .font(NCFont.monoEmphasis)
                    .foregroundStyle(Color.goldDeep)
                    .padding(.horizontal, NCSpacing.medium)
                    .padding(.vertical, NCSpacing.small)
                    .background(Color.goldSoft)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.goldEdge, lineWidth: 1))
            }
            .buttonStyle(.ncBounce)
        }
        .padding(NCSpacing.screenH)
    }
}

// MARK: - 위치 권한 거부

private struct LocationPermissionDeniedView: View {
    var body: some View {
        VStack(spacing: NCSpacing.section) {
            WeatherIconView(.cloud, size: 48)
                .foregroundStyle(Color.ink4)

            VStack(spacing: NCSpacing.small) {
                Text("위치 권한이 필요합니다")
                    .font(NCFont.monoEmphasis)
                    .foregroundStyle(Color.ink)

                Text("날씨 정보를 제공하려면\n위치 접근 권한이 필요합니다.")
                    .font(NCFont.monoBody)
                    .foregroundStyle(Color.ink3)
                    .multilineTextAlignment(.center)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("설정에서 권한 허용하기")
                    .font(NCFont.monoEmphasis)
                    .foregroundStyle(Color.goldDeep)
                    .padding(.horizontal, NCSpacing.medium)
                    .padding(.vertical, NCSpacing.small)
                    .background(Color.goldSoft)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.goldEdge, lineWidth: 1))
            }
            .buttonStyle(.ncBounce)
        }
        .padding(NCSpacing.screenH)
    }
}

// MARK: - Previews

#Preview("날씨 데이터") {
    MainView(viewModel: .makePreview(state: .data))
}

#Preview("로딩") {
    MainView(viewModel: .makePreview(state: .loading))
}

#Preview("에러") {
    MainView(viewModel: .makePreview(state: .error))
}
