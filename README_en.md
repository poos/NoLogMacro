# **Not Only Log**

A Swift macro built on top of OSLog. Use `#noLog` instead of `Logger().log(...)` — you keep **Xcode's click-to-source-location ability** *and* get the same log forwarded to your own handling (custom storage, upload, sampling, …).

Since Xcode 15, OSLog entries in the console can jump straight to the line of code. Custom log libraries can't do that — until this macro: it expands in place into a real `Logger().log(...)`, so the location capability is preserved natively.

Comparison (GitHub's Markdown stops a gif after one play; click the image to replay):

![img](https://gitee.com/poos/NoLogMacro/raw/main/img/compare.gif)

## Features

- `#noLog` family of macros, expanding while preserving OSLog's click-to-source ability
- All `OSLogMessage` interpolations work: `\(value, privacy: .private)`, `\(d, format: .fixed(precision: 2))`, etc. (the macro generates a plain `String` copy for your callback automatically)
- `subsystem` / `category` support, so you can filter in the Console (if you pass only one, the other falls back to `NoLogDefaults`: subsystem defaults to `Bundle.main.bundleIdentifier`)
- Runtime level gating (`NoLogger.minLevel`); entries below the threshold cost nothing (the callback closure is never even evaluated)
- Multi-sink architecture: the `NoLogSink` protocol + `NoLogClosureSink`, so you can attach multiple destinations (file / network / third-party)
- Thread-safe (`NSLock`) and Swift 6 strict-concurrency ready

## Installation

Add `https://github.com/poos/NoLogMacro` via SPM, selecting the `NoLogMacro` library (and optionally the `NoLogMacroClient` example). Minimum deployment: macOS 11 / iOS 14 / watchOS 7 / tvOS 14 / visionOS 1.

## Usage

```swift
import OSLog
import NoLogMacro

// Register a sink once (replaces the old `NoLogger.callback`).
NoLogger.shared.addSink(
    NoLogClosureSink { entry in
        print("[\(entry.level)] \(entry.message) \(entry.attrs?.description ?? "")")
    },
    forKey: "console"
)

// Optional: runtime level gate; logs below this level never reach any sink.
NoLogger.shared.minLevel = .debug

// Equivalent to Logger().log(level: .default, "msg"), and locatable to this line.
#noLog("message")

// With extra structured fields.
#noLogError("request failed", attrs: ["code": 500])

// OSLog privacy / format interpolations now work.
let token = "abc123"
#noLog("token: \(token, privacy: .private)")

// With subsystem / category, handy for Console filtering.
#noLogInfo("fetched profile", category: "network")

// Level-specific convenience macros.
#noLogInfo("info")
#noLogDebug("debug", attrs: ["a": 3])
#noLogError("error", attrs: ["a": 4], subsystem: "com.example.app", category: "network")
#noLogFault("fault")
```

## Macro reference

| Macro | Equivalent level |
|---|---|
| `#noLog("msg")` | `.default` |
| `#noLog(level: .info, "msg")` | any |
| `#noLogInfo("msg")` | `.info` |
| `#noLogDebug("msg")` | `.debug` |
| `#noLogError("msg")` | `.error` |
| `#noLogFault("msg")` | `.fault` |

All macros accept the optional parameters `attrs:`, `subsystem:`, `category:`.

## Migrating from older versions

The old `NoLogger.callback` is now `deprecated` but still works; prefer:

```swift
// Old
NoLogger.callback = { type, message, attrs in ... }

// New
NoLogger.shared.addSink(NoLogClosureSink { entry in ... }, forKey: "console")
```

Note the callback's `attrs` type changed from `Dictionary<String, Any>?` to `[String: any Sendable]?`.

## TODO

- [x] Support `Logger(subsystem:category:)` (via `subsystem:` / `category:` arguments)
- [x] OSLog privacy / format interpolations (e.g. `privacy: .private`)
- [x] Multiple sinks / structured `attrs`
- [x] Swift 6 strict concurrency & thread safety
- [ ] Compile-time stripping of debug/info based on build flags (design pending so it does not break code location)
