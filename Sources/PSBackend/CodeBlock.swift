//
//  CodeBlock.swift
//  PSBackend
//

import Foundation


import Foundation

@preconcurrency import CPython
@preconcurrency import PySwiftKit
@preconcurrency import PySerializing
@preconcurrency import PySwiftWrapper

extension UnsafeMutablePointer<PyTypeObject>: @unchecked Swift.Sendable {}
extension PyTypeObject: @unchecked Swift.Sendable {}


@PyClass(swift_mode: .v6)
public final class CodeBlock: PyDeserialize, @preconcurrency PyClassProtocol {
    
    public var code: String
    public var priority: Priority
    
    
    
    @PyInit
    init(code: String, priority: Int) {
        self.code = code
        self.priority = .init(rawValue: priority) ?? .post_imports
        
        //let a: String = try! PyDict_GetItem<String>(.None, key: "code")
    }
    
}

public extension CodeBlock {
    enum Priority: Int, PySerializable, Comparable {
        public static func < (lhs: CodeBlock.Priority, rhs: CodeBlock.Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        case imports
        case post_imports
        case pre_main
        case main
        case post_main
        case on_exit
    }
}

extension CodeBlock: CustomStringConvertible {
    
    public var description: String {
        code
    }
}
