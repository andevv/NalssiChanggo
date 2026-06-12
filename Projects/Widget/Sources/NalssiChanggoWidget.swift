import WidgetKit
import SwiftUI
import Combine
import WeatherDomain
import WeatherData
import Core
import DesignSystem

// MARK: - Bundle Entry Point

@main
struct NalssiChanggoWidgetBundle: WidgetBundle {
    init() {
        // 위젯 익스텐션은 앱과 별도 프로세스이므로 독립적으로 폰트를 등록한다.
        FontRegistrar.register()
    }

    var body: some Widget {
        NalssiChanggoWidget()
        LockScreenWeatherWidget()
    }
}

// MARK: - Widget Configuration

struct NalssiChanggoWidget: Widget {
    let kind = "NalssiChanggoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            NalssiChanggoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("날씨창고")
        .description("오늘의 날씨를 홈 화면에서 확인하세요.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Timeline Entry

struct WeatherEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetWeatherSnapshot?
}

// MARK: - Timeline Provider

struct WeatherTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        let snapshot = WidgetWeatherSnapshot.load() ?? .placeholder
        completion(WeatherEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        // 앱이 방금 fetch한 캐시가 있으면 그 값을 그대로 사용한다.
        // reloadTimelines 트리거 → getTimeline 호출 사이의 시간은 통상 수 초~1분이므로,
        // 10분 이내 캐시 = 앱이 쓴 데이터 → 위젯과 앱이 동일한 온도를 표시하게 된다.
        if let appFreshSnapshot = WidgetWeatherSnapshot.load(),
           Date().timeIntervalSince(appFreshSnapshot.updatedAt) < 10 * 60 {
            let nextRefresh = appFreshSnapshot.updatedAt.addingTimeInterval(6 * 3600)
            completion(buildTimelineFromSnapshot(appFreshSnapshot, nextRefresh: nextRefresh))
            return
        }

        // 캐시가 없거나 10분을 넘으면 위젯이 직접 앙상블 fetch
        Task {
            guard let location = LocationSnapshot.load() else {
                completion(cachedTimeline() ?? emptyTimeline())
                return
            }

            do {
                let summary = try await fetchEnsembledWeather(location: location)
                let entries = buildEntries(from: summary, locationName: location.locationName)
                let nextRefresh = Date().addingTimeInterval(6 * 3600)
                completion(Timeline(entries: entries, policy: .after(nextRefresh)))
            } catch {
                NCLogger.warning("Widget fetch 실패, 캐시 폴백: \(error.localizedDescription)", category: .weather)
                let retry = Date().addingTimeInterval(30 * 60)
                let timeline = cachedTimeline() ?? emptyTimeline()
                completion(Timeline(entries: timeline.entries, policy: .after(retry)))
            }
        }
    }

    // MARK: - Fetch

    private func fetchEnsembledWeather(location: LocationSnapshot) async throws -> WeatherSummary {
        let repository = WeatherRepositoryImpl(
            airKoreaAPIKey: nil,   // 위젯은 대기질 표시 없음
            kmaAPIKey: Secrets.kmaServiceKey,
            owmAPIKey: Secrets.openWeatherMapAPIKey
        )
        return try await repository
            .fetchWeather(
                latitude: location.latitude,
                longitude: location.longitude,
                locationName: location.locationName
            )
            .async()
    }

    // MARK: - Entry 빌더

    private func buildEntries(from summary: WeatherSummary, locationName: String) -> [WeatherEntry] {
        let now = Date()
        let current = summary.current
        let daily = summary.dailyForecasts.first

        let currentSnapshot = WidgetWeatherSnapshot(
            temperature: Int(current.temperature.rounded()),
            feelsLike: Int(current.feelsLike.rounded()),
            conditionLabel: current.state.koreanLabel,
            weatherIconRaw: mapWeatherIcon(state: current.state, isDaytime: current.isDaytime).rawValue,
            precipitationChance: Int(((daily?.precipitationChance) ?? 0) * 100),
            todayLow: daily.map { Int($0.lowTemperature.rounded()) },
            todayHigh: daily.map { Int($0.highTemperature.rounded()) },
            locationName: locationName,
            updatedAt: now
        )

        var entries = [WeatherEntry(date: now, snapshot: currentSnapshot)]

        // 현재 이후 슬롯으로 최대 11개 Entry 추가 — WidgetKit이 각 시각에 자동 전환
        let hourlyEntries: [WeatherEntry] = summary.hourlyForecasts
            .filter { $0.date > now }
            .prefix(11)
            .map { forecast in
                let hour = Calendar.current.component(.hour, from: forecast.date)
                let isDaytime = (6..<20).contains(hour)
                let hourlySnapshot = WidgetWeatherSnapshot(
                    temperature: Int(forecast.temperature.rounded()),
                    feelsLike: currentSnapshot.feelsLike,  // 시간별 예보에 체감온도 없음 — 현재값 유지
                    conditionLabel: forecast.state.koreanLabel,
                    weatherIconRaw: mapWeatherIcon(state: forecast.state, isDaytime: isDaytime).rawValue,
                    precipitationChance: Int((forecast.precipitationChance * 100).rounded()),
                    todayLow: currentSnapshot.todayLow,
                    todayHigh: currentSnapshot.todayHigh,
                    locationName: locationName,
                    updatedAt: now
                )
                return WeatherEntry(date: forecast.date, snapshot: hourlySnapshot)
            }

        entries.append(contentsOf: hourlyEntries)
        return entries
    }

