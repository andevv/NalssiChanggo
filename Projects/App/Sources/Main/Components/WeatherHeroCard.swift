import SwiftUI
import DesignSystem

struct WeatherHeroCard: View {
    @Environment(\.ncFonts) private var fonts
    let data: WeatherDisplayData
    let isRefreshEnabled: Bool
    let onRefresh: () -> Void

    @State private var showBreakdown = false
    @State private var displayedTemperature: Double = 0
    @State private var displayedFeelsLike: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NCEyebrow(title: "TOTAL · ENSEMBLE")

            VStack(alignment: .leading, spacing: 0) {
                // 아이콘 + 기온
                HStack(alignment: .bottom, spacing: NCSpacing.cardInner) {
                    WeatherIconView(data.weatherIcon, size: 84)
                        .foregroundStyle(Color.goldDeep)

                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        CountingNumber(
                            value: displayedTemperature,
                            font: fonts.heroTemp,
                            color: Color.ink,
                            tracking: -3
                        )
                        Text("°")
                            .font(fonts.heroDeg)
                            .foregroundStyle(Color.ink3)
                            .offset(y: -4)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 6)
                }

                // 날씨 상태
                HStack(spacing: 0) {
                    Text("\(data.condition) · 체감 ")
                    CountingNumber(
                        value: displayedFeelsLike,
                        font: fonts.conditionBody,
                        color: Color.ink2,
                        tracking: 0
                    )
                    Text("°")
                }
                .font(fonts.conditionBody)
                .foregroundStyle(Color.ink2)
                .padding(.top, 4)

                // 구분선 + 소스 정보 (탭 힌트 포함)
                VStack(alignment: .leading, spacing: 0) {
                    DashedDivider()
                        .padding(.bottom, 12)

                    HStack(alignment: .center, spacing: NCSpacing.base) {
                        Text("SOURCE")
                            .font(fonts.monoEyebrow)
                            .foregroundStyle(Color.ink3)
                            .tracking(1)
                            .textCase(.uppercase)

                        Text("WeatherKit × 기상청 × OWM")
                            .font(fonts.monoEmphasis)
                            .foregroundStyle(Color.goldDeep)

                        Spacer()

                        if data.sourceBreakdown != nil {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.goldDeep)
                        }
                    }
                }
                .padding(.top, NCSpacing.cardInner)
            }
            .padding(NCSpacing.cardInner + 4)
            .ncCardGold()
        }
        .contentShape(Rectangle())
        .onAppear {
            // 실제값과 같은 자릿수의 시작값으로 즉시 설정 — 카운트 중 레이아웃 이동 방지
            displayedTemperature = Double(Self.countUpStart(for: data.temperature))
            displayedFeelsLike   = Double(Self.countUpStart(for: data.feelsLike))
            // 다음 렌더 사이클에서 실제값까지 카운트업
            DispatchQueue.main.async {
                withAnimation(.ncCountUp) {
                    displayedTemperature = Double(data.temperature)
                    displayedFeelsLike   = Double(data.feelsLike)
                }
            }
        }
        .onChange(of: data.temperature) { _, newValue in
            withAnimation(.ncNumeric) { displayedTemperature = Double(newValue) }
        }
        .onChange(of: data.feelsLike) { _, newValue in
            withAnimation(.ncNumeric) { displayedFeelsLike = Double(newValue) }
        }
        .bounceTap {
            if data.sourceBreakdown != nil {
                showBreakdown = true
            }
        }
        .sheet(isPresented: $showBreakdown) {
            SourceBreakdownView(data: data, isRefreshEnabled: isRefreshEnabled, onRefresh: {
                showBreakdown = false
                onRefresh()
            })
        }
    }

    /// 카운트업 시작값: 실제값과 자릿수가 같아서 카운트 중 레이아웃이 변하지 않는다.
    /// 예) 22 → 10, 5 → 0, -5 → -1, -15 → -10
    private static func countUpStart(for value: Int) -> Int {
        if value >= 10 { return 10 }
        if value >= 0  { return 0  }
        if value >= -9 { return -1 }
        return -10
    }
}

// MARK: - CountingNumber

/// Animatable을 채택해 withAnimation의 response가 카운트 속도를 직접 제어한다.
/// contentTransition과 달리 SwiftUI가 body를 프레임마다 보간된 value로 호출한다.
private struct CountingNumber: View, Animatable {
    var value: Double
    let font: Font
    let color: Color
    let tracking: CGFloat

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text("\(Int(value.rounded()))")
            .font(font)
            .foregroundStyle(color)
            .tracking(tracking)
    }
}

#Preview {
    WeatherHeroCard(data: .preview, isRefreshEnabled: true, onRefresh: {})
        .padding()
        .background(Color.appBg)
}
