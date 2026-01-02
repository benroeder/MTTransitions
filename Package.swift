// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "MTTransitions",
    platforms: [.iOS(.v11), .macOS(.v10_13), .tvOS(.v13)],
    products: [.library(name: "MTTransitions",
                        targets: ["MTTransitions"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/MetalPetal/MetalPetal", from: "1.24.0"),
    ],
    targets: [
        // ObjC target that embeds Metal shader sources for SPM compatibility
        .target(name: "MTTransitionsSPMSupport",
                dependencies: [.product(name: "MetalPetal", package: "MetalPetal")],
                path: "Source",
                sources: ["MTTransitionsSwiftPMSupport.mm"],
                publicHeadersPath: ".",
                cSettings: [
                    .headerSearchPath("."),
                    .define("SWIFT_PACKAGE", to: "1"),
                    .unsafeFlags(["-fmodules", "-fcxx-modules"])
                ]),
        // Main Swift target
        .target(name: "MTTransitions",
                dependencies: ["MetalPetal", "MTTransitionsSPMSupport"],
                path: "Source",
                exclude: ["MTTransitionsSwiftPMSupport.mm", "MTTransitionsSwiftPMSupport.h"],
                sources: nil,  // Include all Swift files
                resources: [.process("Assets.bundle")]),
        .executableTarget(name: "macOSTest",
                          dependencies: ["MTTransitions"],
                          path: "macOSTest")
    ],
    swiftLanguageVersions: [.v5]
)
