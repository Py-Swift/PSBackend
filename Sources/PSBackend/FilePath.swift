//
//  FilePath.swift
//  PSBackend
//
//  Created by CodeBuilder on 09/08/2025.
//

import Foundation
@preconcurrency import CPython
@preconcurrency import PySwiftKit
@preconcurrency import PySerializing
@preconcurrency import PySwiftWrapper



import PathKit

@MainActor
@PyClass(bases: [.number, .str], swift_mode: .v6)
public final class FilePath: @preconcurrency PySerialize, @preconcurrency PyDeserialize, @preconcurrency PyClassProtocol {
    public var value: Path
    
    public init(value: Path) {
        self.value = value
    }
    
    public static func casted(from object: PyPointer) throws -> Self {
        switch object {
            case FilePath.PyType:
                return Self.unsafeUnpacked(object)
            case .PyUnicode:
                return .init(value: try .casted(from: object))
            default: fatalError()
        }
    }
    
    public static func casted(unsafe object: PyPointer) throws -> Self {
        return .init(value: try .casted(unsafe: object))
    }
    
    @MainActor public func pyPointer() -> PyPointer {
        Self.asPyPointer(self)
    }
    
    @PyMethod
    static func ps_support() -> FilePath {
        .init(value: .ps_support)
    }
    
    @PyMethod
    func copy(destination: FilePath) throws {
        try value.copy(destination.value)
    }
    
    @PyMethod
    func mkdir() throws {
        try value.mkdir()
    }
    
    @PyMethod
    func mkpath() throws {
        try value.mkpath()
    }
    
    @PyProperty var exists: Bool { value.exists }
    
    
    
    
}


extension FilePath: @preconcurrency PyNumberProtocol, @preconcurrency PyStrProtocol {
    
    static func +(l: FilePath, r: String) -> FilePath {
        .init(value: l.value + r)
    }
    
    public func __str__() -> String {
        value.string
    }
    
    public func nb_add(_ other: PyPointer) -> PyPointer? {
        if let string = try? String.casted(from: other) {
            return (self + string).pyPointer()
        }
        return nil
    }
}

//extension PyCast where T == FilePath {
//    public static func cast(from object: PyPointer) throws -> T {
//        switch object {
//        case FilePath.PyType:
//            return UnPackPyPointer(from: object)
//        case .PyUnicode:
//            return try .init(object: object)
//        default: fatalError()
//        }
//
//    }
//}

extension Path {
    static var ps_shared: Path { "/Users/Shared/psproject"}
    static var ps_support: Path { ps_shared + "support" }
    
}
