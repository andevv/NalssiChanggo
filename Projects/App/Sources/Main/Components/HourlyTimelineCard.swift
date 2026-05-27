import SwiftUI
import DesignSystem

struct HourlyTimelineCard: View {
    let data: WeatherDisplayData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NCEyebrow(title: "시간별 예보")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(data.hourlyTimeline) { item in
                        if let label = item.dayLabel {
                            DateSeparatorView(label: label)
                        }
                        HourlyCell(item: item)
                            .padding(.horizontal, 2)
                    }
                }
                .padding(.horizontal, NCSpacing.cardInner)
                .padding(.vertical, NCSpacing.cardInner)
            }
            .ncCard()
        }
    }
}

// MARK: - 시간별 셀

private struct HourlyCell: View {
    let item: WeatherDisplayData.HourlyItem

    private let cellHeight: CGFloat = 118

    var body: some View {
        VStack(spacing: 0) {
            // 시간 레이블
            Text(item.isNow ? "지금" : item.hourLabel)
                .font(NCFont.monoSmall)
                .foregroundStyle(item.isNow ? Color.goldDeep : Color.ink3)
                .tracking(0.4)
                .padding(.bottom, 5)

            // 날씨 아이콘
            WeatherIconView(item.icon, size: item.isNow ? 28 : 24)
                .foregroundStyle(item.isNow ? Color.goldDeep : Color.ink3)

            Spacer()

            // 기온
            Text("\(item.temperature)°")
                .font(item.isNow ? NCFont.labelLarge : NCFont.monoBody)
                .foregroundStyle(item.isNow ? Color.ink : Color.ink2)
                .padding(.bottom, 4)

            // 강수 확률
            rainPctView(pct: item.precipitationPct)
                .padding(.bottom, 4)
        }
        .frame(width: item.isNow ? 58 : 48, height: cellHeight)
        .padding(.vertical, 12)
        .padding(.horizontal, 2)
        .background(item.isNow ? Color.goldSoft : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: NCRadius.inner, style: .continuous))
        .overlay {
            if item.isNow {
                RoundedRectangle(cornerRadius: NCRadius.inner, style: .continuous)
                    .strokeBorder(Color.goldEdge, lineWidth: 1.5)
            }
        }
    }

    @ViewBuilder
    private func rainPctView(pct: Int) -> some View {
        if pct >= 10 {
            HStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 6.5))
                    .foregroundStyle(pct >= 40 ? Color.rain : Color.rain.opacity(0.65))
                Text("\(pct)%")
                    .font(NCFont.monoTiny)
                    .foregroundStyle(pct >= 40 ? Color.rain : Color.rain.opacity(0.75))
            }
        } else {
            Text("—")
                .font(NCFont.monoTiny)
                .foregroundStyle(Color.inkFaint)
        }
    }

    private func rainBarColor(pct: Int) -> Color {
        if pct >= 50 { return Color.rain }
        if pct >= 10 { return Color.rain.opacity(0.4) }
        return Color.hairline.opacity(0.5)
    }
}

// MARK: - 날짜 구분선

private struct DateSeparatorView: View {
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(NCFont.monoTiny)
                .foregroundStyle(Color.ink3)
                .tracking(0.3)
                .lineLimit(1)
                .fixedSize()

            GeometryReader { geo in
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width / 2, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width / 2, y: geo.size.height))
                }
                .stroke(Color.hairline, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        .frame(width: 30)
        .padding(.horizontal, 4)
        // 셀과 같은 총 세로 패딩을 맞춰 정렬 유지
        .padding(.vertical, 12)
    }
}

#Preview {
    HourlyTimelineCard(data: .preview)
        .padding()
        .background(Color.appBg)
}
