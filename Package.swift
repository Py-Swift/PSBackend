// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription



let package_dependencies: [Package.Dependency] = [
    //.package(url: "https://github.com/py-swift/PySwiftKit", from: .init(313, 0, 0)),
    .package(url: "https://github.com/py-swift/PySwiftKit", branch: "development"),
    .package(url: "https://github.com/py-swift/CPython", .upToNextMinor(from: .init(313, 7, 0))),
    .package(url: "https://github.com/py-swift/PyFileGenerator", from: .init(0, 0, 1)),
    // add other packages
    .package(url: "https://github.com/kylef/PathKit", .upToNextMajor(from: "1.0.1")),
    .package(url: "https://github.com/yonaskolb/XcodeGen.git", from: "2.42.0"),
    
]



let package_targets: [Target] = [
    .target(
        name: "PSBackend",
        dependencies: [
            .product(name: "PySwiftKitBase", package: "PySwiftKit"),
            "CPython",
            // add other package products or internal targets
            "PathKit",
            .product(name: "XcodeGenKit", package: "XcodeGen"),
        ],
        resources: [

        ]
    )
]



let package = Package(
    name: "PSBackend",
    platforms: [
        //.iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PSBackend",
            targets: ["PSBackend"]),
    ],
    dependencies: package_dependencies,
    targets: package_targets
)