    // MARK: - 캐시 기반 타임라인 빌더

    private func buildTimelineFromSnapshot(
        _ snapshot: WidgetWeatherSnapshot,
        nextRefresh: Date
    ) -> Timeline<WeatherEntry> {
        let now = Date()
        var entries = [WeatherEntry(date: now, snapshot: snapshot)]
        let hourlyEntries: [WeatherEntry] = snapshot.hourlyForecasts
            .filter { $0.date > now }
            .map { hourly in
                let hourlySnapshot = WidgetWeatherSnapshot(
                    temperature: hourly.temperature,
                    feelsLike: snapshot.feelsLike,
                    conditionLabel: snapshot.conditionLabel,
                    weatherIconRaw: hourly.weatherIconRaw,
                    precipitationChance: hourly.precipitationChance,
                    todayLow: snapshot.todayLow,
                    todayHigh: snapshot.todayHigh,
                    locationName: snapshot.locationName,
                    updatedAt: snapshot.updatedAt
                )
                return WeatherEntry(date: hourly.date, snapshot: hourlySnapshot)
            }
        entries.append(contentsOf: hourlyEntries)
        return Timeline(entries: entries, policy: .after(nextRefresh))
    }

    private func cachedTimeline() -> Timeline<WeatherEntry>? {
        guard let snapshot = WidgetWeatherSnapshot.load() else { return nil }
        return buildTimelineFromSnapshot(snapshot, nextRefresh: Date().addingTimeInterval(30 * 60))
    }

    private func emptyTimeline() -> Timeline<WeatherEntry> {
        Timeline(entries: [WeatherEntry(date: .now, snapshot: nil)], policy: .after(Date().addingTimeInterval(3600)))
    }
}

// MARK: - WeatherState → WeatherIcon 매핑

private func mapWeatherIcon(state: WeatherState, isDaytime: Bool) -> WeatherIcon {
    switch state {
    case .clear, .mostlyClear, .hot:
        return isDaytime ? .sun : .moon
    case .partlyCloudy:
        return isDaytime ? .cloudSun : .moonCloud
    case .mostlyCloudy, .cloudy:
        return .cloud
    case .drizzle, .rain, .sleet:
        return .cloudRain
    case .heavyRain, .thunderstorm:
        return .cloudHeavyRain
    case .snow, .heavySnow, .blizzard, .frigid:
        return .cloudSnow
    case .fog, .haze:
        return .fog
    case .windy:
        return .wind
    case .unknown:
        return isDaytime ? .cloudSun : .moonCloud
    }
}

// MARK: - Root Entry View

struct NalssiChanggoWidgetEntryView: View {
    let entry: WeatherEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                WeatherWidgetContent(snapshot: snapshot)
            } else {
                EmptyWidgetView()
            }
        }
        .widgetURL(URL(string: "nalssichanggo://main"))
    }
}

// MARK: - Weather Content View

private struct WeatherWidgetContent: View {
    let snapshot: WidgetWeatherSnapshot

    private var icon: WeatherIcon {
        WeatherIcon(rawValue: snapshot.weatherIconRaw) ?? .cloudSun
    }

    private var updatedLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm 기준"
        return formatter.string(from: snapshot.updatedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header: 지역명 + 날씨 아이콘 ─────────────────────────
            HStack(alignment: .center, spacing: 0) {
                Text(snapshot.locationName)
                    .font(NCFont.labelSmall)          // 11pt Regular
                    .foregroundStyle(Color.ink3)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 4)

                WeatherIconView(icon, size: 30)
                    .foregroundStyle(snapshot.isStale ? Color.inkFaint : Color.goldDeep)
            }

            Spacer(minLength: 4)

