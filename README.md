# **Not Only Log**

一个基于 OSLog 的 Swift 宏：用 `#noLog` 代替 `Logger().log(...)`，**既保留了 Xcode 控制台点击跳转到源码行的能力，又能把同一条日志转发给你自己的处理逻辑**（自定义存储、上报、采样等）。

Xcode 15 起，控制台里的 OSLog 日志可以直接定位到代码行。但自己写的日志库做不到这一点——直到有了这个宏：它在调用处原地展开成真正的 `Logger().log(...)`，所以定位能力天然保留。

对比效果（GitHub 的 Markdown 下 gif 播一次会停，可点开原图重复看）：

![img](https://gitee.com/poos/NoLogMacro/raw/main/img/compare.gif)

## 功能

- `#noLog` 系列宏，展开后保留 OSLog 的原生代码定位能力
- `OSLogMessage` 专属插值全部可用：`\(value, privacy: .private)`、`\(d, format: .fixed(precision: 2))` 等（宏会自动生成一份 `String` 版本供你的回调使用）
- `subsystem` / `category` 支持，可在 Console 中按模块过滤
- 运行时级别过滤（`NoLogger.minLevel`），低于阈值的条目零成本（回调闭包不会被求值）
- 多 sink 架构：`NoLogSink` 协议 + `NoLogClosureSink`，可同时挂多个目标（文件 / 网络 / 第三方）
- 线程安全（`NSLock`），符合 Swift 6 严格并发

## 安装

通过 SPM 添加 `https://github.com/poos/NoLogMacro`，勾选 `NoLogMacro` 库（以及可选的 `NoLogMacroClient` 示例）。最低支持 macOS 11 / iOS 14 / watchOS 7 / tvOS 14 / visionOS 1。

## 使用

```swift
import OSLog
import NoLogMacro

// 一次性注册一个 sink（取代旧版的 NoLogger.callback）
NoLogger.shared.addSink(
    NoLogClosureSink { entry in
        print("[\(entry.level)] \(entry.message) \(entry.attrs?.description ?? "")")
    },
    forKey: "console"
)

// 可选：运行时级别门控，低于该级别的日志不进入任何 sink
NoLogger.shared.minLevel = .debug

// 与 Logger().log(level: .default, "msg") 等价，且能定位到这一行
#noLog("message")

// 携带额外结构化字段
#noLogError("request failed", attrs: ["code": 500])

// OSLog 隐私 / 格式插值现在可用
let token = "abc123"
#noLog("token: \(token, privacy: .private)")

// 带 subsystem / category，便于在 Console 过滤
#noLogInfo("fetched profile", category: "network")

// 指定级别的便捷宏
#noLogInfo("info")
#noLogDebug("debug", attrs: ["a": 3])
#noLogError("error", attrs: ["a": 4], subsystem: "com.example.app", category: "network")
#noLogFault("fault")
```

## 宏速查

| 宏 | 等价 level |
|---|---|
| `#noLog("msg")` | `.default` |
| `#noLog(level: .info, "msg")` | 任意 |
| `#noLogInfo("msg")` | `.info` |
| `#noLogDebug("msg")` | `.debug` |
| `#noLogError("msg")` | `.error` |
| `#noLogFault("msg")` | `.fault` |

所有宏都接受可选参数 `attrs:`、`subsystem:`、`category:`。

## 从旧版迁移

旧版 `NoLogger.callback` 已标注 `deprecated`，仍可继续工作，但建议改为：

```swift
// 旧
NoLogger.callback = { type, message, attrs in ... }

// 新
NoLogger.shared.addSink(NoLogClosureSink { entry in ... }, forKey: "console")
```

注意回调参数里的 `attrs` 类型由 `Dictionary<String, Any>?` 变为 `[String: any Sendable]?`。

## TODO

- [x] 支持 `Logger(subsystem:category:)`（通过 `subsystem:` / `category:` 参数）
- [x] OSLog 隐私 / 格式插值（如 `privacy: .private`）
- [x] 多 sink / 结构化 attrs
- [x] Swift 6 严格并发、线程安全
- [ ] 编译期按 build flag 裁剪 debug/info（需在不破坏代码定位的前提下设计，待定）
