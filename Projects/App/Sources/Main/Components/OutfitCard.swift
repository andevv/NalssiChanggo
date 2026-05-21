import SwiftUI
import DesignSystem

struct OutfitCard: View {
    let data: MockWeather

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NCEyebrow(title: "OUTFIT · 옷차림", right: "자세히 ›")

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: NCSpacing.cardInner) {
                    OutfitIconBox()
                    OutfitTextBlock(data: data)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.ink4)
                }

                DashedDivider()
                    .padding(.top, NCSpacing.cardInner)
                    .padding(.bottom, 12)

                ChipRow(chips: data.outfitChips)
            }
            .padding(NCSpacing.cardInner)
            .ncCard()
        }
    }
}

// MARK: - Subviews

private struct OutfitIconBox: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: NCRadius.inner, style: .continuous)
                .fill(Color.paperGrain)
                .overlay(
                    RoundedRectangle(cornerRadius: NCRadius.inner, style: .continuous)
                        .strokeBorder(Color.hairline, lineWidth: 1)
                )
            OutfitIconView(.lightOuter, size: 32)
                .foregroundStyle(Color.ink2)
        }
        .frame(width: 56, height: 56)
    }
}

private struct OutfitTextBlock: View {
    let data: MockWeather

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(data.outfitLabel)
                .font(NCFont.cardTitle)
                .foregroundStyle(Color.ink)
                .tracking(-0.3)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(data.outfitSub)
                .font(NCFont.monoEyebrow)
                .foregroundStyle(Color.ink3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ChipRow: View {
    let chips: [(label: String, highlight: Bool)]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                ForEach(chips.indices, id: \.self) { i in
                    NCChip(label: chips[i].label, highlight: chips[i].highlight)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(0..<min(3, chips.count), id: \.self) { i in
                        NCChip(label: chips[i].label, highlight: chips[i].highlight)
                    }
                }
                HStack(spacing: 6) {
                    ForEach(3..<chips.count, id: \.self) { i in
                        NCChip(label: chips[i].label, highlight: chips[i].highlight)
                    }
                }
            }
        }
    }
}

#Preview {
    OutfitCard(data: MockWeather())
        .padding()
        .background(Color.appBg)
}
