#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MTTransitionLib.h"

FOUNDATION_EXPORT double MTTransitionsVersionNumber;
FOUNDATION_EXPORT const unsigned char MTTransitionsVersionString[];

