import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum NoLogMacroError: Error, DiagnosticMessage {
    case missingMessage

    var message: String {
        "#noLog requires a message as its first argument, e.g. #noLog(\"hello\")"
    }
    var diagnosticID: MessageID {
        MessageID(domain: "NoLogMacro", id: "missingMessage")
    }
    var severity: DiagnosticSeverity { .error }
}

/// Build a `String`-compatible version of a string literal: OSLog's
/// `\(value, privacy: .private)` style expressions are only valid inside
/// `OSLogMessage`, so the copy handed to the plain `String` callback drops the
/// extra interpolation arguments and keeps only the first expression.
extension ExprSyntax {
    fileprivate func stringVersion() -> ExprSyntax {
        if var str = self.as(StringLiteralExprSyntax.self) {
            let segments = str.segments.map { segment in
                switch segment {
                case .stringSegment:
                    return segment
                case .expressionSegment(let exprSegment):
                    var newSegment = exprSegment
                    if var first = exprSegment.expressions.first {
                        first.trailingComma = nil
                        newSegment.expressions = LabeledExprListSyntax([first])
                    }
                    return .expressionSegment(newSegment)
                }
            }
            str.segments = StringLiteralSegmentListSyntax(segments)
            return ExprSyntax(str)
        }
        // Not a string literal (e.g. a variable): wrap it as "\(expr)".
        return ExprSyntax(stringLiteral: "\"\\(\(self))\"")
    }
}

private func normalizeLevel(_ raw: String) -> String {
    let name = raw.hasPrefix(".") ? String(raw.dropFirst()) : raw
    return name == "default" ? ".`default`" : raw
}

private func expand(
    node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext,
    levelOverride: String? = nil
) -> ExprSyntax {
    guard let messageExpr = node.arguments.first(where: { $0.label == nil })?.expression else {
        context.diagnose(Diagnostic(node: node, message: NoLogMacroError.missingMessage))
        return ExprSyntax(stringLiteral: "()")
    }

    // level
    let level: String
    if let levelOverride {
        level = levelOverride
    } else if let levelArg = node.arguments.first(where: { $0.label?.text == "level" })?.expression {
        level = normalizeLevel("\(levelArg)")
    } else {
        level = ".`default`"
    }

    // subsystem / category
    let subsystem = node.arguments.first(where: { $0.label?.text == "subsystem" })?.expression
    let category = node.arguments.first(where: { $0.label?.text == "category" })?.expression
    let loggerInit: String
    if subsystem != nil || category != nil {
        let subText = subsystem.map { "\($0)" } ?? "NoLogDefaults.subsystem"
        let catText = category.map { "\($0)" } ?? "NoLogDefaults.category"
        loggerInit = "Logger(subsystem: \(subText), category: \(catText))"
    } else {
        loggerInit = "Logger()"
    }

    let attrs = node.arguments.first(where: { $0.label?.text == "attrs" })?.expression
    let attrsText = attrs.map { "\($0)" } ?? "nil"
    let catText = category.map { "\($0)" } ?? "nil"

    let oslogMessage = "\(messageExpr)"
    let stringMessage = "\(messageExpr.stringVersion())"

    return """
        \(raw: loggerInit)
            .noLog(level: \(raw: level), \(raw: stringMessage), attrs: \(raw: attrsText), category: \(raw: catText))
            .log(level: \(raw: level), \(raw: oslogMessage))
        """
}

public struct NoLogMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        expand(node: node, in: context)
    }
}

public struct NoLogInfoMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        expand(node: node, in: context, levelOverride: ".info")
    }
}

public struct NoLogDebugMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        expand(node: node, in: context, levelOverride: ".debug")
    }
}

public struct NoLogErrorMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        expand(node: node, in: context, levelOverride: ".error")
    }
}

public struct NoLogFaultMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        expand(node: node, in: context, levelOverride: ".fault")
    }
}

@main
struct NoLogMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        NoLogMacro.self,
        NoLogInfoMacro.self,
        NoLogDebugMacro.self,
        NoLogErrorMacro.self,
        NoLogFaultMacro.self,
    ]
}
