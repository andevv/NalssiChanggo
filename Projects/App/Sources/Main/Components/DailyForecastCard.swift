import SwiftUI
import DesignSystem

struct DailyForecastCard: View {
    let data: WeatherDisplayData

    private var weekLow: Int  { min(data.dailyForecast.map(\.lowTemp).min()  ?? 0,  data.temperature) }
    private var weekHigh: Int { max(data.dailyForecast.map(\.highTemp).max() ?? 40, data.temperature) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NCEyebrow(title: "7일 예보")

            VStack(spacing: 0) {
                ForEach(Array(data.dailyForecast.enumerated()), id: \.element.id) { idx, item in
                    DailyRow(
                        item: item,
                        weekLow: weekLow,
                        weekHigh: weekHigh,
                        currentTemp: item.isToday ? data.temperature : nil
                    )

                    // 오늘 행 바로 다음(idx==0→1)과 마지막 행 뒤에는 구분선 생략
                    if idx > 0 && idx < data.dailyForecast.count - 1 {
                        DashedDivider()
                            .padding(.horizontal, NCSpacing.cardInner)
                    }
                }
            }
            .padding(.vertical, NCSpacing.base)
            .ncCard()
        }
    }
}

// MARK: - 일별 행

private struct DailyRow: View {
    @Environment(\.ncFonts) private var fonts
    let item: WeatherDisplayData.DailyForecastItem
    let weekLow: Int
    let weekHigh: Int
    let currentTemp: Int?

    private var dayLabelColor: Color {
        if item.isToday  { return .goldDeep }
        if item.isSunday { return Color(hex: 0xC0392B) }
        return .ink2
    }

    var body: some View {
        HStack(spacing: 0) {
            // 요일 + 날짜 (2줄)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.dayLabel)
                    .font(item.isToday ? fonts.labelLarge : fonts.labelLarge)
                    .foregroundStyle(dayLabelColor)
                Text(item.dateLabel)
                    .font(fonts.monoTiny)
                    .foregroundStyle(item.isToday ? Color.goldDeep.opacity(0.65) : Color.ink4)
            }
            .frame(width: 44, alignment: .leading)

            // 날씨 아이콘
            WeatherIconView(item.icon, size: 20)
                .foregroundStyle(item.isToday ? Color.goldDeep : Color.ink3)
                .frame(width: 28)

            // 강수 확률
            precipView(pct: item.precipitationPct)
                .frame(width: 44, alignment: .leading)

            // 최저 기온
            Text("\(item.lowTemp)°")
                .font(fonts.monoBody)
                .foregroundStyle(item.isToday ? Color.goldDeep.opacity(0.65) : Color.ink4)
                .frame(width: 28, alignment: .trailing)
                .contentTransition(.numericText())
                .animation(.ncNumeric, value: item.lowTemp)

            // 기온 범위 바
            TempRangeBar(
                low: item.lowTemp,
                high: item.highTemp,
                weekLow: weekLow,
                weekHigh: weekHigh,
                currentTemp: currentTemp
            )
            .frame(height: 8)
            .padding(.horizontal, NCSpacing.small)

            // 최고 기온
            Text("\(item.highTemp)°")
                .font(item.isToday ? fonts.labelLarge : fonts.monoBody)
                .foregroundStyle(Color.ink)
                .frame(width: 28, alignment: .trailing)
                .contentTransition(.numericText())
                .animation(.ncNumeric, value: item.highTemp)
        }
        .padding(.horizontal, NCSpacing.cardInner)
        .padding(.vertical, 10)
        .background(todayBackground)
    }

    @ViewBuilder
    private var todayBackground: some View {
        if item.isToday {
            RoundedRectangle(cornerRadius: NCRadius.inner, style: .continuous)
                .fill(Color.goldSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: NCRadius.inner, style: .continuous)
                        .strokeBorder(Color.goldEdge, lineWidth: 1)
                )
                .padding(.horizontal, NCSpacing.base)
        }
    }

    @ViewBuilder
    private func precipView(pct: Int) -> some View {
        if pct >= 10 {
            HStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(pct >= 40 ? Color.rain : Color.rain.opacity(0.55))
                Text("\(pct)%")
                    .font(fonts.monoTiny)
                    .foregroundStyle(pct >= 40 ? Color.rain : Color.rain.opacity(0.65))
                    .contentTransition(.numericText())
                    .animation(.ncNumeric, value: pct)
            }
        } else {
            Color.clear
        }
    }
}

