public protocol WeatherRepositoryProtocol: Sendable {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherSummary
}
