import Foundation
import os

/// 전역 로거 — Xcode 콘솔 + Console.app 통합 지원
public enum NCLogger {

    public enum Category: String {
        case network  = "Network"
        case air      = "AirQuality"
        case weather  = "Weather"
        case location = "Location"
        case general  = "General"
    }

    private static let subsystem = "com.andev.nalssichanggo"

    public static func debug(_ message: String, category: Category = .general,
                             file: String = #file, line: Int = #line) {
        log(level: .debug, prefix: "DEBUG", message: message, category: category, file: file, line: line)
    }

    public static func info(_ message: String, category: Category = .general,
                            file: String = #file, line: Int = #line) {
        log(level: .info, prefix: "INFO ", message: message, category: category, file: file, line: line)
    }

    public static func warning(_ message: String, category: Category = .general,
                               file: String = #file, line: Int = #line) {
        log(level: .default, prefix: "WARN ", message: message, category: category, file: file, line: line)
    }

    public static func error(_ message: String, category: Category = .general,
                             file: String = #file, line: Int = #line) {
        log(level: .error, prefix: "ERROR", message: message, category: category, file: file, line: line)
    }

    // MARK: - Network 전용

    public static func request(url: URL?, category: Category = .network,
                               file: String = #file, line: Int = #line) {
        let urlString = url?.absoluteString ?? "nil"
        log(level: .debug, prefix: "→ REQ", message: urlString, category: category, file: file, line: line)
    }

    public static func response(statusCode: Int, body: Data?, category: Category = .network,
                                file: String = #file, line: Int = #line) {
        let preview = body.flatMap { String(data: $0.prefix(500), encoding: .utf8) } ?? "—"
        log(level: .debug, prefix: "← RES[\(statusCode)]", message: preview, category: category, file: file, line: line)
    }

    // MARK: - Private

    private static func log(level: OSLogType, prefix: String, message: String,
                            category: Category, file: String, line: Int) {
        let filename = (file as NSString).lastPathComponent
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        let formatted = "[\(prefix)] \(message)  (\(filename):\(line))"
        logger.log(level: level, "\(formatted, privacy: .public)")
    }
}
