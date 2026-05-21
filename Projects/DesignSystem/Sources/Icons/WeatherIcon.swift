import SwiftUI

public enum WeatherIcon: String, CaseIterable, Sendable {
    case sun              = "sun"
    case cloud            = "cloud"
    case cloudSun         = "cloud-sun"
    case cloudRain        = "cloud-rain"
    case cloudHeavyRain   = "cloud-heavy-rain"
    case cloudSnow        = "cloud-snow"
    case cloudStorm       = "cloud-storm"
    case fog              = "fog"
    case wind             = "wind"
    case moon             = "moon"
    case moonCloud        = "moon-cloud"
    case starsNight       = "stars-night"

    var assetName: String { "Weather/\(rawValue)" }
}

// MARK: - View

public struct WeatherIconView: View {
    let icon: WeatherIcon
    let size: CGFloat

    public init(_ icon: WeatherIcon, size: CGFloat = 32) {
        self.icon = icon
        self.size = size
    }

    public var body: some View {
        Image(icon.assetName, bundle: .module)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview {
    LazyVGrid(columns: Array(repeating: .init(.fixed(56)), count: 4), spacing: 16) {
        ForEach(WeatherIcon.allCases, id: \.self) { icon in
            VStack(spacing: 4) {
                WeatherIconView(icon, size: 36)
                    .foregroundStyle(Color.gold)
                Text(icon.rawValue)
                    .font(.system(size: 8))
                    .foregroundStyle(Color.ink3)
            }
        }
    }
    .padding(24)
    .background(Color.appBg)
}
