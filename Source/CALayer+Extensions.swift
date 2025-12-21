//
//  CALayer+Extensions.swift
//  MTTransitions
//
//  Created by alexiscn on 2020/3/22.
//

#if os(iOS) || os(tvOS)
import UIKit

extension CALayer {
    var snapshot: UIImage? {
        get {
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, UIScreen.main.scale)
            guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
            self.render(in: ctx)
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return result
        }
    }
}
#elseif os(macOS)
import AppKit

extension CALayer {
    var snapshot: NSImage? {
        get {
            let scale = NSScreen.main?.backingScaleFactor ?? 1.0
            let size = NSSize(width: self.bounds.size.width * scale, height: self.bounds.size.height * scale)
            guard size.width > 0 && size.height > 0 else { return nil }
            let image = NSImage(size: self.bounds.size)
            image.lockFocus()
            guard let ctx = NSGraphicsContext.current?.cgContext else {
                image.unlockFocus()
                return nil
            }
            self.render(in: ctx)
            image.unlockFocus()
            return image
        }
    }
}
#endif
