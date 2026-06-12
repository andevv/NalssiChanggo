import SwiftUI
import DesignSystem

struct WeatherHeroCard: View {
    let data: WeatherDisplayData
    let isRefreshEnabled: Bool
    let onRefresh: () -> Void

    @State private var showBreakdown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NCEyebrow(title: "TOTAL · ENSEMBLE")

            VStack(alignment: .leading, spacing: 0) {
                // 아이콘 + 기온
                HStack(alignment: .bottom, spacing: NCSpacing.cardInner) {
                    WeatherIconView(data.weatherIcon, size: 84)
                        .foregroundStyle(Color.goldDeep)

                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(data.temperature)")
                            .font(NCFont.heroTemp)
                            .foregroundStyle(Color.ink)
                            .tracking(-3)
                        Text("°")
                            .font(NCFont.heroDeg)
                            .foregroundStyle(Color.ink3)
                            .offset(y: -4)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 6)
                }

                // 날씨 상태
                Text("\(data.condition) · 체감 \(data.feelsLike)°")
                    .font(NCFont.conditionBody)
                    .foregroundStyle(Color.ink2)
                    .padding(.top, 4)

                // 구분선 + 소스 정보 (탭 힌트 포함)
                VStack(alignment: .leading, spacing: 0) {
                    DashedDivider()
                        .padding(.bottom, 12)

                    HStack(alignment: .center, spacing: NCSpacing.base) {
                        Text("SOURCE")
                            .font(NCFont.monoEyebrow)
                            .foregroundStyle(Color.ink3)
                            .tracking(1)
                            .textCase(.uppercase)

                        Text("WeatherKit × 기상청 × OWM")
                            .font(NCFont.monoEmphasis)
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
}

#Preview {
    WeatherHeroCard(data: .preview, isRefreshEnabled: true, onRefresh: {})
        .padding()
        .background(Color.appBg)
}
