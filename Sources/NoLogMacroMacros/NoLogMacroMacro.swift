import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

import OSLog

public struct NoLogMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard ((node.argumentList.first?.expression) != nil) else {
            fatalError("compiler bug: the macro does not have any arguments")
        }
        var type: String?
        var msg: String?
        var attr: String?
        switch node.argumentList.count {
        case 3:
            type = "\(node.argumentList.first!.expression)"
            msg = "\(node.argumentList[node.argumentList.index(after: node.argumentList.startIndex)].expression)"
            attr = "\(node.argumentList.last!.expression)"
            
        case 2:
            if "\(String(describing: node.argumentList.first!.label))".contains("level") {
                type = "\(node.argumentList.first!.expression)"
                msg = "\(node.argumentList.last!.expression)"
                
            } else {
                msg = "\(node.argumentList.first!.expression)"
                attr = "\(node.argumentList.last!.expression)"
            }
            
        default:
            msg = "\(node.argumentList.first!.expression)"
        }
        
        return """
            Logger()
                 .noLog(level: \(raw: type ?? ".`default`"), \(raw: msg ?? ""), attrs: \(raw: attr ?? "nil"))
                 .log(level: \(raw: type ?? ".`default`"), \(raw: msg ?? ""))
            """
    }
}

public struct NoLogInfoMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard ((node.argumentList.first?.expression) != nil) else {
            fatalError("compiler bug: the macro does not have any arguments")
        }
        var msg: String?
        var attr: String?
        switch node.argumentList.count {
        case 2:
            msg = "\(node.argumentList.first!.expression)"
            attr = "\(node.argumentList.last!.expression)"
            
        default:
            msg = "\(node.argumentList.first!.expression)"
        }
        
        return """
            Logger()
                 .noLog(level: .info, \(raw: msg ?? ""), attrs: \(raw: attr ?? "nil"))
                 .log(level: .info, \(raw: msg ?? ""))
            """
    }
}

public struct NoLogDebugMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard ((node.argumentList.first?.expression) != nil) else {
            fatalError("compiler bug: the macro does not have any arguments")
        }
        var msg: String?
        var attr: String?
        switch node.argumentList.count {
        case 2:
            msg = "\(node.argumentList.first!.expression)"
            attr = "\(node.argumentList.last!.expression)"
            
        default:
            msg = "\(node.argumentList.first!.expression)"
        }
        
        return """
            Logger()
                 .noLog(level: .debug, \(raw: msg ?? ""), attrs: \(raw: attr ?? "nil"))
                 .log(level: .debug, \(raw: msg ?? ""))
            """
    }
}

public struct NoLogErrorMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard ((node.argumentList.first?.expression) != nil) else {
            fatalError("compiler bug: the macro does not have any arguments")
        }
        var msg: String?
        var attr: String?
        switch node.argumentList.count {
        case 2:
            msg = "\(node.argumentList.first!.expression)"
            attr = "\(node.argumentList.last!.expression)"
            
        default:
            msg = "\(node.argumentList.first!.expression)"
        }
        
        return """
            Logger()
                 .noLog(level: .error, \(raw: msg ?? ""), attrs: \(raw: attr ?? "nil"))
                 .log(level: .error, \(raw: msg ?? ""))
            """
    }
}

public struct NoLogFaultMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard ((node.argumentList.first?.expression) != nil) else {
            fatalError("compiler bug: the macro does not have any arguments")
        }
        var msg: String?
        var attr: String?
        switch node.argumentList.count {
        case 2:
            msg = "\(node.argumentList.first!.expression)"
            attr = "\(node.argumentList.last!.expression)"
            
        default:
            msg = "\(node.argumentList.first!.expression)"
        }
        
        return """
            Logger()
                 .noLog(level: .fault, \(raw: msg ?? ""), attrs: \(raw: attr ?? "nil"))
                 .log(level: .fault, \(raw: msg ?? ""))
            """
    }
}

@main
struct MyMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        NoLogMacro.self,
        NoLogInfoMacro.self,
        NoLogDebugMacro.self,
        NoLogErrorMacro.self,
        NoLogFaultMacro.self,
    ]
}