// MARK: - 기온 범위 바 (그라디언트 + 오늘 thumb)

private struct TempRangeBar: View {
    @Environment(\.ncFonts) private var fonts
    let low: Int
    let high: Int
    let weekLow: Int
    let weekHigh: Int
    let currentTemp: Int?   // 오늘만 non-nil

    private var weekRange: Double {
        let r = Double(weekHigh - weekLow)
        return r > 0 ? r : 1
    }

    private var effectiveLow:  Int { currentTemp.map { min(low,  $0) } ?? low  }
    private var effectiveHigh: Int { currentTemp.map { max(high, $0) } ?? high }

    private var leadingFraction: Double { Double(effectiveLow  - weekLow) / weekRange }
    private var widthFraction:   Double { max(Double(effectiveHigh - effectiveLow) / weekRange, 0.06) }

    private func currentFraction(_ total: CGFloat) -> CGFloat {
        guard let cur = currentTemp else { return 0 }
        let f = CGFloat(Double(cur - weekLow) / weekRange)
        return min(max(f, leadingFraction), leadingFraction + widthFraction) * total
    }

    // 주간 온도 스케일 기준 그라디언트 색상 샘플링 (차가움 → 따뜻함)
    private static let coldColor: Color = Color(hex: 0x7AABCF)
    private static let warmColor: Color = Color(hex: 0xE59520)

    private func gradientColor(at fraction: Double) -> Color {
        let f = min(max(fraction, 0), 1)
        // sRGB linear interpolation (rough)
        let coldR = 0x7A / 255.0; let coldG = 0xAB / 255.0; let coldB = 0xCF / 255.0
        let warmR = 0xE5 / 255.0; let warmG = 0x95 / 255.0; let warmB = 0x20 / 255.0
        return Color(
            red:   coldR + (warmR - coldR) * f,
            green: coldG + (warmG - coldG) * f,
            blue:  coldB + (warmB - coldB) * f
        )
    }

    var body: some View {
        GeometryReader { geo in
            let total    = geo.size.width
            let barLeft  = total * leadingFraction
            let barWidth = total * widthFraction
            let thumbX   = currentFraction(total)

            ZStack(alignment: .leading) {
                // 배경 트랙
                Capsule()
                    .fill(Color.paperGrain)

                // 그라디언트 채운 범위
                LinearGradient(
                    colors: [gradientColor(at: leadingFraction),
                             gradientColor(at: leadingFraction + widthFraction)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(Capsule())
                .frame(width: barWidth)
                .offset(x: barLeft)
            }
            // 오늘 현재 기온 세로 막대 — overlay로 레이아웃 높이에 영향 없이 오버플로
            .overlay(alignment: .leading) {
                if currentTemp != nil {
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(Color.goldDeep)
                        .frame(width: 3, height: 14)
                        .offset(x: thumbX - 1.5)
                }
            }

            // 오늘 현재 기온 레이블 — thumb 위에 표시 (관측 앙상블값으로 덮어쓰기)
            if let cur = currentTemp {
                Text("\(cur)°")
                    .font(fonts.monoTiny)
                    .foregroundStyle(Color.goldDeep)
                    .fixedSize()
                    .contentTransition(.numericText())
                    .animation(.ncNumeric, value: cur)
                    .position(
                        x: min(max(thumbX, 10), total - 10),
                        y: geo.size.height / 2 - 12
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DailyForecastCard(data: .preview)
        .padding()
        .background(Color.appBg)
}
