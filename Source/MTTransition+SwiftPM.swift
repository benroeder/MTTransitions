//
//  MTTransition+SwiftPM.swift
//  MTTransitions
//
//  Auto-generated file for Swift Package Manager support.
//

import Foundation
import MetalPetal

#if SWIFT_PACKAGE
import MTTransitionsSPMSupport
#endif

extension MTTransition {
    /// Library URL for MTTransitions shaders, compatible with SPM.
    /// Uses runtime-compiled source when running under SPM.
    internal static var swiftPMLibraryURL: URL? {
        #if SWIFT_PACKAGE
        // Call the ObjC function that registers and returns the library URL
        return MTTransitionsSwiftPMLibrarySourceURL()
        #else
        return MTIDefaultLibraryURLForBundle(Bundle(for: MTTransition.self))
        #endif
    }
}
