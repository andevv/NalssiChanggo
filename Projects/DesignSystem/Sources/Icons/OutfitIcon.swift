import SwiftUI

public enum OutfitIcon: String, CaseIterable, Sendable {
    case shortSleeve  = "short-sleeve"
    case longSleeve   = "long-sleeve"
    case lightOuter   = "light-outer"
    case heavyOuter   = "heavy-outer"
    case padded       = "padded"
    case umbrella     = "umbrella"

    var assetName: String { "Outfit/\(rawValue)" }

    /// 기온 범위에 따른 기본 추천 아웃핏
    public static func recommended(for temperature: Double) -> OutfitIcon {
        switch temperature {
        case 28...:         return .shortSleeve
        case 20..<28:       return .longSleeve
        case 12..<20:       return .lightOuter
        case 5..<12:        return .heavyOuter
        default:            return .padded
        }
    }
}

// MARK: - View

public struct OutfitIconView: View {
    let icon: OutfitIcon
    let size: CGFloat

    public init(_ icon: OutfitIcon, size: CGFloat = 32) {
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
    HStack(spacing: 20) {
        ForEach(OutfitIcon.allCases, id: \.self) { icon in
            VStack(spacing: 4) {
                OutfitIconView(icon, size: 36)
                    .foregroundStyle(Color.ink2)
                Text(icon.rawValue)
                    .font(.system(size: 8))
                    .foregroundStyle(Color.ink3)
            }
        }
    }
    .padding(24)
    .background(Color.appBg)
}
