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
            Logger().log(level: .default, "default")
            #noLog("default")
            #noLog("default", attrs: ["a": 1])
            #noLog(level: .info, "info", attrs: ["a": 1])
            #noLog(level: .error, "error", attrs: ["a": 2])
            #noLog(level: .info, "default")
            
            Logger().log(level: .info, "info")
            #noLogInfo("info")
            #noLogInfo("info", attrs: ["a": 2])
            
            Logger().log(level: .debug, "debug")
            #noLogDebug("debug")
            #noLogDebug("debug", attrs: ["a": 3])
            
            Logger().log(level: .error, "error")
            #noLogError("error")
            #noLogError("error", attrs: ["a": 4])
            
            Logger().log(level: .fault, "fault")
            #noLogFault("fault")
            #noLogFault("fault", attrs: ["a": 5])
            """,
            expandedSource: """
            Logger().log(level: .default, "default")
            Logger()
                 .noLog(level: .`default`, "default", attrs: nil)
                 .log(level: .`default`, "default")
            Logger()
                 .noLog(level: .`default`, "default", attrs: ["a": 1])
                 .log(level: .`default`, "default")
            Logger()
                 .noLog(level: .info, "info", attrs: ["a": 1])
                 .log(level: .info, "info")
            Logger()
                 .noLog(level: .error, "error", attrs: ["a": 2])
                 .log(level: .error, "error")
            Logger()
                 .noLog(level: .info, "default", attrs: nil)
                 .log(level: .info, "default")
            
            Logger().log(level: .info, "info")
            Logger()
                 .noLog(level: .info, "info", attrs: nil)
                 .log(level: .info, "info")
            Logger()
                 .noLog(level: .info, "info", attrs: ["a": 2])
                 .log(level: .info, "info")
            
            Logger().log(level: .debug, "debug")
            Logger()
                 .noLog(level: .debug, "debug", attrs: nil)
                 .log(level: .debug, "debug")
            Logger()
                 .noLog(level: .debug, "debug", attrs: ["a": 3])
                 .log(level: .debug, "debug")
            
            Logger().log(level: .error, "error")
            Logger()
                 .noLog(level: .error, "error", attrs: nil)
                 .log(level: .error, "error")
            Logger()
                 .noLog(level: .error, "error", attrs: ["a": 4])
                 .log(level: .error, "error")
            
            Logger().log(level: .fault, "fault")
            Logger()
                 .noLog(level: .fault, "fault", attrs: nil)
                 .log(level: .fault, "fault")
            Logger()
                 .noLog(level: .fault, "fault", attrs: ["a": 5])
                 .log(level: .fault, "fault")
            """,
            macros: testMacros
        )
    }
}
