import WeatherDomain

// MARK: - 수치 앙상블 전략 (기온, 강수확률)

public protocol NumericEnsembleStrategy {
    /// values: [(값, 가중치)] — 가중치 합이 1.0일 필요는 없으며, 내부에서 정규화
    func combine(_ values: [(Double, Double)]) -> Double
}

// MARK: - 상태 앙상블 전략 (날씨 상태)

public protocol StateEnsembleStrategy {
    /// states: [(WeatherState, 가중치)]
    func combine(_ states: [(WeatherState, Double)]) -> WeatherState
}

// MARK: - 가중 평균 (수치)

public struct WeightedAverageStrategy: NumericEnsembleStrategy {
    public init() {}

    public func combine(_ values: [(Double, Double)]) -> Double {
        let totalWeight = values.map(\.1).reduce(0, +)
        guard totalWeight > 0 else { return values.first?.0 ?? 0 }
        return values.map { $0.0 * $0.1 }.reduce(0, +) / totalWeight
    }
}

// MARK: - 가중 다수결 (상태)
// 각 후보 상태의 가중치 합이 가장 높은 쪽을 선택. 동점이면 가중치가 높은 소스가 이김.

public struct MajorityVoteStrategy: StateEnsembleStrategy {
    public init() {}

    public func combine(_ states: [(WeatherState, Double)]) -> WeatherState {
        guard !states.isEmpty else { return .unknown }

        // .unknown = "데이터 없음" → 투표 제외
        let valid = states.filter { $0.0 != .unknown }
        guard !valid.isEmpty else { return .unknown }
        if valid.count == 1 { return valid[0].0 }

        var votes: [WeatherState: Double] = [:]
        for (state, weight) in valid {
            votes[state, default: 0] += weight
        }

        // 최고 득표 상태 반환 (동점이면 가중치 높은 소스 선택)
        let maxVote = votes.values.max() ?? 0
        let winners = valid.filter { (votes[$0.0] ?? 0) == maxVote }
        return winners.max(by: { $0.1 < $1.1 })?.0 ?? .unknown
    }
}
