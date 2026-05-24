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

        let icon = OutfitIcon.recommended(for: feelsLike)
        let needsUmbrella = maxRainChance >= 0.3

        let (label, baseItems): (String, [String]) = {
            switch feelsLike {
            case 28...:  return ("반팔 + 반바지", ["반팔", "반바지", "샌들"])
            case 23..<28: return ("반팔 + 얇은 면바지", ["반팔", "얇은 면바지", "운동화"])
            case 20..<23: return ("긴팔 + 면바지", ["긴팔", "면바지", "운동화"])
            case 15..<20: return ("긴팔 + 얇은 가디건", ["긴팔", "가디건", "면바지", "운동화"])
            case 10..<15: return ("자켓 + 긴바지", ["자켓", "긴팔", "긴바지", "운동화"])
            case 5..<10:  return ("코트 + 레이어링", ["코트", "두꺼운 긴팔", "긴바지", "운동화"])
            default:      return ("패딩 + 방한 준비", ["패딩", "두꺼운 내의", "목도리", "장갑"])
            }
        }()

        var chips: [(label: String, highlight: Bool)] = baseItems.map { ($0, false) }
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
