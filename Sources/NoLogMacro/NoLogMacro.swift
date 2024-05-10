// The Swift Programming Language
// https://docs.swift.org/swift-book

import OSLog

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "NoLogMacroMacros", type: "StringifyMacro")

open class NoLogger {
    public static var callback: ((_ level: OSLogType, _ message: String, _ attrs: Dictionary<String, Any>?) -> Void)?
}

public extension Logger {
    func noLog(level: OSLogType = .`default`, _ message: String, attrs: Dictionary<String, Any>? = nil) -> Self {
        NoLogger.callback?(level, message, attrs)
        return self
    }
}

@freestanding(expression)
public macro noLog(_ message: OSLogMessage, attrs: Dictionary<String, Any>? = nil) = #externalMacro(module: "NoLogMacroMacros", type: "NoLogMacro")

@freestanding(expression)
public macro noLogInfo(_ message: OSLogMessage, attrs: Dictionary<String, Any>? = nil) -> Void = #externalMacro(module: "NoLogMacroMacros", type: "NoLogInfoMacro")

@freestanding(expression)
public macro noLogDebug(_ message: OSLogMessage, attrs: Dictionary<String, Any>? = nil) -> Void = #externalMacro(module: "NoLogMacroMacros", type: "NoLogDebugMacro")

@freestanding(expression)
public macro noLogError(_ message: OSLogMessage, attrs: Dictionary<String, Any>? = nil) -> Void = #externalMacro(module: "NoLogMacroMacros", type: "NoLogErrorMacro")

@freestanding(expression)
public macro noLogFault(_ message: OSLogMessage, attrs: Dictionary<String, Any>? = nil) -> Void = #externalMacro(module: "NoLogMacroMacros", type: "NoLogFaultMacro")
