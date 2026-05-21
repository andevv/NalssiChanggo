import SwiftUI
import DesignSystem

struct MainView: View {
    private let data = MockWeather()

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            RadialGradient(
                colors: [Color.gold.opacity(0.06), Color.clear],
                center: UnitPoint(x: 0.2, y: 0),
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: NCSpacing.section) {
                    HeaderSection(data: data)
                    WeatherHeroCard(data: data)
                    AirRainRow(data: data)
                    OutfitCard(data: data)
                }
                .padding(.horizontal, NCSpacing.screenH)
                .padding(.top, NCSpacing.base)
                .padding(.bottom, NCSpacing.medium)
            }
        }
    }
}

// MARK: - Header

private struct HeaderSection: View {
    let data: MockWeather

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("날씨창고")
                    .font(NCFont.monoEyebrow)
                    .foregroundStyle(Color.ink3)
                    .tracking(1.4)
                    .textCase(.uppercase)
                Spacer()
                Text(data.receiptNo)
                    .font(NCFont.monoEyebrow)
                    .foregroundStyle(Color.ink3)
                    .tracking(1.4)
                    .textCase(.uppercase)
            }

            HStack(alignment: .lastTextBaseline, spacing: NCSpacing.small) {
                Text(data.location)
                    .font(NCFont.locationTitle)
                    .foregroundStyle(Color.ink)
                    .tracking(-0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(data.dateLabel)
                    .font(NCFont.monoBody)
                    .foregroundStyle(Color.ink3)
                    .tracking(0.5)
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    MainView()
}
