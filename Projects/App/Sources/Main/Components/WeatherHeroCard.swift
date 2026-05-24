import SwiftUI
import DesignSystem

struct WeatherHeroCard: View {
    let data: WeatherDisplayData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NCEyebrow(title: "TOTAL · Apple WeatherKit")

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

                // 구분선 + 소스 정보
                VStack(alignment: .leading, spacing: 0) {
                    DashedDivider()
                        .padding(.bottom, 12)

                    HStack(alignment: .center, spacing: NCSpacing.base) {
                        Text("SOURCE")
                            .font(NCFont.monoEyebrow)
                            .foregroundStyle(Color.ink3)
                            .tracking(1)
                            .textCase(.uppercase)

                        Text("Apple WeatherKit")
                            .font(NCFont.monoEmphasis)
                            .foregroundStyle(Color.goldDeep)

                        Spacer()
                    }

                    Text("실시간 데이터 · 앙상블 집계 전")
                        .font(NCFont.labelSmall)
                        .foregroundStyle(Color.ink3)
                        .padding(.top, 6)
                }
                .padding(.top, NCSpacing.cardInner)
            }
            .padding(NCSpacing.cardInner + 4)
            .ncCardGold()
        }
    }
}

#Preview {
    WeatherHeroCard(data: .preview)
        .padding()
        .background(Color.appBg)
}
