
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

extension [[String:PyPointer]] {
    static func casted(from object: PyPointer) throws -> Self {
        try object.compactMap { element in
            guard let element else { return nil }
            return try [String:PyPointer].init(object: element)
        }
    }
    
}
public struct WrapperImporter: PyDeserialize {
    
    public let libraries: [Library]
    public let modules: [WrapperImport]
    
    public init(object: PyPointer) throws {
        libraries = try PyDict_GetItem(object, key: "libraries")
        modules = try PyDict_GetItem(object, key: "modules")
    }
    
    public struct Library: CustomStringConvertible, PyDeserialize {
        
        public let name: String
        
        public init(object: PyPointer) throws {
            name = try .init(object: object)
        }
        
        public var description: String {
            name
        }
    }
    
    public enum WrapperImport: PyDeserialize, CustomStringConvertible {
        
        case static_import(String)
        case name_import(name: String, module: String)
        
        public init(object: PyPointer) throws {
            switch object {
            case &PyUnicode_Type:
                self = .static_import(try .init(object: object))
            case &PyDict_Type:
                self = .name_import(
                    name: try PyDict_GetItem(object, key: "name"),
                    module: try PyDict_GetItem(object, key: "module")
                )
            default:
                throw PyStandardException.typeError
            }
        }
        
        public var description: String {
            switch self {
            case .static_import(let string):
                string
            case .name_import(let name, let module):
                ".init(name: \(name), module: \(module).py_init )"
            }
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
    public func wrapper_imports(target_type: XcodeTarget_Type) throws -> [WrapperImporter]
  
    @PyCall
    public func will_modify_main_swift() throws -> Bool
    
    @PyCall
    public func modify_main_swift(libraries: [String], modules: [String]) throws -> [CodeBlock]
    
    @PyCall
    public func plist_entries(plist: PyPointer, target_type: XcodeTarget_Type) throws
    
    @PyCall func install(support: FilePath) async throws
    
    @PyCall
    public func copy_to_site_packages(site_path: FilePath, platform: String) async throws
    
    @PyCall
    public func will_modify_pyproject() throws -> Bool
    
    @PyCall
    public func modify_pyproject(path: FilePath) throws
    
    @PyCall
    public func exclude_dependencies() throws -> [String]
    
    public func do_install(support: FilePath) async throws {
        try await install(support: support)
        
        for fw in try await frameworks() {
            let path = fw.value
            try path.copy(support.value + path.lastComponent)
        }
    }
    
    
    fileprivate static var loadedBackends: [PSBackend] = []
    
    @PyMethod
    static func loaded_backends() -> [PSBackend] {
        loadedBackends
    }
}

extension PSBackend: PySerialize {
    public var pyPointer: PyPointer { py_target }
}


extension PSBackend {
    
    
    fileprivate static func load_backend(name: String, path: Path? = nil) throws -> PSBackend {
        guard
            let _backend = PyImport_ImportModule("pyswiftbackends.\(name)"),
            let backend = PyObject_GetAttr(_backend, "backend")
        else {
            PyErr_Print()
            fatalError()
        }
        
        return try .casted(from: backend)
    }
    
    fileprivate static func load_backend(external name: String, path: Path? = nil) throws -> PSBackend {
        guard
            let _backend = PyImport_ImportModule("\(name)"),
            let backend = PyObject_GetAttr(_backend, "backend")
        else {
            PyErr_Print()
            fatalError()
        }
        
        return try .casted(from: backend)
    }
    
    public static func load(name: String, path: Path? = nil) throws -> PSBackend {
        let backend = switch name {
        case let external where external.contains("."):
            try load_backend(external: external, path: path)
        default:
            try load_backend(name: name, path: path)
        }
        loadedBackends.append(backend)
        return backend
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
        PSBackend.self,
        CodeBlock.self
    ]
}
