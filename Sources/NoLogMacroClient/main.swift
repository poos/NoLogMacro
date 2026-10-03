import NoLogMacro
import OSLog

// Setup a sink once (replaces the old `NoLogger.callback`).
NoLogger.shared.addSink(
    NoLogClosureSink { entry in
        let loc = "\(entry.file):\(entry.line)"
        let cat = entry.category.map { " @\($0)" } ?? ""
        let attrs = entry.attrs.map { " \($0)" } ?? ""
        print("[\(entry.level)]\(cat) \(entry.message)\(attrs) — \(loc)")
    },
    forKey: "console"
)

// Optional runtime level gate: drop anything below .debug.
NoLogger.shared.minLevel = .debug

// Plain usage keeps Xcode's click-to-source ability.
#noLog("hello world")
#noLog("user tapped", attrs: ["view": "home"])

// OSLog privacy / format interpolations now work.
let token = "abc123"
#noLog("token: \(token, privacy: .private)")

// Leveled variants, with subsystem / category support.
#noLogInfo("fetched profile", category: "network")
#noLogDebug("cache size: \(42)")
#noLogError("request failed", attrs: ["code": 500], subsystem: "com.example.app", category: "network")
#noLogFault("crash imminent")
