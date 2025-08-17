//
//  CodeBlock.swift
//  PSBackend
//

import Foundation


import Foundation
import PySwiftKit
import PySerializing
import PyUnpack
import PySwiftWrapper
import PySwiftObject

@PyClass
public final class CodeBlock: PyDeserialize {
    
    public var code: String
    public var priority: Priority
    
    @PyInit
    init(code: String, priority: Int) {
        self.code = code
        self.priority = .init(rawValue: priority) ?? .post_imports
    }
    
}

public extension CodeBlock {
    enum Priority: Int, PySerializable, Equatable {
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
