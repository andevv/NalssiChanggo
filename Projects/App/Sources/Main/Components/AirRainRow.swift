import SwiftUI
import DesignSystem

struct AirRainRow: View {
    let data: WeatherDisplayData

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

// MARK: - 대기질 Card

private struct AirCard: View {
    let data: WeatherDisplayData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    CardEyebrow("대기질")
                    if data.hasAirData {
                        Text(data.airGrade)
                            .font(NCFont.cardValue)
                            .foregroundStyle(data.airGradeColor)
                            .lineLimit(1)
                    } else {
                        Text("--")
                            .font(NCFont.cardValue)
                            .foregroundStyle(Color.inkFaint)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if data.hasAirData {
                    AirDial(grade: data.airGradeIndex, size: 32)
                } else {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.inkFaint)
                }
            }

            DashedDivider()
                .padding(.top, 12)
                .padding(.bottom, NCSpacing.small)

            if data.hasAirData {
                PMRow(label: "PM2.5", value: data.airPM25)
                PMRow(label: "PM10", value: data.airPM10)
                    .padding(.top, 4)
            } else {
                PMRow(label: "PM2.5", value: nil)
                PMRow(label: "PM10", value: nil)
                    .padding(.top, 4)
            }
        }
        .padding(NCSpacing.cardInner)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ncCard()
    }
}

// MARK: - 강수 Card

private struct RainCard: View {
    let data: WeatherDisplayData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    CardEyebrow("강수")
                    Text(data.rainCondition)
                        .font(NCFont.cardValue)
                        .foregroundStyle(data.rainCondition == "강수 없음" ? Color.ink3 : Color.rain)
                        .lineLimit(1)
                }
                Spacer()
                OutfitIconView(.umbrella, size: 28)
                    .foregroundStyle(data.rainCondition == "강수 없음" ? Color.inkFaint : Color.rain)
            }

            DashedDivider()
                .padding(.top, 12)
                .padding(.bottom, NCSpacing.base)

            if data.hourlyRain.isEmpty {
                Spacer()
                Text("데이터 없음")
                    .font(NCFont.monoEyebrow)
                    .foregroundStyle(Color.inkFaint)
            } else {
                HourlyRainBars(values: data.hourlyRain.map(\.pct))
                    .frame(height: 32)

                HStack {
                    Text(data.hourlyRain.first.map { "\($0.hour)시" } ?? "")
                    Spacer()
                    Text(data.rainPeakLabel)
                        .foregroundStyle(data.rainCondition == "강수 없음" ? Color.ink3 : Color.rain)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(data.hourlyRain.last.map { "\($0.hour)시" } ?? "")
                }
                .font(NCFont.monoEyebrow)
                .foregroundStyle(Color.ink3)
                .padding(.top, 4)
            }
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

// MARK: - PM Row

private struct PMRow: View {
    let label: String
    let value: Int?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(label)
                .font(NCFont.monoEyebrow)
                .foregroundStyle(Color.ink3)
                .frame(width: 44, alignment: .leading)
            if let value {
                Text("\(value)")
                    .font(NCFont.monoEmphasis)
                    .foregroundStyle(Color.ink2)
                    .contentTransition(.numericText())
                    .animation(.ncNumeric, value: value)
                Text(" μg/m³")
                    .font(NCFont.labelSmall)
                    .foregroundStyle(Color.ink3)
            } else {
                Text("--")
                    .font(NCFont.monoEmphasis)
                    .foregroundStyle(Color.inkFaint)
            }
        }
    }
}

// MARK: - Card Eyebrow

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
    AirRainRow(data: .preview)
        .padding()
        .background(Color.appBg)
}
