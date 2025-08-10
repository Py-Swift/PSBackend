
import Foundation
import PySwiftKit
import PySerializing
import PyUnpack
import PySwiftWrapper
import PySwiftObject
import PyTypes
import PyComparable

import PathKit
import XcodeGenKit
import ProjectSpec

public protocol PySwiftBackend: PyClassProtocol, PySerializable {
    
}

extension Path: PySerializing.PySerializable {
    
    public init(object: PyPointer) throws {
        self = .init(try .init(object: object))
    }
    
    public var pyPointer: PyPointer { string.pyPointer }
}

extension Dependency: PySerializing.PySerializable {
    
    public init(object: PyPointer) throws {
        let info = try [String:PyPointer](object: object)
        if let _framework = info["framework"] {
            self = .init(
                type: .framework,
                reference: try .init(object: _framework),
                embed: true,
                codeSign: true
            )
        } else if let _package = info["package"], let _products = info["products"] {
            self = .init(
                type: .package(
                    products: try .casted(from: _products)
                ),
                reference: try .init(object: _package)
            )
        } else {
            fatalError("not a valid depedency: \(info)")
        }
    }
    
    public var pyPointer: PyPointer { fatalError() }
}

extension Dependency.DependencyType: PySerializing.PySerializable {
    public var pyPointer: PyPointer { fatalError() }
}

extension PyCast where T == Dependency {
    
}

extension PyCast where T == Dependency.DependencyType {
    
}




extension SwiftPackage: PySerializing.PyDeserialize {
    public init(object: PyPointer) throws {
        let dict = try [String:PyPointer](object: object)
        if let path =  dict["path"] {
            self = .local(path: try .init(object: path), group: nil, excludeFromProject: false)
        } else if let url = dict["url"] {
            if let branch = dict["branch"] {
                self = .remote(url: try .init(object: url), versionRequirement: .branch(try .init(object: branch)))
            } else if let upToMajor = dict["upToMajor"] {
                self = .remote(url: try .init(object: url), versionRequirement: .upToNextMajorVersion(try .init(object: upToMajor)))
            } else if let upToMinor = dict["upToMinor"] {
                self = .remote(url: try .init(object: url), versionRequirement: .upToNextMinorVersion(try .init(object: upToMinor)))
            } else {
                fatalError()
            }
        } else {
            fatalError()
        }
    }
}



@PyClass()
@PyContainer(weak_ref: false)
public final class PSBackend {
    
    
    
    
    @PyCall
    public func url() throws -> URL?
    
    @PyCall
    public func frameworks() async throws -> [FilePath]
    
    @PyCall
    public func downloads() async throws -> [URL]
    
    @PyCall
    public func config(root: FilePath) async throws
    
    @PyCall
    public func packages() throws -> [String:SwiftPackage]
    
    @PyCall
    public func target_dependencies(target_type: XcodeTarget_Type) async throws -> [Dependency]
    
    @PyCall
    public func wrapper_imports(target_type: XcodeTarget_Type) async throws -> [[String:PyPointer]]
    
    public func install(support: FilePath) async throws {
        for fw in try await frameworks() {
            let path = fw.value
            try path.copy(support.value + path.lastComponent)
        }
    }
    
}




public extension PSBackend {
    public enum XcodeTarget_Type: String {
        case iphoneos = "IphoneOS"
        case macos = "MacOS"
        
        public func targetPath(_ root: Path) -> Path {
            root + rawValue
        }
    }
}


@PyModule
public struct BackendTools: PyModuleProtocol {
    public static var py_classes: [any (PyClassProtocol & AnyObject).Type] = [
        FilePath.self,
        PSBackend.self
    ]
}
