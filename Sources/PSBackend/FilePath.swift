//
//  FilePath.swift
//  PSBackend
//
//  Created by CodeBuilder on 09/08/2025.
//

import Foundation
import PySwiftKit
import PySerializing
import PyUnpack
import PySwiftWrapper
import PySwiftObject
import PyTypes
import PyComparable

import PathKit

@PyClass(bases: [.number, .str])
public final class FilePath: PySerializable {
    public var value: Path
    
    public init(value: Path) {
        self.value = value
    }
    
    public init(object: PyPointer) throws {
        value = .init(try .init(object: object))
    }
    
    public var pyPointer: PyPointer { Self.asPyPointer(self) }
    
    
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
}



extension FilePath: PyNumberProtocol, PyStrProtocol {
    
    static func +(l: FilePath, r: String) -> FilePath {
        .init(value: l.value + r)
    }
    
    public func __str__() -> String {
        value.string
    }
    
    public func nb_add(_ other: PyPointer) -> PyPointer? {
        if let string = try? String(object: other) {
            return (self + string).pyPointer
        }
        return nil
    }
}

extension PyCast where T == FilePath {
    public static func cast(from object: PyPointer) throws -> T {
        switch object {
        case FilePath.PyType:
            return UnPackPyPointer(from: object)
        case .PyUnicode:
            return try .init(object: object)
        default: fatalError()
        }

    }
}

extension Path {
    static var ps_shared: Path { "/Users/Shared/psproject"}
    static var ps_support: Path { ps_shared + "support" }
    
}
