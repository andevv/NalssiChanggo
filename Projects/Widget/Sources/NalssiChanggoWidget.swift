import WidgetKit
import SwiftUI
import WeatherDomain
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
        let snapshot = WidgetWeatherSnapshot.load()
        let entry = WeatherEntry(date: .now, snapshot: snapshot)

        // 데이터 있고 6시간 내 — 앱이 갱신할 때까지 대기
        // 데이터 없거나 만료 — 1시간 뒤 다시 시도 (앱이 미실행 상태인 fallback)
        let policy: TimelineReloadPolicy = {
            guard let snap = snapshot, !snap.isStale else {
                return .after(Date().addingTimeInterval(3600))
            }
            return .never
        }()

        completion(Timeline(entries: [entry], policy: policy))
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
                        Text("↑\(high)°")
                            .foregroundStyle(Color.ink2)
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

#Preview("데이터 없음", as: .systemSmall) {
    NalssiChanggoWidget()
} timeline: {
    WeatherEntry(date: .now, snapshot: nil)
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
