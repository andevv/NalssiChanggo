public protocol FetchWeatherUseCaseProtocol: Sendable {
    func execute(latitude: Double, longitude: Double) async throws -> WeatherSummary
}
