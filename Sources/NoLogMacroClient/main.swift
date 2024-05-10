import NoLogMacro
import OSLog

Logger().log(level: .default, "default")
#noLog("default")
#noLog("default", attrs: ["a": 1])

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
