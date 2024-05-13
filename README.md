# **Not Only Log**
一个宏，内部基于OSLog库中Logger.

Xcode15后，debug控制台提供了非常有用的日志输入，其中包括了可直接定位到代码行的功能。

遗憾的是，我们app自定义的日志库无法实现同样的定位代码行。一直到......有了这个库:

随着Xcode15来的Swift宏让上边的设想能够实现，下边是个例子：

**What's the difference**
> github的markdown，gif播放一次后会停止播放，可以点击图片到原图，可重复播放
![img](https://gitee.com/poos/NoLogMacro/raw/main/img/compare.gif)

可以看到，常规方法的log无法定位到正确的代码行。通过本库提供的方法可以完美的以宏的方式支持，非常轻量级。

## Using

- 右键添加 Package，通过链接 `https://github.com/poos/NoLogMacro` 添加，同时选择 Lib 和 Client
- `import OSLog` 和 `import NoLogMacro`，初始化 `NoLogger.callback`（可选）
- 使用`#noLog()` 代替 `Logger().log()`

gif:

> github的markdown，gif播放一次后会停止播放，可以点击图片到原图，可重复播放
![img](https://gitee.com/poos/NoLogMacro/raw/main/img/use.gif)

step1:

![img](https://gitee.com/poos/NoLogMacro/raw/main/img/example1.png)

![img](https://gitee.com/poos/NoLogMacro/raw/main/img/example2.png)

step2:

![img](https://gitee.com/poos/NoLogMacro/raw/main/img/example3.png)

### Code

Just like:

```
//import
import OSLog
import NoLogMacro

// set once
NoLogger.callback = { (type: OSLogType, message: String, attrs: Dictionary<String, Any>?) in
    print("simple type: \(type) message: \(message) dic: \(String(describing: attrs))")
}


// all log can send to `NoLogger.callback`
// **can be located to a line**

// same with `Logger().log(level: .default, "default")`
#noLog("message")
// and more custom info
#noLogError("error", attrs: ["code": 404])

// others
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
```

## TODO List

- support `Logger(subsystem: <#T##String#>, category: <#T##String#>)`
- brew iOS 14, using print support
- using Swift Macro writing this lib