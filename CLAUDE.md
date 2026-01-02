# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MTTransitions is a Swift/Metal library that ports GPU-accelerated visual transitions from [GL-Transitions](https://gl-transitions.com/) to Apple's Metal framework. It provides 76+ transition effects for images, UIView animations, UIViewController transitions, and video composition.

**Key Dependencies:**
- MetalPetal (>= 1.24.0) - GPU image processing framework
- MetalKit (weak linked)

## Build Commands

### Using CocoaPods (Primary)
```bash
cd MTTransitionsDemo.xcworkspace
pod install
open MTTransitionsDemo.xcworkspace
```

### Using Swift Package Manager
The library can be added as a package dependency. SPM manifest is in `Package.swift`.

### Building the Demo App
```bash
xcodebuild -workspace MTTransitionsDemo.xcworkspace -scheme MTTransitionsDemo -configuration Debug
```

## Testing

No automated test suite exists. Testing is done manually through the demo application which contains sample view controllers for each use case:
- `ImageTransitionSampleViewController` - Basic image transitions
- `VideoTransitionSampleViewController` - Video merging with transitions
- `MultipleVideoTransitionsViewController` - Multiple video clips
- `CreateVideoFromImagesViewController` - Image sequences to video

## Architecture

### Core Pattern

Each transition consists of a **Swift class** + **Metal shader** pair:

**Swift Class** (`Source/Transitions/MT*Transition.swift`):
- Extends `MTTransition` base class
- Overrides `fragmentName` to reference the Metal shader function
- Overrides `parameters` to pass configurable values to GPU
- Exposes public properties for effect customization

**Metal Shader** (`Source/Transitions/MT*Transition.metal`):
- Implements a fragment function (e.g., `BounceFragment`)
- Receives `fromTexture`, `toTexture`, `progress` (0.0-1.0), and custom parameters
- Uses helper functions from `MTTransitionLib.h`

### Key Classes

| Class | Purpose |
|-------|---------|
| `MTTransition` | Base class for all transitions; implements `MTIUnaryFilter` |
| `MTTransition.Effect` | Enum of all available effects with `.transition` factory |
| `MTViewControllerTransition` | UIViewController push/present transitions |
| `MTVideoTransition` | Merge video clips with transition effects |
| `MTMovieMaker` | Create videos from image sequences with transitions |
| `MTVideoCompositor` | Custom `AVVideoCompositing` for GPU rendering |

### Image Requirements

Images must be oriented correctly for Metal rendering:
```swift
let image = MTIImage(image: uiImage, isOpaque: true)?.oriented(.downMirrored)
```

### Rendering Context

A shared Metal context is available:
```swift
let context = MTTransition.context  // MTIContext
```

## Adding a New Transition

1. Create `Source/Transitions/MTNewTransition.swift`:
```swift
public class MTNewTransition: MTTransition {
    public var customParam: Float = 1.0

    override var fragmentName: String { return "NewFragment" }
    override var parameters: [String: Any] { return ["customParam": customParam] }
}
```

2. Create `Source/Transitions/MTNewTransition.metal`:
```metal
#include <metal_stdlib>
#include "MTIShaderLib.h"
#include "MTTransitionLib.h"

using namespace metalpetal;

fragment float4 NewFragment(VertexOut vertexIn [[ stage_in ]],
                            texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                            texture2d<float, access::sample> toTexture [[ texture(1) ]],
                            constant float & customParam [[ buffer(0) ]],
                            constant float & ratio [[ buffer(1) ]],
                            constant float & progress [[ buffer(2) ]],
                            sampler textureSampler [[ sampler(0) ]]) {
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    // Transition logic here...
    return mix(getFromColor(uv, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               progress);
}
```

3. Add case to `MTTransition.Effect` enum in `MTTransition+Effect.swift`

## Platform Requirements

- iOS 11.0+
- Swift 5.0+
- Xcode 11.0+
