//
//  UIImage+Extensions.swift
//  MTTransitions
//
//  Created by alexiscn on 2020/3/22.
//

#if os(iOS) || os(tvOS)
import UIKit

// Based on: https://stackoverflow.com/a/29552143
extension UIImage {
    func imageWithSize(size:CGSize) -> UIImage? {
        var scaledImageRect = CGRect.zero

        let aspectWidth:CGFloat = size.width / self.size.width
        let aspectHeight:CGFloat = size.height / self.size.height
        let aspectRatio:CGFloat = min(aspectWidth, aspectHeight)

        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0

        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        self.draw(in: scaledImageRect)

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();

        return scaledImage
    }
}
#elseif os(macOS)
import AppKit

extension NSImage {
    func imageWithSize(size: CGSize) -> NSImage? {
        var scaledImageRect = CGRect.zero

        let aspectWidth: CGFloat = size.width / self.size.width
        let aspectHeight: CGFloat = size.height / self.size.height
        let aspectRatio: CGFloat = min(aspectWidth, aspectHeight)

        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0

        let newImage = NSImage(size: size)
        newImage.lockFocus()
        self.draw(in: scaledImageRect, from: NSRect(origin: .zero, size: self.size), operation: .copy, fraction: 1.0)
        newImage.unlockFocus()

        return newImage
    }
}
#endif
