public struct SourceBreakdown: Sendable {

    public struct SourceSnapshot: Sendable {
        public let temperature: Double
        public let state: WeatherState
        public let humidity: Double
        public let windSpeed: Double
        /// 앙상블 집계 시 적용된 원시 가중치 (예: 0.3, 0.4)
        public let rawWeight: Double
        /// source.temperature - ensembleTemperature
        public let deviation: Double

        public init(
            temperature: Double,
            state: WeatherState,
            humidity: Double,
            windSpeed: Double,
            rawWeight: Double,
            deviation: Double
        ) {
            self.temperature = temperature
            self.state       = state
            self.humidity    = humidity
            self.windSpeed   = windSpeed
            self.rawWeight   = rawWeight
            self.deviation   = deviation
        }
    }

    public let apple: SourceSnapshot?
    public let kma:   SourceSnapshot?
    public let owm:   SourceSnapshot?

    /// 앙상블 기온 (가중 평균 결과)
    public let ensembleTemperature: Double

    /// 소스 간 일치도 0.0–1.0 (표준편차 기반, 0°C = 1.0, 5°C = 0.0)
    public let agreement: Double

    /// 사용 가능한 소스들의 평균 절대 편차 (°C)
    public let avgAbsDeviation: Double

    public init(
        apple: SourceSnapshot?,
        kma: SourceSnapshot?,
        owm: SourceSnapshot?,
        ensembleTemperature: Double,
        agreement: Double,
        avgAbsDeviation: Double
    ) {
        self.apple              = apple
        self.kma                = kma
        self.owm                = owm
        self.ensembleTemperature = ensembleTemperature
        self.agreement          = agreement
        self.avgAbsDeviation    = avgAbsDeviation
    }
}
