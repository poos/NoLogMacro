import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import NoLogMacroMacros
import OSLog

let testMacros: [String: Macro.Type] = [
    "noLog": NoLogMacro.self,
    "noLogInfo": NoLogInfoMacro.self,
    "noLogDebug": NoLogDebugMacro.self,
    "noLogError": NoLogErrorMacro.self,
    "noLogFault": NoLogFaultMacro.self,
]

final class MyMacroTests: XCTestCase {
    func testMacro() throws {
        assertMacroExpansion(
            """
            #noLog("default")
            #noLog("default", attrs: ["a": 1])
            #noLog(level: .error, "error", attrs: ["a": 2])
            #noLog("token: \\(token, privacy: .private)")
            #noLogInfo("info", category: "net")
            #noLogDebug("debug")
            #noLogError("error")
            #noLogFault("fault", subsystem: "com.example")
            """,
            expandedSource: """
            Logger()
                .noLog(level: .`default`, "default", attrs: nil, category: nil)
                .log(level: .`default`, "default")
            Logger()
                .noLog(level: .`default`, "default", attrs: ["a": 1], category: nil)
                .log(level: .`default`, "default")
            Logger()
                .noLog(level: .error, "error", attrs: ["a": 2], category: nil)
                .log(level: .error, "error")
            Logger()
                .noLog(level: .`default`, "token: \\(token)", attrs: nil, category: nil)
                .log(level: .`default`, "token: \\(token, privacy: .private)")
            Logger(subsystem: NoLogDefaults.subsystem, category: "net")
                .noLog(level: .info, "info", attrs: nil, category: "net")
                .log(level: .info, "info")
            Logger()
                .noLog(level: .debug, "debug", attrs: nil, category: nil)
                .log(level: .debug, "debug")
            Logger()
                .noLog(level: .error, "error", attrs: nil, category: nil)
                .log(level: .error, "error")
            Logger(subsystem: "com.example", category: NoLogDefaults.category)
                .noLog(level: .fault, "fault", attrs: nil, category: nil)
                .log(level: .fault, "fault")
            """,
            macros: testMacros
        )
    }
}
