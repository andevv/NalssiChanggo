public enum WeatherState: String, Codable, Sendable {
    case clear
    case mostlyClear
    case partlyCloudy
    case mostlyCloudy
    case cloudy
    case drizzle
    case rain
    case heavyRain
    case thunderstorm
    case snow
    case heavySnow
    case sleet
    case fog
    case haze
    case windy
    case hot
    case frigid
    case blizzard
    case unknown

    public var koreanLabel: String {
        switch self {
        case .clear:        return "맑음"
        case .mostlyClear:  return "대체로 맑음"
        case .partlyCloudy: return "구름 조금"
        case .mostlyCloudy: return "대체로 흐림"
        case .cloudy:       return "흐림"
        case .drizzle:      return "이슬비"
        case .rain:         return "비"
        case .heavyRain:    return "강한 비"
        case .thunderstorm: return "천둥번개"
        case .snow:         return "눈"
        case .heavySnow:    return "폭설"
        case .sleet:        return "진눈깨비"
        case .fog:          return "안개"
        case .haze:         return "연무"
        case .windy:        return "강풍"
        case .hot:          return "매우 더움"
        case .frigid:       return "매우 추움"
        case .blizzard:     return "눈보라"
        case .unknown:      return "알 수 없음"
        }
    }
}
