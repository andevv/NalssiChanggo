import SwiftUI
import DesignSystem

struct WeatherHeroCard: View {
    let data: MockWeather

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NCEyebrow(title: "TOTAL · 앙상블 합계")

            VStack(alignment: .leading, spacing: 0) {
                // 아이콘 + 기온
                HStack(alignment: .bottom, spacing: NCSpacing.cardInner) {
                    WeatherIconView(.cloudSun, size: 84)
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

                // 구분선 + AGREE 바
                VStack(alignment: .leading, spacing: 0) {
                    DashedDivider()
                        .padding(.bottom, 12)

                    HStack(spacing: NCSpacing.base) {
                        Text("AGREE")
                            .font(NCFont.monoEyebrow)
                            .foregroundStyle(Color.ink3)
                            .tracking(1)
                            .textCase(.uppercase)

                        AgreementBar(
                            value: Double(data.agreementPct) / 100.0,
                            color: Color.gold
                        )

                        Text("\(data.agreementPct)%")
                            .font(NCFont.monoEmphasis)
                            .foregroundStyle(Color.goldDeep)
                    }

                    HStack(alignment: .lastTextBaseline) {
                        Text("Google · Apple · 기상청 — 세 곳 일치")
                            .font(NCFont.labelSmall)
                            .foregroundStyle(Color.ink3)
                        Spacer()
                        Text("소스 비교 ›")
                            .font(NCFont.monoBody)
                            .foregroundStyle(Color.goldDeep)
                    }
                    .padding(.top, 6)
                }
                .padding(.top, NCSpacing.cardInner)
            }
            .padding(NCSpacing.cardInner + 4)  // 20pt — 디자인 기준
            .ncCardGold()
        }
    }
}

#Preview {
    WeatherHeroCard(data: MockWeather())
        .padding()
        .background(Color.appBg)
}
