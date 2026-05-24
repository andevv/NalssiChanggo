public struct AirQualityData: Sendable {
    /// AirDial 등급 (0=좋음 1=보통 2=나쁨 3=매우나쁨 4=위험)
    public let gradeIndex: Int
    public let grade: String
    /// PM2.5 평균 농도 μg/m³
    public let pm25Value: Int
    /// PM10 평균 농도 μg/m³
    public let pm10Value: Int

    public init(gradeIndex: Int, grade: String, pm25Value: Int, pm10Value: Int) {
        self.gradeIndex = gradeIndex
        self.grade = grade
        self.pm25Value = pm25Value
        self.pm10Value = pm10Value
    }
}
