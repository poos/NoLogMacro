// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import OSLog

/// A single log record produced by `#noLog`.
///
/// `message` is already a plain `String` (the macro strips OSLog-only
/// interpolations such as `\(value, privacy: .private)`), so sinks can format
/// and forward it freely without involving `OSLog`.
public struct NoLogEntry: Sendable {
    public let level: OSLogType
    public let message: String
    public let attrs: [String: any Sendable]?
    public let category: String?
    public let file: String
    public let line: Int

    public init(
        level: OSLogType,
        message: String,
        attrs: [String: any Sendable]? = nil,
        category: String? = nil,
        file: String = #fileID,
        line: Int = #line
    ) {
        self.level = level
        self.message = message
        self.attrs = attrs
        self.category = category
        self.file = file
        self.line = line
    }
}

/// Fallback values used when `#noLog` is given only `subsystem:` or only
/// `category:` (a `Logger` requires both). The macro refers to these names
/// directly, so no extra import is needed at the call site.
public enum NoLogDefaults {
    public static let subsystem: String = Bundle.main.bundleIdentifier ?? "NoLogMacro"
    public static let category: String = "default"
}

/// A destination for log entries. Implement this to ship logs to a file, a
/// remote service, a third-party analytics SDK, etc.
public protocol NoLogSink: Sendable {
    func write(_ entry: @autoclosure () -> NoLogEntry)
}

/// A sink backed by a plain closure.
public struct NoLogClosureSink: NoLogSink {
    private let handler: @Sendable (NoLogEntry) -> Void

    public init(_ handler: @escaping @Sendable (NoLogEntry) -> Void) {
        self.handler = handler
    }

    public func write(_ entry: @autoclosure () -> NoLogEntry) {
        handler(entry())
    }
}

/// Thread-safe registry of sinks and the minimum level gate.
public final class NoLogger: @unchecked Sendable {
    public static let shared = NoLogger()

    private let lock = NSLock()
    nonisolated(unsafe) private var _sinks: [any NoLogSink] = []
    nonisolated(unsafe) private var _sinkKeys: [String] = []
    nonisolated(unsafe) private var _minLevel: OSLogType?

    /// Entries below this level are dropped. `nil` means "no filtering".
    public var minLevel: OSLogType? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _minLevel
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _minLevel = newValue
        }
    }

    private init() {}

    /// Add a sink. Re-adding the same `key` is a no-op (useful for one-time setup).
    public func addSink(_ sink: any NoLogSink, forKey key: String = UUID().uuidString) {
        lock.lock()
        defer { lock.unlock() }
        guard !_sinkKeys.contains(key) else { return }
        _sinkKeys.append(key)
        _sinks.append(sink)
    }

    public func removeSink(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        guard let idx = _sinkKeys.firstIndex(of: key) else { return }
        _sinkKeys.remove(at: idx)
        _sinks.remove(at: idx)
    }

    public func removeAllSinks() {
        lock.lock()
        defer { lock.unlock() }
        _sinks.removeAll()
        _sinkKeys.removeAll()
    }

    /// Backward-compatible single callback. Deprecated in favor of `addSink`.
    @available(*, deprecated, message: "Use `addSink(_:)` / `NoLogClosureSink` instead.")
    public var callback: (@Sendable (OSLogType, String, [String: any Sendable]?) -> Void)? {
        didSet {
            if let callback {
                addSink(NoLogClosureSink { callback($0.level, $0.message, $0.attrs) }, forKey: "_deprecated_callback")
            } else {
                removeSink(forKey: "_deprecated_callback")
            }
        }
    }

    func isEnabled(level: OSLogType) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !_sinks.isEmpty else { return false }
        // Read `_minLevel` directly: the public `minLevel` getter takes the same
        // non-recursive lock, so calling it here would deadlock.
        guard let min = _minLevel else { return true }
        return rank(level) >= rank(min)
    }

    func dispatch(_ entry: NoLogEntry) {
        lock.lock()
        let sinks = _sinks
        lock.unlock()
        for sink in sinks {
            sink.write(entry)
        }
    }

    private func rank(_ type: OSLogType) -> Int {
        if type == .debug { return 0 }
        if type == .info { return 1 }
        if type == .default { return 2 }
        if type == .error { return 3 }
        if type == .fault { return 4 }
        return 2
    }
}

extension Logger {
    /// Emits the entry to every registered `NoLogSink` (respecting `NoLogger.minLevel`),
    /// then returns `self` so the call can be chained into `log(level:_:)`.
    ///
    /// The `message` closure is only evaluated when at least one sink is enabled
    /// for the given level, so disabled logs cost almost nothing.
    @discardableResult
    public func noLog(
        level: OSLogType = .`default`,
        _ message: @autoclosure () -> String,
        attrs: [String: any Sendable]? = nil,
        category: String? = nil,
        file: String = #fileID,
        line: Int = #line
    ) -> Self {
        if NoLogger.shared.isEnabled(level: level) {
            let entry = NoLogEntry(
                level: level,
                message: message(),
                attrs: attrs,
                category: category,
                file: file,
                line: line
            )
            NoLogger.shared.dispatch(entry)
        }
        return self
    }
}

// MARK: - Public macro declarations

@freestanding(expression)
public macro noLog(
    _ message: OSLogMessage,
    level: OSLogType = .`default`,
    attrs: [String: any Sendable]? = nil,
    subsystem: String? = nil,
    category: String? = nil
) = #externalMacro(module: "NoLogMacroMacros", type: "NoLogMacro")

@freestanding(expression)
public macro noLogInfo(
    _ message: OSLogMessage,
    attrs: [String: any Sendable]? = nil,
    subsystem: String? = nil,
    category: String? = nil
) = #externalMacro(module: "NoLogMacroMacros", type: "NoLogInfoMacro")

@freestanding(expression)
public macro noLogDebug(
    _ message: OSLogMessage,
    attrs: [String: any Sendable]? = nil,
    subsystem: String? = nil,
    category: String? = nil
) = #externalMacro(module: "NoLogMacroMacros", type: "NoLogDebugMacro")

@freestanding(expression)
public macro noLogError(
    _ message: OSLogMessage,
    attrs: [String: any Sendable]? = nil,
    subsystem: String? = nil,
    category: String? = nil
) = #externalMacro(module: "NoLogMacroMacros", type: "NoLogErrorMacro")

@freestanding(expression)
public macro noLogFault(
    _ message: OSLogMessage,
    attrs: [String: any Sendable]? = nil,
    subsystem: String? = nil,
    category: String? = nil
) = #externalMacro(module: "NoLogMacroMacros", type: "NoLogFaultMacro")
