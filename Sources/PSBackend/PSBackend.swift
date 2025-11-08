
import Foundation
@preconcurrency import CPython
@preconcurrency import PySwiftKit
@preconcurrency import PySerializing
//import PyUnpack
@preconcurrency import PySwiftWrapper
//import PySwiftObject
//import PyTypes
//import PyComparable

@preconcurrency import PathKit
import XcodeGenKit
import ProjectSpec

@MainActor
public protocol PySwiftBackend: PyClassProtocol, PySerializable {
    
}

extension Path: PySerializing.PySerializable {
    
    public static func casted(from object: PyPointer) throws -> Path {
        .init(try .casted(from: object))
    }
    
    public static func casted(unsafe object: PyPointer) throws -> Path {
        .init(try .casted(unsafe: object))
    }
    
    public func pyPointer() -> PyPointer {
        string.pyPointer()
    }
}

extension Dependency: PySerializing.PySerializable {
    
    
    public static func casted(unsafe object: PyPointer) throws -> Dependency {
        let info = try [String:PyPointer].casted(from: object)
        
        if let _framework = info["framework"] {
            return .init(
                type: .framework,
                reference: try .casted(from: _framework),
                embed: true,
                codeSign: true
            )
        } else if let _package = info["package"], let _products = info["products"] {
            return .init(
                type: .package(
                    products: try .casted(from: _products)
                ),
                reference: try .casted(from: _package)
            )
        } else {
            fatalError("not a valid depedency: \(info)")
        }
    }
    
    public static func casted(from object: PyPointer) throws -> Dependency {
        try .casted(unsafe: object)
    }
    
    
    
    public func pyPointer() -> PyPointer {
        fatalError()
    }
}

extension Dependency.DependencyType: PySerializing.PySerializable {
    public static func casted(from object: PyPointer) throws -> Dependency.DependencyType {
        fatalError()
    }
    public static func casted(unsafe object: PyPointer) throws -> Dependency.DependencyType {
        fatalError()
    }
    public func pyPointer() -> PyPointer {
        fatalError()
    }
}

//extension PyCast where T == Dependency {
//    
//}
//
//extension PyCast where T == Dependency.DependencyType {
//    
//}




extension SwiftPackage: PySerializing.PyDeserialize {
    
    public static func casted(unsafe object: PyPointer) throws -> SwiftPackage {
        let dict = try [String:PyPointer].casted(from: object)
        if let path =  dict["path"] {
            return .local(path: try .casted(from: path), group: nil, excludeFromProject: false)
        } else if let url = dict["url"] {
            if let branch = dict["branch"] {
                return .remote(url: try .casted(from: url), versionRequirement: .branch(try .casted(from: branch)))
            } else if let upToMajor = dict["upToMajor"] {
                return .remote(url: try .casted(from: url), versionRequirement: .upToNextMajorVersion(try .casted(from: upToMajor)))
            } else if let upToMinor = dict["upToMinor"] {
                return .remote(url: try .casted(from: url), versionRequirement: .upToNextMinorVersion(try .casted(from: upToMinor)))
            } else {
                fatalError()
            }
        } else {
            fatalError()
        }
        
    }
    
    public static func casted(from object: PyPointer) throws -> SwiftPackage {
        try .casted(unsafe: object)
    }
    
    
}

extension [[String:PyPointer]] {
    static func casted(from object: PyPointer) throws -> Self {
        try object.compactMap { element in
            guard let element else { return nil }
            return try [String:PyPointer].casted(from: element)
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
    
    public static func casted(unsafe object: PyPointer) throws -> WrapperImporter {
        try .init(object: object)
    }
    
    public static func casted(from object: PyPointer) throws -> WrapperImporter {
        try .init(object: object)
    }
    
    public struct Library: CustomStringConvertible, PyDeserialize {
        
        public let name: String
        
        public init(object: PyPointer) throws {
            name = try .casted(from: object)
        }
        
        public var description: String {
            name
        }
        
        public static func casted(from object: PyPointer) throws -> WrapperImporter.Library {
            try .init(object: object)
        }
        
        public static func casted(unsafe object: PyPointer) throws -> WrapperImporter.Library {
            try .init(object: object)
        }
    }
    
    public enum WrapperImport: PyDeserialize, CustomStringConvertible {
        
        case static_import(String)
        case name_import(name: String, module: String)
        
        public init(object: PyPointer) throws {
            switch object {
            case &PyUnicode_Type:
                self = .static_import(try .casted(from: object))
            case &PyDict_Type:
                self = .name_import(
                    name: try PyDict_GetItem(object, key: "name"),
                    module: try PyDict_GetItem(object, key: "module")
                )
            default:
                throw PyStandardException.typeError
            }
        }
        
        public static func casted(from object: PyPointer) throws -> WrapperImporter.WrapperImport {
            try .init(object: object)
        }
        
        public static func casted(unsafe object: PyPointer) throws -> WrapperImporter.WrapperImport {
            try .init(object: object)
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

@MainActor
@PyClass(swift_mode: .v6)
@PyContainer(weak_ref: false)
public final class PSBackend: @unchecked Sendable, @preconcurrency PyClassProtocol {
    
    
    
    
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
    public func copy_to_site_packages(site_path: FilePath, platform: String) throws
    
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
    
    
    @MainActor fileprivate static var loadedBackends: [PSBackend] = []
    
    
    @PyMethod
    @MainActor
    static func loaded_backends() -> [PSBackend] {
        loadedBackends
    }
    
}

extension PSBackend: @preconcurrency PySerialize {
    public func pyPointer() -> PyPointer {
        py_target
    }
}

extension PSBackend: PyDeserialize {
   
   
}


extension PSBackend {
    
    
    
    fileprivate static func load_backend(name: String, path: Path? = nil) throws -> Self {
        guard
            let _backend = PyImport_ImportModule("pyswiftbackends.\(name)")
            
        else {
            PyErr_Print()
            fatalError()
        }
        let backend: PyPointer = try PyObject_GetAttr(_backend, key: "backend")
        return try Self.casted(from: backend)
    }
    
    fileprivate static func load_backend(external name: String, path: Path? = nil) throws -> PSBackend {
        guard
            let _backend = PyImport_ImportModule("\(name)")
            
        else {
            PyErr_Print()
            fatalError()
        }
        let backend = try PyObject_GetAttr(_backend, key: "backend")
        return try .casted(from: backend)
    }
    
    @MainActor
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



extension PSBackend {
    public enum XcodeTarget_Type: String {
        case iphoneos = "IphoneOS"
        case macos = "MacOS"
        
        public func targetPath(_ root: Path) -> Path {
            root + rawValue
        }
    }
}

@MainActor
@PyModule
public struct BackendTools: @preconcurrency PyModuleProtocol {
    public static let py_classes: [any (PyClassProtocol & AnyObject).Type] = [
        FilePath.self,
        PSBackend.self,
        CodeBlock.self
    ]
}
