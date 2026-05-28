import SwiftUI
import DesignSystem

struct SourceBreakdownView: View {
    let data: WeatherDisplayData
    let onRefresh: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            if let bd = data.sourceBreakdown {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        SheetHeader(
                            receiptNo: data.receiptNo,
                            location: data.location,
                            onDismiss: { dismiss() }
                        )
                        .padding(.horizontal, NCSpacing.screenH)
                        .padding(.top, NCSpacing.medium)

                        VStack(alignment: .leading, spacing: NCSpacing.section) {
                            SummaryCard(bd: bd)

                            SourceListSection(bd: bd, data: data)

                            CommentBlock(text: bd.commentText)

                            UpdatedFooter(label: bd.updatedLabel, onRefresh: onRefresh)
                        }
                        .padding(.horizontal, NCSpacing.screenH)
                        .padding(.top, NCSpacing.medium)
                        .padding(.bottom, NCSpacing.large)
                    }
                }
            }
        }
    }
}

// MARK: - Sheet Header

private struct SheetHeader: View {
    let receiptNo: String
    let location: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SOURCE BREAKDOWN · 소스 비교")
                .font(NCFont.monoEyebrow)
                .foregroundStyle(Color.ink3)
                .tracking(1.2)
                .textCase(.uppercase)
                .padding(.top, 2)

            Text(location)
                .font(NCFont.locationTitle)
                .foregroundStyle(Color.ink)
                .tracking(-0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 2)
        }
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let bd: WeatherDisplayData.SourceBreakdownDisplayData

    private var agreementColor: Color {
        switch bd.agreementPct {
        case 90...: return .airGood
        case 70...: return Color(hex: 0xC9A52E)
        default:    return .warn
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 일치도 행
            HStack(alignment: .center, spacing: NCSpacing.small) {
                Image(systemName: bd.agreementPct >= 70 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(agreementColor)
                    .font(.system(size: 18))

                VStack(alignment: .leading, spacing: 2) {
                    Text(bd.agreementLabel)
                        .font(NCFont.labelLarge)
                        .foregroundStyle(Color.ink)
                    Text("AGREE · \(bd.avgAbsDeviationLabel)")
                        .font(NCFont.monoEyebrow)
                        .foregroundStyle(Color.ink3)
                        .tracking(1)
                        .textCase(.uppercase)
                }

                Spacer()

                Text("\(bd.agreementPct)%")
                    .font(.pretendardBold(size: 36))
                    .foregroundStyle(agreementColor)
                    .tracking(-1)
            }
            .padding(.horizontal, NCSpacing.cardInner)
            .padding(.top, NCSpacing.cardInner)
            .padding(.bottom, NCSpacing.small)

            DashedDivider()
                .padding(.horizontal, NCSpacing.cardInner)
                .padding(.vertical, NCSpacing.small)

            // 앙상블 결과 행
            HStack(alignment: .center, spacing: NCSpacing.small) {
                WeatherIconView(bd.ensembleIcon, size: 28)
                    .foregroundStyle(Color.goldDeep)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(bd.ensembleTemp)")
                            .font(NCFont.subTemp)
                            .foregroundStyle(Color.ink)
                        Text("°  \(bd.ensembleCondition)")
                            .font(NCFont.conditionBody)
                            .foregroundStyle(Color.ink2)
                    }
                    Text("ENSEMBLE · 평균 가중치 적용")
                        .font(NCFont.monoEyebrow)
                        .foregroundStyle(Color.ink3)
                        .tracking(1)
                        .textCase(.uppercase)
                }
            }
            .padding(.horizontal, NCSpacing.cardInner)
            .padding(.bottom, NCSpacing.cardInner)
        }
        .ncCardGold()
    }
}

// MARK: - Source List Section

private struct SourceListSection: View {
    let bd: WeatherDisplayData.SourceBreakdownDisplayData
    let data: WeatherDisplayData

    var body: some View {
        VStack(alignment: .leading, spacing: NCSpacing.base) {
            NCEyebrow(
                title: "소스 · \(bd.sources.count) SOURCES",
                right: "가중치"
            )

            ForEach(bd.sources) { source in
                SourceCard(
                    source: source,
                    ensembleTemp: Double(bd.ensembleTemp),
                    rangeMin: bd.tempRangeMin,
                    rangeMax: bd.tempRangeMax
                )
            }
        }
    }
}

// MARK: - Source Card

private struct SourceCard: View {
    let source: WeatherDisplayData.SourceBreakdownDisplayData.SourceCard
    let ensembleTemp: Double
    let rangeMin: Double
    let rangeMax: Double

