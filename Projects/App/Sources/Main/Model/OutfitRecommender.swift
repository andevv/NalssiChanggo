import DesignSystem

struct OutfitRecommendation {
    let icon: OutfitIcon
    let label: String
    let sub: String
    let chips: [(label: String, highlight: Bool)]
}

enum OutfitRecommender {

    static func recommend(
        feelsLike: Double,
        minTemp: Double?,
        maxTemp: Double?,
        maxRainChance: Double
    ) -> OutfitRecommendation {

        let needsUmbrella = maxRainChance >= 0.3

        let (icon, label, topChips): (OutfitIcon, String, [String]) = {
            switch feelsLike {
            case 28...:   return (.shortSleeve, "반팔",        ["반팔", "반바지"])
            case 23..<28: return (.shortSleeve, "반팔",        ["반팔"])
            case 20..<23: return (.longSleeve,  "긴팔",        ["긴팔"])
            case 15..<20: return (.lightOuter,  "가디건",      ["긴팔", "가디건"])
            case 10..<15: return (.lightOuter,  "자켓",        ["긴팔", "자켓"])
            case 5..<10:  return (.heavyOuter,  "코트",        ["코트"])
            case 0..<5:   return (.padded,      "패딩",        ["패딩"])
            default:      return (.padded,      "두꺼운 패딩", ["패딩", "목도리"])
            }
        }()

        var chips: [(label: String, highlight: Bool)] = topChips.map { ($0, false) }
        if needsUmbrella {
            chips.append(("☂ 우산", true))
        }

        var subParts: [String] = []
        if let min = minTemp, let max = maxTemp {
            subParts.append("\(Int(min.rounded()))° → \(Int(max.rounded()))°")
        }
        if needsUmbrella {
            subParts.append("☂ 우산 챙기기")
        }

        return OutfitRecommendation(
            icon: icon,
            label: label,
            sub: subParts.joined(separator: " · "),
            chips: chips
        )
    }
}
