import SwiftUI
import DesignSystem

struct AirRainRow: View {
    let data: MockWeather

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NCEyebrow(title: "대기 · 강수")

            HStack(alignment: .top, spacing: NCSpacing.small) {
                AirCard(data: data)
                RainCard(data: data)
            }
        }
    }
}

// MARK: - 미세먼지 Card

private struct AirCard: View {
    let data: MockWeather

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    CardEyebrow("미세먼지")
                    Text(data.pmGrade)
                        .font(NCFont.cardValue)
                        .foregroundStyle(Color.airGood)
                        .lineLimit(1)
                }
                Spacer()
                AirDial(grade: data.pmGradeIndex, size: 32)
            }

            DashedDivider()
                .padding(.top, 12)
                .padding(.bottom, NCSpacing.small)

            Text("\(data.pmValue) ㎍/㎥")
                .font(NCFont.monoEmphasis)
                .foregroundStyle(Color.ink2)

            Text("전일 대비 \(data.pmDelta > 0 ? "+" : "")\(data.pmDelta)")
                .font(NCFont.labelSmall)
                .foregroundStyle(Color.ink3)
                .padding(.top, 2)
        }
        .padding(NCSpacing.cardInner)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ncCard()
    }
}

// MARK: - 강수 Card

private struct RainCard: View {
    let data: MockWeather

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    CardEyebrow("강수")
                    Text(data.rainCondition)
                        .font(NCFont.cardValue)
                        .foregroundStyle(Color.rain)
                        .lineLimit(1)
                }
                Spacer()
                OutfitIconView(.umbrella, size: 28)
                    .foregroundStyle(Color.rain)
            }

            DashedDivider()
                .padding(.top, 12)
                .padding(.bottom, NCSpacing.base)

            HourlyRainBars(values: data.hourlyRain.map(\.pct))
                .frame(height: 32)

            HStack {
                Text(data.hourlyRain.first.map { "\($0.hour)시" } ?? "")
                Spacer()
                Text(data.rainPeakLabel)
                    .foregroundStyle(Color.rain)
                    .fontWeight(.semibold)
                Spacer()
                Text(data.hourlyRain.last.map { "\($0.hour)시" } ?? "")
            }
            .font(NCFont.monoEyebrow)
            .foregroundStyle(Color.ink3)
            .padding(.top, 4)
        }
        .padding(NCSpacing.cardInner)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ncCard()
    }
}

// MARK: - Hourly Rain Bars

private struct HourlyRainBars: View {
    let values: [Int]

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(values.indices, id: \.self) { i in
                let p = values[i]
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(p >= 50 ? Color.rain : Color.rainSoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .strokeBorder(p >= 50 ? Color.rain : Color.hairline, lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity)
                    .scaleEffect(y: CGFloat(max(p, 6)) / 100.0, anchor: .bottom)
            }
        }
    }
}

// MARK: - 카드 내부 아이브로우

private struct CardEyebrow: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(NCFont.monoEyebrow)
            .foregroundStyle(Color.ink3)
            .tracking(1)
            .textCase(.uppercase)
    }
}

#Preview {
    AirRainRow(data: MockWeather())
        .padding()
        .background(Color.appBg)
}
