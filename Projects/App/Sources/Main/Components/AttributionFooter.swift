import SwiftUI
import DesignSystem

/// 날씨 데이터 출처 표기 푸터
/// - Apple WeatherKit: 라이선스 요건에 따라 공식 마크 + 법적 고지 링크 표시
/// - 기상청: 공공데이터포털 이용약관에 따른 출처 표기
/// - OpenWeatherMap: 서비스 약관에 따른 출처 표기
struct AttributionFooter: View {
    @Environment(\.ncFonts) private var fonts
    let markURL: URL?
    let legalURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            DashedDivider()

            VStack(spacing: 10) {
                Text("WEATHER DATA SOURCE")
                    .font(fonts.monoEyebrow)
                    .foregroundStyle(Color.inkFaint)
                    .tracking(1.4)
                    .textCase(.uppercase)

                HStack(spacing: 0) {
                    // Apple Weather — 공식 마크 (AsyncImage) 또는 텍스트 폴백
                    appleWeatherMark

                    dividerDot

                    // 기상청
                    Link(destination: URL(string: "https://www.weather.go.kr")!) {
                        Text("기상청")
                            .font(fonts.labelSmall)
                            .foregroundStyle(Color.ink4)
                    }

                    dividerDot

                    // OpenWeatherMap
                    Link(destination: URL(string: "https://openweathermap.org")!) {
                        Text("OpenWeatherMap")
                            .font(fonts.labelSmall)
                            .foregroundStyle(Color.ink4)
                    }
                }
            }
            .padding(.top, NCSpacing.medium)
            .padding(.bottom, NCSpacing.large)
        }
    }

    // MARK: - Apple Weather Mark

    @ViewBuilder
    private var appleWeatherMark: some View {
        let destination = legalURL ?? URL(string: "https://weatherkit.apple.com/legal-attribution.html")!

        Link(destination: destination) {
            if let markURL {
                AsyncImage(url: markURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 13)
                            .opacity(0.65)
                    default:
                        appleWeatherTextMark
                    }
                }
            } else {
                appleWeatherTextMark
            }
        }
    }

    private var appleWeatherTextMark: some View {
        HStack(spacing: 3) {
            Image(systemName: "apple.logo")
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(Color.ink4)
            Text("Weather")
                .font(fonts.labelSmall)
                .foregroundStyle(Color.ink4)
        }
    }

    // MARK: - Separator

    private var dividerDot: some View {
        Text(" · ")
            .font(fonts.labelSmall)
            .foregroundStyle(Color.inkFaint)
    }
}

#Preview {
    VStack {
        Spacer()
        AttributionFooter(markURL: nil, legalURL: nil)
            .padding(.horizontal, 20)
    }
    .background(Color.appBg)
}