            // ── 메인 기온 ─────────────────────────────────────────────
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(snapshot.temperature)")
                    .font(NCFont.widgetTemp)           // 48pt Bold
                    .foregroundStyle(snapshot.isStale ? Color.ink4 : Color.ink)
                    .tracking(-2)
                    .contentTransition(.numericText())
                Text("°")
                    .font(NCFont.widgetDeg)            // 28pt Medium
                    .foregroundStyle(Color.ink3)
                    .offset(y: -2)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            // ── 날씨 상태 + 체감온도 ──────────────────────────────────
            Text("\(snapshot.conditionLabel) · 체감 \(snapshot.feelsLike)°")
                .font(NCFont.chip)                    // 12pt Medium
                .foregroundStyle(Color.ink3)
                .lineLimit(1)
                .padding(.top, 2)
                .contentTransition(.numericText())

            Spacer(minLength: 6)

            // ── 구분선 ────────────────────────────────────────────────
            Rectangle()
                .fill(Color.hairline)
                .frame(height: 0.5)
                .padding(.bottom, 6)

            // ── 최저·최고·강수 ────────────────────────────────────────
            HStack(alignment: .center, spacing: 0) {
                if let low = snapshot.todayLow, let high = snapshot.todayHigh {
                    HStack(spacing: 5) {
                        Text("↓\(low)°")
                            .foregroundStyle(Color.ink4)
                            .contentTransition(.numericText())
                        Text("↑\(high)°")
                            .foregroundStyle(Color.ink2)
                            .contentTransition(.numericText())
                    }
                    .font(NCFont.monoBody)             // 11pt Regular
                }

                Spacer(minLength: 0)

                if snapshot.precipitationChance >= 10 {
                    HStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 8, weight: .regular))
                        Text("\(snapshot.precipitationChance)%")
                            .font(NCFont.monoBody)
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(
                        snapshot.precipitationChance >= 40 ? Color.rain : Color.ink4
                    )
                }
            }

            // ── 갱신 시각 ─────────────────────────────────────────────
            HStack {
                Spacer()
                Text(updatedLabel)
                    .font(NCFont.monoTiny)             // 9pt Medium
                    .foregroundStyle(snapshot.isStale ? Color.warn : Color.inkFaint)
            }
            .padding(.top, 3)
        }
        .containerBackground(Color.paper, for: .widget)
    }
}

// MARK: - Empty (No Data) View

private struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: NCSpacing.small) {
            WeatherIconView(.cloudSun, size: 32)
                .foregroundStyle(Color.inkFaint)

            Text("앱을 열어\n날씨를 불러오세요")
                .font(NCFont.labelSmall)
                .foregroundStyle(Color.ink4)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color.paper, for: .widget)
    }
}

// MARK: - Lock Screen Widget Configuration

struct LockScreenWeatherWidget: Widget {
    let kind = "LockScreenWeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("날씨창고")
        .description("잠금 화면에서 현재 날씨를 확인하세요.")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Lock Screen Root Entry View

private struct LockScreenWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WeatherEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                switch family {
                case .accessoryInline:
                    AccessoryInlineWidgetView(snapshot: snapshot)
                case .accessoryCircular:
                    AccessoryCircularWidgetView(snapshot: snapshot)
                case .accessoryRectangular:
                    AccessoryRectangularWidgetView(snapshot: snapshot)
                default:
                    EmptyView()
                }
            } else {
                switch family {
                case .accessoryInline:
                    Label("날씨창고", systemImage: "cloud.sun")
                case .accessoryCircular:
                    ZStack {
                        AccessoryWidgetBackground()
                        Image(systemName: "cloud.sun")
                            .font(.system(size: 20))
                    }
                case .accessoryRectangular:
                    Label("앱을 열어 날씨를 불러오세요", systemImage: "cloud.sun")
                default:
                    EmptyView()
                }
            }
        }
        .widgetURL(URL(string: "nalssichanggo://main"))
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Accessory Inline View

private struct AccessoryInlineWidgetView: View {
    let snapshot: WidgetWeatherSnapshot

    private var sfSymbol: String {
        WeatherIcon(rawValue: snapshot.weatherIconRaw)?.sfSymbolName ?? "cloud.sun"
    }

    var body: some View {
        Label("\(snapshot.temperature)° \(snapshot.conditionLabel)", systemImage: sfSymbol)
    }
}

// MARK: - Accessory Circular View

private struct AccessoryCircularWidgetView: View {
    let snapshot: WidgetWeatherSnapshot

    private var icon: WeatherIcon {
        WeatherIcon(rawValue: snapshot.weatherIconRaw) ?? .cloudSun
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                WeatherIconView(icon, size: 20)
                    .widgetAccentable()
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("\(snapshot.temperature)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text("°")
                        .font(.system(size: 11, weight: .medium))
                }
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            }
        }
    }
}

