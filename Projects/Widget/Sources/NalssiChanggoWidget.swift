import WidgetKit
import SwiftUI

@main
struct NalssiChanggoWidgetBundle: WidgetBundle {
    var body: some Widget {
        NalssiChanggoWidget()
    }
}

struct NalssiChanggoWidget: Widget {
    let kind = "NalssiChanggoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            NalssiChanggoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("날씨창고")
        .description("현재 날씨를 홈 화면에서 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WeatherEntry: TimelineEntry {
    let date: Date
}

struct WeatherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        completion(WeatherEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let entry = WeatherEntry(date: .now)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct NalssiChanggoWidgetEntryView: View {
    let entry: WeatherEntry

    var body: some View {
        Text("날씨창고")
    }
}
