import SwiftUI
import DesignSystem
import WeatherDomain

struct MainView: View {
    let viewModel: MainViewModel

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

            if let data = viewModel.displayData {
                WeatherContentView(data: data)
            } else if let errorMessage = viewModel.errorMessage {
                WeatherErrorView(message: errorMessage) {
                    viewModel.retry()
                }
            } else {
                WeatherLoadingView()
            }
        }
        .onAppear {
            viewModel.locationManager.requestLocation()
        }
        // 위치가 갱신될 때마다 날씨를 새로 불러온다
        .onChange(of: viewModel.locationManager.locationVersion) { _, _ in
            viewModel.loadWeather()
        }
    }
}

// MARK: - 날씨 콘텐츠

private struct WeatherContentView: View {
    let data: WeatherDisplayData

    var body: some View {
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

// MARK: - 헤더

private struct HeaderSection: View {
    let data: WeatherDisplayData

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

// MARK: - 로딩

private struct WeatherLoadingView: View {
    @State private var pulse: Double = 0.4

    var body: some View {
        VStack(spacing: NCSpacing.base) {
            WeatherIconView(.cloudSun, size: 56)
                .foregroundStyle(Color.goldDeep)
                .opacity(pulse)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: pulse
                )
            Text("날씨 정보를 불러오는 중…")
                .font(NCFont.monoBody)
                .foregroundStyle(Color.ink3)
        }
        .onAppear { pulse = 1.0 }
    }
}

// MARK: - 에러

private struct WeatherErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: NCSpacing.section) {
            WeatherIconView(.cloud, size: 48)
                .foregroundStyle(Color.ink4)
            Text(message)
                .font(NCFont.monoBody)
                .foregroundStyle(Color.ink3)
                .multilineTextAlignment(.center)
            Button(action: onRetry) {
                Text("다시 시도")
                    .font(NCFont.monoEmphasis)
                    .foregroundStyle(Color.goldDeep)
                    .padding(.horizontal, NCSpacing.medium)
                    .padding(.vertical, NCSpacing.small)
                    .background(Color.goldSoft)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.goldEdge, lineWidth: 1))
            }
        }
        .padding(NCSpacing.screenH)
    }
}

// MARK: - Previews

#Preview("날씨 데이터") {
    MainView(viewModel: .makePreview(state: .data))
}

#Preview("로딩") {
    MainView(viewModel: .makePreview(state: .loading))
}

#Preview("에러") {
    MainView(viewModel: .makePreview(state: .error))
}