// MARK: - Accessory Rectangular View

private struct AccessoryRectangularWidgetView: View {
    let snapshot: WidgetWeatherSnapshot

    private var icon: WeatherIcon {
        WeatherIcon(rawValue: snapshot.weatherIconRaw) ?? .cloudSun
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // 아이콘 + 기온
            VStack(alignment: .center, spacing: 0) {
                WeatherIconView(icon, size: 28)
                    .widgetAccentable()
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("\(snapshot.temperature)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("°")
                        .font(.system(size: 16, weight: .medium))
                        .offset(y: -1)
                }
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            }

            // 날씨 상태 + 최저최고 + 강수
            VStack(alignment: .leading, spacing: 3) {
                Text(snapshot.conditionLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                if let low = snapshot.todayLow, let high = snapshot.todayHigh {
                    Text("↓\(low)° ↑\(high)°")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                if snapshot.precipitationChance >= 10 {
                    Label("\(snapshot.precipitationChance)%", systemImage: "drop.fill")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Placeholder Snapshot

private extension WidgetWeatherSnapshot {
    static let placeholder = WidgetWeatherSnapshot(
        temperature: 22,
        feelsLike: 20,
        conditionLabel: "맑음",
        weatherIconRaw: WeatherIcon.sun.rawValue,
        precipitationChance: 0,
        todayLow: 15,
        todayHigh: 26,
        locationName: "서울 강남구",
        updatedAt: Date()
    )
}

// MARK: - Previews

#Preview("날씨 있음", as: .systemSmall) {
    NalssiChanggoWidget()
} timeline: {
    WeatherEntry(date: .now, snapshot: .placeholder)
}

#Preview("숫자 트랜지션", as: .systemSmall) {
    NalssiChanggoWidget()
} timeline: {
    WeatherEntry(date: .now, snapshot: WidgetWeatherSnapshot(
        temperature: 15, feelsLike: 12, conditionLabel: "맑음",
        weatherIconRaw: WeatherIcon.sun.rawValue,
        precipitationChance: 10, todayLow: 10, todayHigh: 22,
        locationName: "서울 강남구", updatedAt: .now
    ))
    WeatherEntry(date: .now + 3600, snapshot: WidgetWeatherSnapshot(
        temperature: 23, feelsLike: 21, conditionLabel: "구름 조금",
        weatherIconRaw: WeatherIcon.cloudSun.rawValue,
        precipitationChance: 40, todayLow: 10, todayHigh: 26,
        locationName: "서울 강남구", updatedAt: .now + 3600
    ))
}

#Preview("데이터 없음", as: .systemSmall) {
    NalssiChanggoWidget()
} timeline: {
    WeatherEntry(date: .now, snapshot: nil)
}

#Preview("잠금화면 인라인", as: .accessoryInline) {
    LockScreenWeatherWidget()
} timeline: {
    WeatherEntry(date: .now, snapshot: .placeholder)
}

#Preview("잠금화면 원형", as: .accessoryCircular) {
    LockScreenWeatherWidget()
} timeline: {
    WeatherEntry(date: .now, snapshot: .placeholder)
}

#Preview("잠금화면 직사각형", as: .accessoryRectangular) {
    LockScreenWeatherWidget()
} timeline: {
    WeatherEntry(date: .now, snapshot: .placeholder)
}

#Preview("잠금화면 직사각형 — 강수 있음", as: .accessoryRectangular) {
    LockScreenWeatherWidget()
} timeline: {
    WeatherEntry(
        date: .now,
        snapshot: WidgetWeatherSnapshot(
            temperature: 18,
            feelsLike: 15,
            conditionLabel: "구름 많음",
            weatherIconRaw: WeatherIcon.cloudRain.rawValue,
            precipitationChance: 60,
            todayLow: 12,
            todayHigh: 22,
            locationName: "서울 강남구",
            updatedAt: Date()
        )
    )
}

#Preview("만료된 데이터", as: .systemSmall) {
    NalssiChanggoWidget()
} timeline: {
    WeatherEntry(
        date: .now,
        snapshot: WidgetWeatherSnapshot(
            temperature: 18,
            feelsLike: 16,
            conditionLabel: "구름 조금",
            weatherIconRaw: WeatherIcon.cloudSun.rawValue,
            precipitationChance: 30,
            todayLow: 12,
            todayHigh: 22,
            locationName: "서울 강남구",
            updatedAt: Date().addingTimeInterval(-7 * 3600) // 7시간 전
        )
    )
}