    private var initialColor: Color {
        switch source.id {
        case "apple": return Color(hex: 0x3A6FB0)
        case "kma":   return Color(hex: 0x4D8C5A)
        default:      return Color(hex: 0x6B6357)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 소스명 행
            HStack(alignment: .center, spacing: NCSpacing.small) {
                // 이니셜 뱃지
                ZStack {
                    Circle()
                        .fill(initialColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Text(source.initial)
                        .font(NCFont.labelLarge)
                        .foregroundStyle(initialColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(source.name)
                        .font(NCFont.labelLarge)
                        .foregroundStyle(Color.ink)
                }

                Spacer()

                // 가중치 배지 (KMA 강조)
                Text(source.weightBadge)
                    .font(NCFont.monoEmphasis)
                    .foregroundStyle(source.weightBadge == "× 1.0" ? Color.ink3 : Color.goldDeep)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(source.weightBadge == "× 1.0" ? Color.paperGrain : Color.goldSoft)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(
                        source.weightBadge == "× 1.0" ? Color.hairline : Color.goldEdge,
                        lineWidth: 1
                    ))
            }
            .padding(.horizontal, NCSpacing.cardInner)
            .padding(.top, NCSpacing.cardInner)

            // 기온·상태 행
            HStack(alignment: .center) {
                WeatherIconView(source.weatherIcon, size: 22)
                    .foregroundStyle(Color.goldDeep)
                    .padding(.trailing, 2)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(source.temperature)")
                        .font(.pretendardBold(size: 28))
                        .foregroundStyle(Color.ink)
                    Text("°")
                        .font(NCFont.conditionBody)
                        .foregroundStyle(Color.ink3)
                }

                Text(source.conditionLabel)
                    .font(NCFont.conditionBody)
                    .foregroundStyle(Color.ink2)
                    .padding(.leading, 4)

                Spacer()

                // 편차 배지
                Text(source.deviationLabel)
                    .font(NCFont.monoEmphasis)
                    .foregroundStyle(source.deviationPositive ? Color.warn : Color.rain)
                    .monospacedDigit()
            }
            .padding(.horizontal, NCSpacing.cardInner)
            .padding(.top, NCSpacing.base)

            // 온도 범위 바
            TempRangeBar(
                sourceTemp: Double(source.temperature),
                ensembleTemp: ensembleTemp,
                rangeMin: rangeMin,
                rangeMax: rangeMax
            )
            .padding(.horizontal, NCSpacing.cardInner)
            .padding(.top, NCSpacing.base)
            .padding(.bottom, NCSpacing.cardInner)
        }
        .ncCard()
    }
}

// MARK: - Temp Range Bar

private struct TempRangeBar: View {
    let sourceTemp: Double
    let ensembleTemp: Double
    let rangeMin: Double
    let rangeMax: Double

    private func fraction(_ value: Double) -> Double {
        let span = rangeMax - rangeMin
        guard span > 0 else { return 0.5 }
        return min(max((value - rangeMin) / span, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                let w = geo.size.width
                let ensembleX = w * fraction(ensembleTemp)
                let sourceX   = w * fraction(sourceTemp)

                ZStack(alignment: .leading) {
                    // 배경 트랙
                    Capsule()
                        .fill(Color.hairline)
                        .frame(height: 3)

                    // 앙상블 마커 (세로선)
                    Rectangle()
                        .fill(Color.ink3)
                        .frame(width: 1.5, height: 10)
                        .offset(x: ensembleX - 0.75, y: -3.5)

                    // 소스 위치 마커
                    Circle()
                        .fill(Color.ink)
                        .frame(width: 9, height: 9)
                        .offset(x: sourceX - 4.5, y: -3)
                }
            }
            .frame(height: 10)

            // 레이블
            HStack {
                Text("\(Int(rangeMin.rounded()))°")
                    .font(NCFont.monoSmall)
                    .foregroundStyle(Color.inkFaint)

                Spacer()

                Text("앙상블 \(Int(ensembleTemp.rounded()))°")
                    .font(NCFont.monoSmall)
                    .foregroundStyle(Color.ink3)

                Spacer()

                Text("\(Int(rangeMax.rounded()))°")
                    .font(NCFont.monoSmall)
                    .foregroundStyle(Color.inkFaint)
            }
        }
    }
}

// MARK: - Comment Block

private struct CommentBlock: View {
    let text: String

    var body: some View {
        Text(text)
            .font(NCFont.accent)
            .foregroundStyle(Color.ink2)
            .padding(NCSpacing.cardInner)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.paperGrain)
            .clipShape(RoundedRectangle(cornerRadius: NCRadius.inner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NCRadius.inner, style: .continuous)
                    .strokeBorder(Color.hairline, lineWidth: 1)
            )
    }
}

// MARK: - Updated Footer

private struct UpdatedFooter: View {
    let label: String
    let onRefresh: () -> Void

    var body: some View {
        HStack {
            Text("UPDATED · \(label)")
                .font(NCFont.monoEyebrow)
                .foregroundStyle(Color.ink3)
                .tracking(1)
                .textCase(.uppercase)

            Spacer()

            Button(action: onRefresh) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .medium))
                    Text("새로고침")
                        .font(NCFont.monoEyebrow)
                        .tracking(0.5)
                }
                .foregroundStyle(Color.goldDeep)
            }
        }
    }
}

// MARK: - Font helper (local)

private extension Font {
    static func pretendardBold(size: CGFloat) -> Font {
        .custom("Pretendard-Bold", size: size, relativeTo: .body)
    }
}

// MARK: - Preview

#Preview {
    SourceBreakdownView(data: .preview, onRefresh: {})
}
