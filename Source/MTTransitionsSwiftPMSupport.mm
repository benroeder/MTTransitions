//
//  MTTransitionsSwiftPMSupport.mm
//  MTTransitions
//
//  Auto-generated file for Swift Package Manager support.
//  Do not edit manually - regenerate using generate_mttransitions_spm_support.py
//

#import "MTTransitionsSwiftPMSupport.h"
@import Metal;

#if __has_include(<MetalPetal/MTILibrarySource.h>)
// Framework/Xcode build
#import <MetalPetal/MTILibrarySource.h>
#else
// SPM build - use module import
@import MetalPetalObjectiveC.Core;
#endif

static const char *MTTransitionsBuiltinLibrarySource = R"mttrawstring(
//
//  MTTransitions.h
//  MTTransitions
//
//  Created by alexiscn on 2019/1/24.
//

#ifndef MTTransitions_h
#define MTTransitions_h

#if __METAL_MACOS__ || __METAL_IOS__

#define PI 3.141592653589
#define M_PI   3.14159265358979323846

#include <metal_stdlib>
#include "MTIShaderLib.h"

using namespace metal;

namespace metalpetal {
    
    enum class ResizeMode { cover, contains, stretch };
    
    METAL_FUNC float2 cover(float2 uv, float ratio, float r) {
        
        return 0.5 + (uv - 0.5) * float2(min(ratio/r, 1.0), min(r/ratio, 1.0));
    }
    
//    METAL_FUNC float2 resize(ResizeMode mode, float ratio, float2 uv, float4 texture) {
//        if (mode == ResizeMode::cover) {
//
//        } else if (mode == ResizeMode::contains) {
//
//        } else {
//            return uv;
//        }
//        return float2(1.0);
//    }
    
    METAL_FUNC float4 getFromColor(float2 uv, texture2d<float, access::sample> texture, float ratio, float _fromR) {
        constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
        float2 _uv = cover(uv, ratio, _fromR);
        return texture.sample(s, _uv);
    }
    
    METAL_FUNC float4 getToColor(float2 uv, texture2d<float, access::sample> texture, float ratio, float _toR) {
        constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
        float2 _uv = cover(uv, ratio, _toR);
        return texture.sample(s, _uv);
    }
    
    //Random function borrowed from everywhere
    METAL_FUNC float rand(float2 co){
      return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
    }
}

#endif /* MTTransitions_h */

#endif


// Author: Fernando Kuteken
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 AngularFragment(VertexOut vertexIn [[ stage_in ]],
                                texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                constant float & startingAngle [[ buffer(0) ]],
                                constant float & ratio [[ buffer(1) ]],
                                constant float & progress [[ buffer(2) ]],
                                sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float offset = startingAngle * PI / 180.0;
    float angle = atan2(uv.y - 0.5, uv.x - 0.5) + offset;
    float normalizedAngle = (angle + PI) / (2.0 * PI);
    normalizedAngle = normalizedAngle - floor(normalizedAngle);
    return mix(
               getFromColor(uv, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               step(normalizedAngle, progress));
}



// Author: hong
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float2 skewRight(float2 p, float progress) {
  float skewX = (p.x - progress)/(0.5 - progress) * 0.5;
  float skewY =  (p.y - 0.5)/(0.5 + progress * (p.x - 0.5) / 0.5)* 0.5  + 0.5;
  return float2(skewX, skewY);
}

float2 skewLeft(float2 p, float progress) {
  float skewX = (p.x - 0.5)/(progress - 0.5) * 0.5 + 0.5;
  float skewY = (p.y - 0.5) / (0.5 + (1.0 - progress ) * (0.5 - p.x) / 0.5) * 0.5  + 0.5;
  return float2(skewX, skewY);
}

float4 addShade(float progress) {
  float shadeVal  =  max(0.7, abs(progress - 0.5) * 2.0);
  return float4(float3(shadeVal ), 1.0);
}


fragment float4 BookFlipFragment(VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                 texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                 constant float & ratio [[ buffer(0) ]],
                                 constant float & progress [[ buffer(1) ]],
                                 sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float pr = step(1.0 - progress, uv.x);

    if (uv.x < 0.5) {
        return mix(getFromColor(uv, fromTexture, ratio, _fromR),
                   getToColor(skewLeft(uv, progress), toTexture, ratio, _toR) * addShade(progress),
                   pr);
    } else {
        return mix(getFromColor(skewRight(uv, progress), fromTexture, ratio, _fromR) * addShade(progress),
                   getToColor(uv, toTexture, ratio, _toR),
                   pr);
    }
}


// Author: Adrian Purser
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 BounceFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & bounces [[ buffer(0) ]],
                               constant float4 & shadowColour [[ buffer(1) ]],
                               constant float & shadowHeight [[ buffer(2) ]],
                               constant float & ratio [[ buffer(3) ]],
                               constant float & progress [[ buffer(4) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float time = progress;
    float stime = sin(time * PI/2.0);
    float phase = time * PI * bounces;
    float y = abs(cos(phase)) * (1 - stime);
    float d = uv.y - y;
    float4 shadow = ((d/shadowHeight) * shadowColour.a) + (1.0 - shadowColour.a);
    float4 smooth = step(d, shadowHeight) * (1.0 - mix(shadow, 1.0, smoothstep(0.95, 1.0, progress)));
    return mix(mix(getToColor(uv, toTexture, ratio, _toR), shadowColour, smooth),
               getFromColor(float2(uv.x, uv.y + (1.0 - y)), fromTexture, ratio, _fromR),
               step(d, 0.0)
    );
}


// Author: huynx
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float horizontal_check(float2 p1, float2 p2, float2 p3) {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

bool PointInTriangle (float2 pt, float2 p1, float2 p2, float2 p3) {
    bool b1, b2, b3;
    b1 = horizontal_check(pt, p1, p2) < 0.0;
    b2 = horizontal_check(pt, p2, p3) < 0.0;
    b3 = horizontal_check(pt, p3, p1) < 0.0;
    return ((b1 == b2) && (b2 == b3));
}

bool in_left_triangle(float2 p, float progress){
    float2 vertex1, vertex2, vertex3;
    vertex1 = float2(progress, 0.5);
    vertex2 = float2(0.0, 0.5-progress);
    vertex3 = float2(0.0, 0.5+progress);
    if (PointInTriangle(p, vertex1, vertex2, vertex3)) {
        return true;
    }
    return false;
}

bool in_right_triangle(float2 p, float progress){
    float2 vertex1, vertex2, vertex3;
    vertex1 = float2(1.0-progress, 0.5);
    vertex2 = float2(1.0, 0.5-progress);
    vertex3 = float2(1.0, 0.5+progress);
    if (PointInTriangle(p, vertex1, vertex2, vertex3)) {
        return true;
    }
    return false;
}

float horizontal_blur_edge(float2 bot1, float2 bot2, float2 top, float2 testPt) {
    float2 lineDir = bot1 - top;
    float2 perpDir = float2(lineDir.y, -lineDir.x);
    float2 dirToPt1 = bot1 - testPt;
    float dist1 = abs(dot(normalize(perpDir), dirToPt1));

    lineDir = bot2 - top;
    perpDir = float2(lineDir.y, -lineDir.x);
    dirToPt1 = bot2 - testPt;
    float min_dist = min(abs(dot(normalize(perpDir), dirToPt1)), dist1);

    if (min_dist < 0.005) {
        return min_dist / 0.005;
    } else {
        return 1.0;
    }
}

fragment float4 BowTieHorizontalFragment(VertexOut vertexIn [[ stage_in ]],
                                         texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                         texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                         constant float & ratio [[ buffer(0) ]],
                                         constant float & progress [[ buffer(1) ]],
                                         sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    if (in_left_triangle(uv, progress)) {
        if (progress < 0.1) {
            return getFromColor(uv, fromTexture, ratio, _fromR);
        }
        if (uv.x < 0.5) {
            float2 vertex1 = float2(progress, 0.5);
            float2 vertex2 = float2(0.0, 0.5-progress);
            float2 vertex3 = float2(0.0, 0.5+progress);
            return mix(
                       getFromColor(uv, fromTexture, ratio, _fromR),
                       getToColor(uv, toTexture, ratio, _toR),
                       horizontal_blur_edge(vertex2, vertex3, vertex1, uv)
                       );
        } else {
            if (progress > 0.0) {
                return getToColor(uv, toTexture, ratio, _toR);
            } else {
                return getFromColor(uv, fromTexture, ratio, _fromR);
            }
        }
    } else if (in_right_triangle(uv, progress)) {
        if (uv.x >= 0.5) {
            float2 vertex1 = float2(1.0-progress, 0.5);
            float2 vertex2 = float2(1.0, 0.5-progress);
            float2 vertex3 = float2(1.0, 0.5+progress);
            return mix(
                       getFromColor(uv, fromTexture, ratio, _fromR),
                       getToColor(uv, toTexture, ratio, _toR),
                       horizontal_blur_edge(vertex2, vertex3, vertex1, uv)
                       );
        } else {
            return getFromColor(uv, fromTexture, ratio, _fromR);
        }
    } else {
        return getFromColor(uv, fromTexture, ratio, _fromR);
    }
}


// Author: huynx
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float vertical_check(float2 p1, float2 p2, float2 p3) {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

bool vertical_pointInTriangle (float2 pt, float2 p1, float2 p2, float2 p3) {
    bool b1, b2, b3;
    b1 = vertical_check(pt, p1, p2) < 0.0;
    b2 = vertical_check(pt, p2, p3) < 0.0;
    b3 = vertical_check(pt, p3, p1) < 0.0;
    return ((b1 == b2) && (b2 == b3));
}

bool in_top_triangle(float2 p, float progress) {
    float2 vertex1, vertex2, vertex3;
    vertex1 = float2(0.5, progress);
    vertex2 = float2(0.5 - progress, 0.0);
    vertex3 = float2(0.5 + progress, 0.0);
    if (vertical_pointInTriangle(p, vertex1, vertex2, vertex3))
    {
        return true;
    }
    return false;
}

bool in_bottom_triangle(float2 p, float progress) {
    float2 vertex1, vertex2, vertex3;
    vertex1 = float2(0.5, 1.0 - progress);
    vertex2 = float2(0.5-progress, 1.0);
    vertex3 = float2(0.5+progress, 1.0);
    if (vertical_pointInTriangle(p, vertex1, vertex2, vertex3))
    {
        return true;
    }
    return false;
}

float vertical_blur_edge(float2 bot1, float2 bot2, float2 top, float2 testPt) {
    float2 lineDir = bot1 - top;
    float2 perpDir = float2(lineDir.y, -lineDir.x);
    float2 dirToPt1 = bot1 - testPt;
    float dist1 = abs(dot(normalize(perpDir), dirToPt1));
    
    lineDir = bot2 - top;
    perpDir = float2(lineDir.y, -lineDir.x);
    dirToPt1 = bot2 - testPt;
    float min_dist = min(abs(dot(normalize(perpDir), dirToPt1)), dist1);
    
    if (min_dist < 0.005) {
        return min_dist / 0.005;
    } else {
        return 1.0;
    }
}

fragment float4 BowTieVerticalFragment(VertexOut vertexIn [[ stage_in ]],
                                       texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                       texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                       constant float & ratio [[ buffer(0) ]],
                                       constant float & progress [[ buffer(1) ]],
                                       sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    if (in_top_triangle(uv, progress)) {
        if (progress < 0.1) {
            return getFromColor(uv, fromTexture, ratio, _fromR);
        }
        if (uv.y < 0.5) {
            float2 vertex1 = float2(0.5, progress);
            float2 vertex2 = float2(0.5-progress, 0.0);
            float2 vertex3 = float2(0.5+progress, 0.0);
            return mix(
                       getFromColor(uv, fromTexture, ratio, _fromR),
                       getFromColor(uv, toTexture, ratio, _toR),
                       vertical_blur_edge(vertex2, vertex3, vertex1, uv)
                       );
        } else {
            if (progress > 0.0) {
                return getToColor(uv, toTexture, ratio, _toR);
            } else {
                return getFromColor(uv, fromTexture, ratio, _fromR);
            }
        }
    } else if (in_bottom_triangle(uv, progress)) {
        if (uv.y >= 0.5) {
            float2 vertex1 = float2(0.5, 1.0-progress);
            float2 vertex2 = float2(0.5-progress, 1.0);
            float2 vertex3 = float2(0.5+progress, 1.0);
            return mix(
                       getFromColor(uv, fromTexture, ratio, _fromR),
                       getToColor(uv, toTexture, ratio, _toR),
                       vertical_blur_edge(vertex2, vertex3, vertex1, uv)
                       );
        } else {
            return getFromColor(uv, fromTexture, ratio, _fromR);
        }
    }
    else {
        return getFromColor(uv, fromTexture, ratio, _fromR);
    }
}


// License: MIT
// Author: gre

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 BurnFragment(VertexOut vertexIn [[ stage_in ]],
                             texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                             texture2d<float, access::sample> toTexture [[ texture(1) ]],
                             constant float3 & color [[ buffer(0) ]],
                             constant float & ratio [[ buffer(1) ]],
                             constant float & progress [[ buffer(2) ]],
                             sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    return mix(getFromColor(uv, fromTexture, ratio, _fromR) + float4(progress*color, 1.0),
               getToColor(uv, toTexture, ratio, _toR) + float4((1.0-progress)*color, 1.0),
               progress
               );
}



// Author: mandubian
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float compute(float2 p, float progress, float2 center, float amplitude, float waves) {
    float2 o = p * sin(progress * amplitude) - center;
    // horizontal vector
    float2 h = float2(1.0, 0.0);
    // butterfly polar function (don't ask me why this one :))
    float theta = acos(dot(o, h)) * waves;
    return (exp(cos(theta)) - 2.0 * cos(4.0 * theta) + pow(sin((2.0 * theta - PI) / 24.), 5.0)) / 10.0;
}

fragment float4 ButterflyWaveScrawlerFragment(VertexOut vertexIn [[ stage_in ]],
                                              texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                              texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                              constant float & colorSeparation [[ buffer(0) ]],
                                              constant float & amplitude [[ buffer(1) ]],
                                              constant float & waves [[ buffer(2) ]],
                                              constant float & ratio [[ buffer(3) ]],
                                              constant float & progress [[ buffer(4) ]],
                                              sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 p = uv.xy / float2(1.0).xy;
    float inv = 1.0 - progress;
//    float2 dir = p - float2(.5);
//    float dist = length(dir);
    float disp = compute(p, progress, float2(0.5, 0.5), amplitude, waves);
    float4 texTo = getToColor(p + inv*disp, toTexture, ratio, _toR);
    float4 texFrom = float4(
                            getFromColor(p + progress*disp*(1.0 - colorSeparation), fromTexture, ratio, _fromR).r,
                            getFromColor(p + progress*disp, fromTexture, ratio, _fromR).g,
                            getFromColor(p + progress*disp*(1.0 + colorSeparation), fromTexture, ratio, _fromR).b,
                            1.0);
    return texTo * progress + texFrom * inv;
}


// Author: @Flexi23
// License: MIT
// inspired by http://www.wolframalpha.com/input/?i=cannabis+curve

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 CannabisleafFragment(VertexOut vertexIn [[ stage_in ]],
                                     texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                     texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                     constant float & ratio [[ buffer(0) ]],
                                     constant float & progress [[ buffer(1) ]],
                                     sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    if(progress == 0.0){
        return getFromColor(uv, fromTexture, ratio, _fromR);
    }
    float2 leaf_uv = (uv - float2(0.5))/10./pow(progress,3.5);
    leaf_uv.y += 0.35;
    float r = 0.18;
    float o = atan2(leaf_uv.y, leaf_uv.x);
    
    float4 a = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 b = getToColor(uv, toTexture, ratio, _toR);
    float4 c = 1.0 - step(1.0 - length(leaf_uv) + r*(1.0 + sin(o))*(1.0 + 0.9 * cos(8.0*o))*(1.0 + 0.1*cos(24.0*o))*(0.9+0.05*cos(200.0*o)), 1.0);
    return mix(a, b, c);
}



// License: MIT
// Author: fkuteken
// ported by gre from https://gist.github.com/fkuteken/f63e3009c1143950dee9063c3b83fb88

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 CircleCropFragment(VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                   constant float & bgcolor [[ buffer(0) ]],
                                   constant float & ratio [[ buffer(1) ]],
                                   constant float & progress [[ buffer(2) ]],
                                   sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
 
    float2 ratio2 = float2(1.0, 1.0 / ratio);
    float s = pow(2.0 * abs(progress - 0.5), 3.0);
    float dist = length((float2(uv) - 0.5) * ratio2);
    
    float4 from = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 to = getToColor(uv, toTexture, ratio, _toR);
    
    return mix(
               progress < 0.5 ?  from: to, // branching is ok here as we statically depend on progress uniform (branching won't change over pixels)
               bgcolor,
               step(s, dist)
    );
}


// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 CircleOpenFragment(VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                   constant float & smoothness [[ buffer(0) ]],
                                   constant bool & opening [[ buffer(1) ]],
                                   constant float & ratio [[ buffer(2) ]],
                                   constant float & progress [[ buffer(3) ]],
                                   sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    const float2 center = float2(0.5, 0.5);
    const float SQRT_2 = 1.414213562373;
    
    float x = opening ? progress : 1.-progress;
    float m = smoothstep(-smoothness, 0.0, SQRT_2*distance(center, uv) - x*(1.+smoothness));
    return mix(getFromColor(uv, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               opening ? 1.-m : m
               );
}



// Author: Fernando Kuteken
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 CircleFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float2 & center [[ buffer(0) ]],
                               constant float3 & backColor [[ buffer(1) ]],
                               constant float & ratio [[ buffer(2) ]],
                               constant float & progress [[ buffer(3) ]],
                               sampler textureSampler [[ sampler(0) ]]) 
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float distance = length(uv - center);
    float radius = sqrt(8.0) * abs(progress - 0.5);
    if (distance > radius) {
        return float4(backColor, 1.0);
    } else {
        if (progress < 0.5) {
            return getFromColor(uv, fromTexture, ratio, _fromR);
        } else {
            return getToColor(uv, toTexture, ratio, _toR);
        }
    }
}



// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 ColorPhaseFragment(VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                   constant float4 & fromStep [[ buffer(0) ]],
                                   constant float4 & toStep [[ buffer(1) ]],
                                   constant float & ratio [[ buffer(2) ]],
                                   constant float & progress [[ buffer(3) ]],
                                   sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float4 a = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 b = getFromColor(uv, toTexture, ratio, _toR);
    return mix(a, b, smoothstep(fromStep, toStep, float4(progress)));
}



// License: MIT
// Author: P-Seebauer
// ported by gre from https://gist.github.com/P-Seebauer/2a5fa2f77c883dd661f9

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 ColourDistanceFragment(VertexOut vertexIn [[ stage_in ]],
                                       texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                       texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                       constant float & power [[ buffer(0) ]],
                                       constant float & ratio [[ buffer(1) ]],
                                       constant float & progress [[ buffer(2) ]],
                                       sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float4 fTex = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 tTex = getToColor(uv, toTexture, ratio, _toR);
    float m = step(distance(fTex, tTex), progress);
    return mix(mix(fTex, tTex, m),
               tTex,
               pow(progress, power)
               );
}


// Author: haiyoucuv
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 CoordFromInFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & ratio [[ buffer(0) ]],
                               constant float & progress [[ buffer(1) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    float4 coordTo = getToColor(uv, toTexture, ratio, _toR);
    //float4 coordFrom = getFromColor(uv, fromTexture, ratio, _fromR);
    
    float4 a = getFromColor(coordTo.rg, fromTexture, ratio, _fromR);
    float4 b = getToColor(uv, toTexture, ratio, _toR);
    
    return mix(a, b, progress);
}


// Author: mandubian
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 CrazyParametricFunFragment(VertexOut vertexIn [[ stage_in ]],
                                           texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                           texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                           constant float & a [[ buffer(0) ]],
                                           constant float & b [[ buffer(1) ]],
                                           constant float & smoothness [[ buffer(2) ]],
                                           constant float & amplitude [[ buffer(3) ]],
                                           constant float & ratio [[ buffer(4) ]],
                                           constant float & progress [[ buffer(5) ]],
                                           sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 p = uv.xy / float2(1.0).xy;
    float2 dir = p - float2(.5);
    float dist = length(dir);
    float x = (a - b) * cos(progress) + b * cos(progress * ((a / b) - 1.0));
    float y = (a - b) * sin(progress) - b * sin(progress * ((a / b) - 1.0));
    float2 offset = dir * float2(sin(progress  * dist * amplitude * x), sin(progress * dist * amplitude * y)) / smoothness;
    return mix(getFromColor(p + offset, fromTexture, ratio, _fromR),
               getToColor(p, toTexture, ratio, _toR),
               smoothstep(0.2, 1.0, progress)
               );
}


// License: MIT
// Author: pthrasher
// adapted by gre from https://gist.github.com/pthrasher/04fd9a7de4012cbb03f6

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 CrossHatchFragment(VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                   constant float & threshold [[ buffer(0) ]],
                                   constant float2 & center [[ buffer(1) ]],
                                   constant float & fadeEdge [[ buffer(2) ]],
                                   constant float & ratio [[ buffer(3) ]],
                                   constant float & progress [[ buffer(4) ]],
                                   sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float dist = distance(center, uv) / threshold;
    float r = progress - min(rand(float2(uv.y, 0.0)), rand(float2(0.0, uv.x)));
    return mix(getFromColor(uv, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               mix(0.0,
                   mix(step(dist, r),1.0, smoothstep(1.0-fadeEdge, 1.0, progress)),
                   smoothstep(0.0, fadeEdge, progress))
               );
}


// Author: Eke Péter <peterekepeter@gmail.com>
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 CrossWarpFragment(VertexOut vertexIn [[ stage_in ]],
                                  texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                  texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                  constant float & ratio [[ buffer(0) ]],
                                  constant float & progress [[ buffer(1) ]],
                                  sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float x = progress;
    x = smoothstep(.0,1.0,(x * 2.0 + uv.x - 1.0));
    return mix(getFromColor((uv - 0.5) * (1.0 - x) + 0.5, fromTexture, ratio, _fromR),
               getToColor((uv - 0.5) * x + 0.5, toTexture, ratio, _toR),
               x);
}


// License: MIT
// Author: rectalogic
// ported by gre from https://gist.github.com/rectalogic/b86b90161503a0023231

// Converted from https://github.com/rectalogic/rendermix-basic-effects/blob/master/assets/com/rendermix/CrossZoom/CrossZoom.frag
// Which is based on https://github.com/evanw/glfx.js/blob/master/src/filters/blur/zoomblur.js
// With additional easing functions from https://github.com/rectalogic/rendermix-basic-effects/blob/master/assets/com/rendermix/Easing/Easing.glsllib

#include <metal_stdlib>

using namespace metalpetal;

float Linear_ease(float begin, float change, float duration, float time) {
    return change * time / duration + begin;
}

float Exponential_easeInOut(float begin, float change, float duration, float time) {
    if (time == 0.0)
        return begin;
    else if (time == duration)
        return begin + change;
    time = time / (duration / 2.0);
    if (time < 1.0)
        return change / 2.0 * pow(2.0, 10.0 * (time - 1.0)) + begin;
    return change / 2.0 * (-pow(2.0, -10.0 * (time - 1.0)) + 2.0) + begin;
}

float Sinusoidal_easeInOut(float begin, float change, float duration, float time) {
    return -change / 2.0 * (cos(PI * time / duration) - 1.0) + begin;
}


float3 crossFade(float2 uv, float dissolve, float ratio, texture2d<float, access::sample> fromTexture, float _fromR,
                 texture2d<float, access::sample> toTexture, float _toR) {
    return mix(getFromColor(uv, fromTexture, ratio, _fromR).rgb,
               getFromColor(uv, toTexture, ratio, _toR).rgb,
               dissolve);
}

fragment float4 CrossZoomFragment(VertexOut vertexIn [[ stage_in ]],
                                  texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                  texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                  constant float & strength [[ buffer(0) ]],
                                  constant float & ratio [[ buffer(1) ]],
                                  constant float & progress [[ buffer(2) ]],
                                  sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 texCoord = uv.xy / float2(1.0).xy;
    
    // Linear interpolate center across center half of the image
    float2 center = float2(Linear_ease(0.25, 0.5, 1.0, progress), 0.5);
    float dissolve = Exponential_easeInOut(0.0, 1.0, 1.0, progress);
    
    // Mirrored sinusoidal loop. 0->strength then strength->0
    float st = Sinusoidal_easeInOut(0.0, strength, 0.5, progress);
    
    float3 color = float3(0.0);
    float total = 0.0;
    float2 toCenter = center - texCoord;
    
    /* randomize the lookup values to hide the fixed number of samples */
    float offset = rand(uv);
    
    for (float t = 0.0; t <= 40.0; t++) {
        float percent = (t + offset) / 40.0;
        float weight = 4.0 * (percent - percent * percent);
        color += crossFade(texCoord + toCenter * percent * st, dissolve, ratio, fromTexture, _fromR, toTexture, _toR) * weight;
        total += weight;
    }
    return float4(color / total, 1.0);
}


// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float2 cube_project (float2 p, float floating) {
    return p * float2(1.0, -1.2) + float2(0.0, -floating/100.);
}

bool cube_inBounds (float2 p) {
    return all(float2(0.0) < p) && all(p < float2(1.0));
}

// p : the position
// persp : the perspective in [ 0, 1 ]
// center : the xcenter in [0, 1] \ 0.5 excluded
float2 cube_xskew (float2 p, float persp, float center) {
    float x = mix(p.x, 1.0-p.x, center);
    return (
            (float2( x, (p.y - 0.5*(1.0-persp) * x) / (1.0+(persp-1.0)*x) ) - float2(0.5-abs(center - 0.5), 0.0))
            * float2(0.5 / abs(center - 0.5) * (center<0.5 ? 1.0 : -1.0), 1.0)
            + float2(center<0.5 ? 0.0 : 1.0, 0.0)
            );
}

fragment float4 CubeFragment(VertexOut vertexIn [[ stage_in ]],
                             texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                             texture2d<float, access::sample> toTexture [[ texture(1) ]],
                             constant float & persp [[ buffer(0) ]],
                             constant float & unzoom [[ buffer(1) ]],
                             constant float & reflection [[ buffer(2) ]],
                             constant float & floating [[ buffer(3) ]],
                             constant float & ratio [[ buffer(4) ]],
                             constant float & progress [[ buffer(5) ]],
                             sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float uz = unzoom * 2.0*(0.5 - abs(0.5 - progress));
    float2 p = -uz*0.5+(1.0+uz) * uv;
    float2 fromP = cube_xskew((p - float2(progress, 0.0)) / float2(1.0 - progress, 1.0),
                         1.0 - mix(progress, 0.0, persp),
                         0.0);
    float2 toP = cube_xskew(p/float2(progress, 1.0),
                       mix(pow(progress, 2.0), 1.0, persp),
                       1.0);
    // FIXME avoid branching might help perf!
    if (cube_inBounds(fromP)) {
        return getFromColor(fromP, fromTexture, ratio, _fromR);
    } else if (cube_inBounds(toP)) {
        return getToColor(toP, toTexture, ratio, _toR);
    }
    
    float4 c = float4(0.0, 0.0, 0.0, 1.0);
    fromP = cube_project(fromP, floating);
    // FIXME avoid branching might help perf!
    if (cube_inBounds(fromP)) {
        c += mix(float4(0.0), getFromColor(fromP, fromTexture, ratio, _fromR), reflection * mix(1.0, 0.0, fromP.y));
    }
    toP = cube_project(toP, floating);
    if (cube_inBounds(toP)) {
        c += mix(float4(0.0), getToColor(toP, toTexture, ratio, _toR), reflection * mix(1.0, 0.0, toP.y));
    }
    return c;
}


// Author: Max Plotnikov
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 DirectionalEasingFragment(VertexOut vertexIn [[ stage_in ]],
                                          texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                          texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                          constant float2 & direction [[ buffer(0) ]],
                                          constant float & ratio [[ buffer(1) ]],
                                          constant float & progress [[ buffer(2) ]],
                                          sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float easing = sqrt((2.0 - progress) * progress);
    float2 p = uv + easing * sign(direction);
    float2 f = fract(p);
    return mix(
        getToColor(f, toTexture, ratio, _toR),
        getFromColor(f, fromTexture, ratio, _fromR),
        step(0.0, p.y) * step(p.y, 1.0) * step(0.0, p.x) * step(p.x, 1.0)
      );
}


// Author: Gaëtan Renaudeau
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 DirectionalFragment(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                    texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                    constant float2 & direction [[ buffer(0) ]],
                                    constant float & ratio [[ buffer(1) ]],
                                    constant float & progress [[ buffer(2) ]],
                                    sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 p = uv + progress * sign(direction);
    float2 f = fract(p);
    return mix(getToColor(f, toTexture, ratio, _toR),
               getFromColor(f, fromTexture, ratio, _fromR),
               step(0.0, p.y) * step(p.y, 1.0) * step(0.0, p.x) * step(p.x, 1.0));
}



// Author: pschroen
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 DirectionalWarpFragment(VertexOut vertexIn [[ stage_in ]],
                                        texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                        texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                        constant float2 & direction [[ buffer(0) ]],
                                        constant float & ratio [[ buffer(1) ]],
                                        constant float & progress [[ buffer(2) ]],
                                        sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    const float smoothness = 0.5;
    const float2 center = float2(0.5, 0.5);
    
    float2 v = normalize(direction);
    v /= abs(v.x) + abs(v.y);
    float d = v.x * center.x + v.y * center.y;
    float m = 1.0 - smoothstep(-smoothness, 0.0, v.x * uv.x + v.y * uv.y - (d - 0.5 + progress * (1.0 + smoothness)));
    return mix(getFromColor((uv - 0.5) * (1.0 - m) + 0.5, fromTexture, ratio, _fromR),
               getToColor((uv - 0.5) * m + 0.5, toTexture, ratio, _toR),
               m);
}



// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 DirectionalWipeFragment(VertexOut vertexIn [[ stage_in ]],
                                        texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                        texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                        constant float2 & direction [[ buffer(0) ]],
                                        constant float & smoothness [[ buffer(1) ]],
                                        constant float & ratio [[ buffer(2) ]],
                                        constant float & progress [[ buffer(3) ]],
                                        sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    const float2 center = float2(0.5, 0.5);
    
    float2 v = normalize(direction);
    v /= abs(v.x)+abs(v.y);
    float d = v.x * center.x + v.y * center.y;
    float m =
    (1.0-step(progress, 0.0)) * // there is something wrong with our formula that makes m not equals 0.0 with progress is 0.0
    (1.0 - smoothstep(-smoothness, 0.0, v.x * uv.x + v.y * uv.y - (d-0.5+progress*(1.+smoothness))));
    
    return mix(getFromColor(uv, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               m);
}



// Author: Travis Fischer
// License: MIT
//
// Adapted from a Codrops article by Robin Delaporte
// https://tympanus.net/Development/DistortionHoverEffect

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 DisplacementFragment(VertexOut vertexIn [[ stage_in ]],
                                     texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                     texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                     texture2d<float, access::sample> displacementMap [[ texture(2)]],
                                     constant float & strength [[ buffer(0) ]],
                                     constant float & ratio [[ buffer(1) ]],
                                     constant float & progress [[ buffer(2) ]],
                                     sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    
    float displacement = displacementMap.sample(s, uv).r * strength;
    float2 uvFrom = float2(uv.x + progress * displacement, uv.y);
    float2 uvTo = float2(uv.x - (1.0 - progress) * displacement, uv.y);
    
    return mix(getFromColor(uvFrom, fromTexture, ratio, _fromR),
               getToColor(uvTo, toTexture, ratio, _toR),
               progress
               );
}



// Author: hjm1fb
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;


float2 hash(float2 p)  // replace this by something better
{
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(float2 p) {
    const float K1 = 0.366025404;  // (sqrt(3)-1)/2;
    const float K2 = 0.211324865;  // (3-sqrt(3))/6;
    
    float2 i = floor(p + (p.x + p.y) * K1);
    float2 a = p - i + (i.x + i.y) * K2;
    float m = step(a.y, a.x);
    float2 o = float2(m, 1.0 - m);
    float2 b = a - o + K2;
    float2 c = a - 1.0 + 2.0 * K2;
    float3 h = max(0.5 - float3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    float3 n = h * h * h * h * float3(dot(a, hash(i + 0.0)), dot(b, hash(i + o)), dot(c, hash(i + 1.0)));
    return dot(n, float3(70.0));
}

fragment float4 DissolveFragment(VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                 texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                 constant float & uLineWidth [[ buffer(0) ]],
                                 constant float3 & uSpreadClr [[ buffer(1) ]],
                                 constant float3 & uHotClr [[ buffer(2) ]],
                                 constant float & uPow [[ buffer(3) ]],
                                 constant float & uIntensity [[ buffer(4) ]],
                                 constant float & ratio [[ buffer(5) ]],
                                 constant float & progress [[ buffer(6) ]],
                                 sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float4 from = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 to = getToColor(uv, toTexture, ratio, _toR);
    float4 outColor;
    float burn;
    burn = 0.5 + 0.5 * (0.299 * from.r + 0.587 * from.g + 0.114 * from.b);
    
    float show = burn - progress;
    if (show < 0.001) {
        outColor = to;
    } else {
        float factor = 1.0 - smoothstep(0.0, uLineWidth, show);
        float3 burnColor = mix(uSpreadClr, uHotClr, factor);
        burnColor = pow(burnColor, float3(uPow)) * uIntensity;
        float3 finalRGB = mix(from.rgb, burnColor, factor * step(0.0001, progress));
        outColor = float4(finalRGB * from.a, from.a);
    }
    return outColor;
}


// Author: Zeh Fernando
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float doomscreen_rand(int num) {
    return fract(mod(float(num) * 67123.313, 12.0) * sin(float(num) * 10.3) * cos(float(num)));
}

float doomscreen_wave(int num, int bars, float frequency) {
    float fn = float(num) * frequency * 0.1 * float(bars);
    return cos(fn * 0.5) * cos(fn * 0.13) * sin((fn+10.0) * 0.3) / 2.0 + 0.5;
}

float doomscreen_drip(int num, int bars, float dripScale) {
    return sin(float(num) / float(bars - 1) * 3.141592) * dripScale;
}

float doomscreen_pos(int num, int bars, float frequency, float dripScale, float noise) {
    return (noise == 0.0 ? doomscreen_wave(num, bars, frequency) : mix(doomscreen_wave(num, bars, frequency), doomscreen_rand(num), noise)) + (dripScale == 0.0 ? 0.0 : doomscreen_drip(num, bars, dripScale));
}

fragment float4 DoomScreenFragment(VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                   constant float & dripScale [[ buffer(0) ]],
                                   constant int & bars [[ buffer(1) ]],
                                   constant float & noise [[ buffer(2) ]],
                                   constant float & frequency [[ buffer(3) ]],
                                   constant float & amplitude [[ buffer(4) ]],
                                   constant float & ratio [[ buffer(5) ]],
                                   constant float & progress [[ buffer(6) ]],
                                   sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    int bar = int(uv.x * (float(bars)));
    float scale = 1.0 + doomscreen_pos(bar, bars, frequency, dripScale, noise) * amplitude;
    float phase = progress * scale;
    float posY = uv.y / float2(1.0).y;
    float2 p;
    float4 c;
    if (phase + posY < 1.0) {
        p = float2(uv.x, uv.y + mix(0.0, float2(1.0).y, phase)) / float2(1.0).xy;
        c = getFromColor(p, fromTexture, ratio, _fromR);
    } else {
        p = uv.xy / float2(1.0).xy;
        c = getToColor(p, toTexture, ratio, _toR);
    }
    
    // Finally, apply the color
    return c;
}


// License: MIT 
// Author: gre

#include <metal_stdlib>

using namespace metalpetal;

bool doorway_inBounds (float2 p) {
    const float2 boundMin = float2(0.0, 0.0);
    const float2 boundMax = float2(1.0, 1.0);
    return all(boundMin < p) && all(p < boundMax);
}

float2 doorway_project (float2 p) {
    return p * float2(1.0, -1.2) + float2(0.0, -0.02);
}

float4 doorway_bgColor(float2 p, float2 pto, float reflection, texture2d<float, access::sample> toTexture, float ratio, float _toR) {
    const float4 black = float4(0.0, 0.0, 0.0, 1.0);
    float4 c = black;
    pto = doorway_project(pto);
    if (doorway_inBounds(pto)) {
        c += mix(black, getToColor(pto, toTexture, ratio, _toR), reflection * mix(1.0, 0.0, pto.y));
    }
    return c;
}

fragment float4 DoorwayFragment(VertexOut vertexIn [[ stage_in ]],
                                texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                constant float & depth [[ buffer(0) ]],
                                constant float & reflection [[ buffer(1) ]],
                                constant float & perspective [[ buffer(2) ]],
                                constant float & ratio [[ buffer(3) ]],
                                constant float & progress [[ buffer(4) ]],
                                sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 pfr = float2(-1.), pto = float2(-1.);
    float middleSlit = 2.0 * abs(uv.x-0.5) - progress;
    if (middleSlit > 0.0) {
        pfr = uv + (uv.x > 0.5 ? -1.0 : 1.0) * float2(0.5 * progress, 0.0);
        float d = 1.0/(1.0 + perspective * progress*(1.0 - middleSlit));
        pfr.y -= d/2.0;
        pfr.y *= d;
        pfr.y += d/2.0;
    }
    float size = mix(1.0, depth, 1.0 - progress);
    pto = (uv + float2(-0.5, -0.5)) * float2(size, size) + float2(0.5, 0.5);
    if (doorway_inBounds(pfr)) {
        return getFromColor(pfr, fromTexture, ratio, _fromR);
    } else if (doorway_inBounds(pto)) {
        return getToColor(pto, toTexture, ratio, _toR);
    } else {
        return doorway_bgColor(uv, pto, reflection, toTexture, ratio, _toR);
    }
}



// Author: mikolalysenko
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float2 offset(float progress, float x, float theta) {
    //float phase = progress * progress + progress + theta;
    float shifty = 0.03 * progress * cos(10.0*(progress + x));
    return float2(0, shifty);
}

fragment float4 DreamyFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & ratio [[ buffer(0) ]],
                               constant float & progress [[ buffer(1) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    return mix(getFromColor(uv + offset(progress, uv.x, 0.0), fromTexture, ratio, _fromR),
               getToColor(uv + offset(1.0-progress, uv.x, 3.14), toTexture, ratio, _toR),
               progress);
}


// Author: Zeh Fernando
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

// Definitions --------
#define DEG2RAD 0.03926990816987241548078304229099 // 1/180*PI


fragment float4 DreamyZoomFragment(VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                   constant float & rotation [[ buffer(0) ]],
                                   constant float & scale [[ buffer(1) ]],
                                   constant float & ratio [[ buffer(2) ]],
                                   constant float & progress [[ buffer(3) ]],
                                   sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    // Massage parameters
    float phase = progress < 0.5 ? progress * 2.0 : (progress - 0.5) * 2.0;
    float angleOffset = progress < 0.5 ? mix(0.0, rotation * DEG2RAD, phase) : mix(-rotation * DEG2RAD, 0.0, phase);
    float newScale = progress < 0.5 ? mix(1.0, scale, phase) : mix(scale, 1.0, phase);
    
    float2 center = float2(0, 0);
    
    // Calculate the source point
    //float2 assumedCenter = float2(0.5, 0.5);
    float2 p = (uv.xy - float2(0.5, 0.5)) / newScale * float2(ratio, 1.0);
    
    // This can probably be optimized (with distance())
    float angle = atan2(p.y, p.x) + angleOffset;
    float dist = distance(center, p);
    p.x = cos(angle) * dist / ratio + 0.5;
    p.y = sin(angle) * dist + 0.5;
    float4 c = progress < 0.5 ? getFromColor(p, fromTexture, ratio, _fromR) : getToColor(p, toTexture, ratio, _toR);

    // Finally, apply the color
    return c + (progress < 0.5 ? mix(0.0, 1.0, phase) : mix(1.0, 0.0, phase));
}


// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 FadeColorFragment(VertexOut vertexIn [[ stage_in ]],
                                  texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                  texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                  constant float3 & color [[ buffer(0) ]],
                                  constant float & colorPhase [[ buffer(1) ]],
                                  constant float & ratio [[ buffer(2) ]],
                                  constant float & progress [[ buffer(3) ]],
                                  sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    return mix(mix(float4(color, 1.0),
                   getFromColor(uv, fromTexture, ratio, _fromR),
                   smoothstep(1.0-colorPhase, 0.0, progress)),
               mix(float4(color, 1.0),
                   getToColor(uv, toTexture, ratio, _toR),
                   smoothstep(colorPhase, 1.0, progress)),
               progress);
}


//
//  MTFadeInWipeLeftTransition.metal
//  MTTransitions
//
//  Created by Nazmul on 04/08/2022.
//

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 FadeInWipeLeftFragment(VertexOut vertexIn [[ stage_in ]],
                            texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                            texture2d<float, access::sample> toTexture [[ texture(1) ]],
                            constant float & ratio [[ buffer(0) ]],
                            constant float & progress [[ buffer(1) ]],
                           
                                         sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float2 _uv = uv;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    _uv.x -= progress;
    
    if(uv.x >= progress)
    {
        return getFromColor(_uv, fromTexture, ratio, _fromR);
    }
    
    float4 a = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 b = getToColor(uv, toTexture, ratio, _toR);
    return mix(a, b, progress);
}







//
//  MTFadeInWipeUpTransition.metal
//  MTTransitions
//
//  Created by Nazmul on 04/08/2022.
//

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 FadeInWipeUpFragment(VertexOut vertexIn [[ stage_in ]],
                            texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                            texture2d<float, access::sample> toTexture [[ texture(1) ]],
                            constant float & ratio [[ buffer(0) ]],
                            constant float & progress [[ buffer(1) ]],
                           
                                         sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float2 _uv = uv;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    _uv.y -= progress;
    
    if(uv.y >= progress)
    {
        return getFromColor(_uv, fromTexture, ratio, _fromR);
    }
    
    float4 a = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 b = getToColor(uv, toTexture, ratio, _toR);
    return mix(a, b, progress);
}




// Author: gre
// license: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 FadeFragment(VertexOut vertexIn [[ stage_in ]],
                            texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                            texture2d<float, access::sample> toTexture [[ texture(1) ]],
                            constant float & ratio [[ buffer(0) ]],
                            constant float & progress [[ buffer(1) ]],
                            sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    float4 a = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 b = getToColor(uv, toTexture, ratio, _toR);
    return mix(a, b, progress);
}


// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float3 grayscale (float3 color) {
    return float3(0.2126*color.r + 0.7152*color.g + 0.0722*color.b);
}

fragment float4 FadegrayscaleFragment(VertexOut vertexIn [[ stage_in ]],
                                      texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                      texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                      constant float & intensity [[ buffer(0) ]],
                                      constant float & ratio [[ buffer(1) ]],
                                      constant float & progress [[ buffer(2) ]],
                                      sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    float4 fc = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 tc = getFromColor(uv, toTexture, ratio, _toR);
    return mix(mix(float4(grayscale(fc.rgb), 1.0), fc, smoothstep(1.0-intensity, 0.0, progress)),
               mix(float4(grayscale(tc.rgb), 1.0), tc, smoothstep(    intensity, 1.0, progress)),
               progress);
}



// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 FlyeyeFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & colorSeparation [[ buffer(0) ]],
                               constant float & zoom [[ buffer(1) ]],
                               constant float & size [[ buffer(2) ]],
                               constant float & ratio [[ buffer(3) ]],
                               constant float & progress [[ buffer(4) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float inv = 1.0 - progress;
    float2 disp = size*float2(cos(zoom*uv.x), sin(zoom*uv.y));
    float4 texTo = getToColor(uv + inv*disp, toTexture, ratio, _toR);
    float4 texFrom = float4(getFromColor(uv + progress*disp*(1.0 - colorSeparation), fromTexture, ratio, _fromR).r,
                            getFromColor(uv + progress*disp, fromTexture, ratio, _fromR).g,
                            getFromColor(uv + progress*disp*(1.0 + colorSeparation), fromTexture, ratio, _fromR).b,
                            1.0);
    return texTo*progress + texFrom*inv;
    
}


// Author: Matt DesLauriers
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float glitch_random(float2 co) {
    float a = 12.9898;
    float b = 78.233;
    float c = 43758.5453;
    float dt= dot(co.xy ,float2(a,b));
    float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

float glitch_voronoi(float2 x ) {
    float2 p = floor(x);
    float2 f = fract(x);
    float res = 8.0;
    for(float j = -1.0; j <= 1.0; j++ )
        for(float i = -1.0; i <= 1.0; i++ ) {
            float2  b = float2( i, j );
            float2  r = b - f + glitch_random(p + b);
            float d = dot(r, r);
            res = min( res, d );
        }
    return sqrt( res );
}

float2 displace(float4 tex, float2 texCoord, float dotDepth, float textureDepth, float strength) {
    //    float b = glitch_voronoi(.003 * texCoord + 2.0);
    //    float g = glitch_voronoi(0.2 * texCoord);
    //    float r = glitch_voronoi(texCoord - 1.0);
    float4 dt = tex * 1.0;
    float4 dis = dt * dotDepth + 1.0 - tex * textureDepth;
    
    dis.x = dis.x - 1.0 + textureDepth*dotDepth;
    dis.y = dis.y - 1.0 + textureDepth*dotDepth;
    dis.x *= strength;
    dis.y *= strength;
    float2 res_uv = texCoord ;
    res_uv.x = res_uv.x + dis.x - 0.0;
    res_uv.y = res_uv.y + dis.y;
    return res_uv;
}

float glitch_ease1(float t) {
    return t == 0.0 || t == 1.0
    ? t
    : t < 0.5
    ? +0.5 * pow(2.0, (20.0 * t) - 10.0)
    : -0.5 * pow(2.0, 10.0 - (t * 20.0)) + 1.0;
}
float glitch_ease2(float t) {
    return t == 1.0 ? t : 1.0 - pow(2.0, -10.0 * t);
}

fragment float4 GlitchDisplaceFragment(VertexOut vertexIn [[ stage_in ]],
                                       texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                       texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                       constant float & ratio [[ buffer(0) ]],
                                       constant float & progress [[ buffer(1) ]],
                                       sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 p = uv.xy / float2(1.0).xy;
    float4 color1 = getFromColor(p, fromTexture, ratio, _fromR);
    float4 color2 = getToColor(p, toTexture, ratio, _toR);
    float2 disp = displace(color1, p, 0.33, 0.7, 1.0-glitch_ease1(progress));
    float2 disp2 = displace(color2, p, 0.33, 0.5, glitch_ease2(progress));
    float4 dColor1 = getToColor(disp, toTexture, ratio, _toR);
    float4 dColor2 = getFromColor(disp2, fromTexture, ratio, _fromR);
    float val = glitch_ease1(progress);
    float3 gray = float3(dot(min(dColor2, dColor1).rgb, float3(0.299, 0.587, 0.114)));
    dColor2 = float4(gray, 1.0);
    dColor2 *= 2.0;
    color1 = mix(color1, dColor2, smoothstep(0.0, 0.5, progress));
    color2 = mix(color2, dColor1, smoothstep(1.0, 0.5, progress));
    return mix(color1, color2, val);
}


// Author: Gunnar Roth
// Based on work from natewave
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 GlitchMemoriesFragment(VertexOut vertexIn [[ stage_in ]],
                                       texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                       texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                       constant float & ratio [[ buffer(0) ]],
                                       constant float & progress [[ buffer(1) ]],
                                       sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 block = floor(uv.xy / float2(16));
    float2 uv_noise = block / float2(64);
    uv_noise += floor(float2(progress) * float2(1200.0, 3500.0)) / float2(64);
    float2 dist = progress > 0.0 ? (fract(uv_noise) - 0.5) * 0.3 *(1.0 -progress) : float2(0.0);
    float2 red = uv + dist * 0.2;
    float2 green = uv + dist * 0.3;
    float2 blue = uv + dist * 0.5;
    
    float r = mix(getFromColor(red, fromTexture, ratio, _fromR),
                  getToColor(red, toTexture, ratio, _toR),
                  progress).r;
    float g = mix(getFromColor(green, fromTexture, ratio, _fromR),
                  getToColor(green, toTexture, ratio, _toR),
                  progress).g;
    float b = mix(getFromColor(blue, fromTexture, ratio, _fromR),
                  getToColor(blue, toTexture, ratio, _toR),
                  progress).b;
    return float4(r, g, b, 1.0);
}


// License: MIT
// Author: TimDonselaar
// ported by gre from https://gist.github.com/TimDonselaar/9bcd1c4b5934ba60087bdb55c2ea92e5

#include <metal_stdlib>

using namespace metalpetal;

float getDelta(float2 p, int2 size) {
    float2 rectanglePos = floor(float2(size) * p);
    float2 rectangleSize = float2(1.0 / float2(size).x, 1.0 / float2(size).y);
    float top = rectangleSize.y * (rectanglePos.y + 1.0);
    float bottom = rectangleSize.y * rectanglePos.y;
    float left = rectangleSize.x * rectanglePos.x;
    float right = rectangleSize.x * (rectanglePos.x + 1.0);
    float minX = min(abs(p.x - left), abs(p.x - right));
    float minY = min(abs(p.y - top), abs(p.y - bottom));
    return min(minX, minY);
}

float getDividerSize(int2 size, float dividerWidth) {
    float2 rectangleSize = float2(1.0 / float2(size).x, 1.0 / float2(size).y);
    return min(rectangleSize.x, rectangleSize.y) * dividerWidth;
}

fragment float4 GridFlipFragment(VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                 texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                 constant float4 & bgcolor [[ buffer(0) ]],
                                 constant float & randomness [[ buffer(1) ]],
                                 constant float & pause [[ buffer(2) ]],
                                 constant float & dividerWidth [[ buffer(3) ]],
                                 constant int2 & size [[ buffer(4) ]],
                                 constant float & ratio [[ buffer(5) ]],
                                 constant float & progress [[ buffer(6) ]],
                                 sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    if(progress < pause) {
        float currentProg = progress / pause;
        float a = 1.0;
        if(getDelta(uv, size) < getDividerSize(size, dividerWidth)) {
            a = 1.0 - currentProg;
        }
        return mix(bgcolor, getFromColor(uv, fromTexture, ratio, _fromR), a);
    } else if(progress < 1.0 - pause){
        if(getDelta(uv, size) < getDividerSize(size, dividerWidth)) {
            return bgcolor;
        } else {
            float currentProg = (progress - pause) / (1.0 - pause * 2.0);
            float2 q = uv;
            float2 rectanglePos = floor(float2(size) * q);
            
            float r = rand(rectanglePos) - randomness;
            float cp = smoothstep(0.0, 1.0 - r, currentProg);
            
            float rectangleSize = 1.0 / float2(size).x;
            float delta = rectanglePos.x * rectangleSize;
            float offset = rectangleSize / 2.0 + delta;
            
            uv.x = (uv.x - offset)/abs(cp - 0.5)*0.5 + offset;
            float4 a = getFromColor(uv, fromTexture, ratio, _fromR);
            float4 b = getToColor(uv, toTexture, ratio, _toR);
            
            float s = step(abs(float2(size).x * (q.x - delta) - 0.5), abs(cp - 0.5));
            return mix(bgcolor, mix(b, a, step(cp, 0.5)), s);
        }
    } else {
        float currentProg = (progress - 1.0 + pause) / pause;
        float a = 1.0;
        if(getDelta(uv, size) < getDividerSize(size, dividerWidth)) {
            a = currentProg;
        }
        return mix(bgcolor, getToColor(uv, toTexture, ratio, _toR), a);
    }
}


// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float inHeart(float2 p, float2 center, float size) {
    if (size == 0.0) {
        return 0.0;
    }
    float2 o = (p-center)/(1.6*size);
    float a = o.x*o.x+o.y*o.y-0.3;
    return step(a*a*a, o.x*o.x*o.y*o.y*o.y);
}

fragment float4 HeartFragment(VertexOut vertexIn [[ stage_in ]],
                              texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                              texture2d<float, access::sample> toTexture [[ texture(1) ]],
                              constant float & ratio [[ buffer(0) ]],
                              constant float & progress [[ buffer(1) ]],
                              sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    return mix(getFromColor(uv, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               inHeart(uv, float2(0.5, 0.4), progress)
               );
}



// Author: Fernando Kuteken
// License: MIT
// Hexagonal math from: http://www.redblobgames.com/grids/hexagons/

#include <metal_stdlib>

using namespace metalpetal;

struct Hexagon {
    float q;
    float r;
    float s;
};

Hexagon createHexagon(float q, float r){
    Hexagon hex;
    hex.q = q;
    hex.r = r;
    hex.s = -q - r;
    return hex;
}

Hexagon roundHexagon(Hexagon hex){
    
    float q = floor(hex.q + 0.5);
    float r = floor(hex.r + 0.5);
    float s = floor(hex.s + 0.5);
    
    float deltaQ = abs(q - hex.q);
    float deltaR = abs(r - hex.r);
    float deltaS = abs(s - hex.s);
    
    if (deltaQ > deltaR && deltaQ > deltaS)
        q = -r - s;
    else if (deltaR > deltaS)
        r = -q - s;
    else
        s = -q - r;
    
    return createHexagon(q, r);
}

Hexagon hexagonFromPoint(float2 point, float size, float ratio) {
    
    point.y /= ratio;
    point = (point - 0.5) / size;
    
    float q = (sqrt(3.0) / 3.0) * point.x + (-1.0 / 3.0) * point.y;
    float r = 0.0 * point.x + 2.0 / 3.0 * point.y;
    
    Hexagon hex = createHexagon(q, r);
    return roundHexagon(hex);
    
}

float2 pointFromHexagon(Hexagon hex, float size, float ratio) {
    
    float x = (sqrt(3.0) * hex.q + (sqrt(3.0) / 2.0) * hex.r) * size + 0.5;
    float y = (0.0 * hex.q + (3.0 / 2.0) * hex.r) * size + 0.5;
    
    return float2(x, y * ratio);
}


fragment float4 HexagonalizeFragment(VertexOut vertexIn [[ stage_in ]],
                                     texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                     texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                     constant int & steps [[ buffer(0) ]],
                                     constant float & horizontalHexagons [[ buffer(1) ]],
                                     constant float & ratio [[ buffer(2) ]],
                                     constant float & progress [[ buffer(3) ]],
                                     sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    
    float dist = 2.0 * min(progress, 1.0 - progress);
    dist = steps > 0 ? ceil(dist * float(steps)) / float(steps) : dist;
    
    float size = (sqrt(3.0) / 3.0) * dist / horizontalHexagons;
    
    float2 point = dist > 0.0 ? pointFromHexagon(hexagonFromPoint(uv, size, ratio), size, ratio) : uv;
    
    return mix(getFromColor(point, fromTexture, ratio, _fromR),
               getToColor(point, toTexture, ratio, _toR),
               progress);
    
}



// Author: Hewlett-Packard
// License: BSD 3 Clause
// Adapted by Sergey Kosarevsky from:
// http://rectalogic.github.io/webvfx/examples_2transition-shader-pagecurl_8html-example.html

/*
 Copyright (c) 2010 Hewlett-Packard Development Company, L.P. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above
 copyright notice, this list of conditions and the following disclaimer
 in the documentation and/or other materials provided with the
 distribution.
 * Neither the name of Hewlett-Packard nor the names of its
 contributors may be used to endorse or promote products derived from
 this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 in float2 texCoord;
 */

#include <metal_stdlib>

using namespace metalpetal;

constexpr constant float scale = 512.0;
constexpr constant float sharpness = 3.0;
constexpr constant float cylinderRadius = 1.0/M_PI_F/2.0;

float3 hitPoint(float hitAngle, float yc, float3 point, float3x3 rrotation) {
    float hitPoint = hitAngle / (2.0 * M_PI_F);
    point.y = hitPoint;
    return rrotation * point;
}

float4 antiAlias(float4 color1, float4 color2, float distanc){
    float distance = distanc * scale;
    if (distance < 0.0) {
        return color2;
    }
    if (distance > 2.0) {
        return color1;
    }
    float dd = pow(1.0 - distance / 2.0, sharpness);
    return ((color2 - color1) * dd) + color1;
}

float distanceToEdge(float3 point) {
    float dx = abs(point.x > 0.5 ? 1.0 - point.x : point.x);
    float dy = abs(point.y > 0.5 ? 1.0 - point.y : point.y);
    if (point.x < 0.0) {
        dx = -point.x;
    }
    if (point.x > 1.0) {
        dx = point.x - 1.0;
    }
    if (point.y < 0.0) {
        dy = -point.y;
    }
    if (point.y > 1.0) {
        dy = point.y - 1.0;
    }
    if ((point.x < 0.0 || point.x > 1.0) && (point.y < 0.0 || point.y > 1.0)) {
        return sqrt(dx * dx + dy * dy);
    }
    return min(dx, dy);
}

float4 seeThrough(float yc, float2 p, float3x3 rotation, float3x3 rrotation,
                  float amount, float ratio,
                  texture2d<float, access::sample> fromTexture, float _fromR,
                  texture2d<float, access::sample> toTexture, float _toR) {

    float cylinderAngle = 2.0 * M_PI_F * amount;
    float hitAngle = M_PI_F - (acos(yc / cylinderRadius) - cylinderAngle);
    float3 point = hitPoint(hitAngle, yc, rotation * float3(p, 1.0), rrotation);
    if (yc <= 0.0 && (point.x < 0.0 || point.y < 0.0 || point.x > 1.0 || point.y > 1.0)) {
        return getToColor(p, toTexture, ratio, _toR);
    }
    
    if (yc > 0.0) {
        return getFromColor(p, fromTexture, ratio, _fromR);
    }
    
    float4 color = getFromColor(point.xy, fromTexture, ratio, _fromR);
    float4 tcolor = float4(0.0);
    
    return antiAlias(color, tcolor, distanceToEdge(point));
}

float4 seeThroughWithShadow(float yc, float2 p, float3 point, float3x3 rotation, float3x3 rrotation,
                            float amount, float ratio,
                            texture2d<float, access::sample> fromTexture, float _fromR,
                            texture2d<float, access::sample> toTexture, float _toR) {
    float shadow = distanceToEdge(point) * 30.0;
    shadow = (1.0 - shadow) / 3.0;
    
    if (shadow < 0.0) {
        shadow = 0.0;
    } else {
        shadow = shadow * amount;
    }
    
    float4 shadowColor = seeThrough(yc, p, rotation, rrotation, amount, ratio, fromTexture, _fromR, toTexture, _toR);
    shadowColor.r = shadowColor.r - shadow;
    shadowColor.g = shadowColor.g - shadow;
    shadowColor.b = shadowColor.b - shadow;
    
    return shadowColor;
}

float4 backside(float yc, float3 point, float ratio, texture2d<float, access::sample> fromTexture, float _fromR) {
    float4 color = getFromColor(point.xy, fromTexture, ratio, _fromR);
    float gray = (color.r + color.b + color.g) / 15.0;
    gray += (8.0 / 10.0) * (pow(1.0 - abs(yc/cylinderRadius), 2.0 / 10.0) / 2.0 + (5.0 / 10.0));
    color.rgb = float3(gray);
    return color;
}

float4 behindSurface(float2 p, float yc, float3 point, float3x3 rrotation,float amount, float cylinderAngle, float ratio, texture2d<float, access::sample> toTexture, float _toR) {
    float cylinderRadius =  1.0/M_PI_F/2.0;
    float shado = (1.0 - ((-cylinderRadius - yc) / amount * 7.0)) / 6.0;
    shado *= 1.0 - abs(point.x - 0.5);
    
    yc = (-cylinderRadius - cylinderRadius - yc);
    
    float hitAngle = (acos(yc / cylinderRadius) + cylinderAngle) - M_PI_F;
    point = hitPoint(hitAngle, yc, point, rrotation);
    
    if (yc < 0.0 && point.x >= 0.0 && point.y >= 0.0 && point.x <= 1.0 && point.y <= 1.0 && (hitAngle < M_PI_F || amount > 0.5)) {
        shado = 1.0 - (sqrt(pow(point.x - 0.5, 2.0) + pow(point.y - 0.5, 2.0)) / (71.0 / 100.0));
        shado *= pow(-yc / cylinderRadius, 3.0);
        shado *= 0.5;
    } else {
        shado = 0.0;
    }
    return float4(getToColor(p, toTexture, ratio, _toR).rgb - shado, 1.0);
}


fragment float4 InvertedPageCurlFragment(VertexOut vertexIn [[ stage_in ]],
                                         texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                         texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                         constant float & ratio [[ buffer(0) ]],
                                         constant float & progress [[ buffer(1) ]],
                                         sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    const float MIN_AMOUNT = -0.16;
    const float MAX_AMOUNT = 1.3;
    float amount = progress * (MAX_AMOUNT - MIN_AMOUNT) + MIN_AMOUNT;
    float cylinderCenter = amount;
    float cylinderAngle = 2.0 * M_PI_F * amount; // 360 degrees * amount
    
    const float angle = 100.0 * M_PI_F / 180.0;
    float c = cos(-angle);
    float s = sin(-angle);
    
    float3x3 rotation = float3x3(float3(c, s, 0),
                                 float3(-s, c, 0),
                                 float3(-0.801, 0.8900, 1));
    c = cos(angle);
    s = sin(angle);
    
    float3x3 rrotation = float3x3(float3(c, s, 0),
                                  float3(-s, c, 0),
                                  float3(0.98500, 0.985, 1));
    
    float3 point = rotation * float3(uv, 1.0);
    
    float yc = point.y - cylinderCenter;
    
    if (yc < -cylinderRadius) {
        // Behind surface
        return behindSurface(uv, yc, point, rrotation, amount, cylinderAngle, ratio, toTexture, _toR);
    }
    
    if (yc > cylinderRadius) {
        // Flat surface
        return getFromColor(uv, fromTexture, ratio, _fromR);
    }
    
    float hitAngle = (acos(yc/cylinderRadius) + cylinderAngle) - M_PI_F;
    float hitAngleMod = mod(hitAngle, 2.0 * M_PI_F);
    if ((hitAngleMod > M_PI_F && amount < 0.5) || (hitAngleMod > M_PI_F/2.0 && amount < 0.0)) {
        return seeThrough(yc, uv, rotation, rrotation, amount, ratio, fromTexture, _fromR, toTexture, _toR);
    }
    
    point = hitPoint(hitAngle, yc, point, rrotation);
    
    if (point.x < 0.0 || point.y < 0.0 || point.x > 1.0 || point.y > 1.0) {
        return seeThroughWithShadow(yc, uv, point, rotation, rrotation, amount, ratio, fromTexture, _fromR, toTexture, _toR);
    }
    
    float4 color = backside(yc, point, ratio, fromTexture, _fromR);
    
    float4 otherColor;
    if (yc < 0.0) {
        float shado = 1.0 - (sqrt(pow(point.x - 0.5, 2.0) + pow(point.y - 0.5, 2.0)) / 0.71);
        shado *= pow(-yc / cylinderRadius, 3.0);
        shado *= 0.5;
        otherColor = float4(0.0, 0.0, 0.0, shado);
    } else {
        otherColor = getFromColor(uv, fromTexture, ratio, _fromR);
    }
    
    color = antiAlias(color, otherColor, cylinderRadius - abs(yc));
    
    float4 cl = seeThroughWithShadow(yc, uv, point, rotation, rrotation, amount, ratio, fromTexture, _fromR, toTexture, _toR);
    float dist = distanceToEdge(point);
    
    return antiAlias(color, cl, dist);
}


// Author: nwoeanhinnogaehr
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 KaleidoScopeFragment(VertexOut vertexIn [[ stage_in ]],
                                     texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                     texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                     constant float & angle [[ buffer(0) ]],
                                     constant float & speed [[ buffer(1) ]],
                                     constant float & power [[ buffer(2) ]],
                                     constant float & ratio [[ buffer(3) ]],
                                     constant float & progress [[ buffer(4) ]],
                                     sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 p = uv.xy / float2(1.0).xy;
    float2 q = p;
    float t = pow(progress, power)*speed;
    p = p -0.5;
    for (int i = 0; i < 7; i++) {
        p = float2(sin(t)*p.x + cos(t)*p.y, sin(t)*p.y - cos(t)*p.x);
        t += angle;
        p = abs(fmod(p, 2.0) - 1.0);
    }
    abs(fmod(p, 1.0));
    return mix(mix(getFromColor(q, fromTexture, ratio, _fromR),
                   getToColor(q, toTexture, ratio, _toR), progress),
               mix(getFromColor(p, fromTexture, ratio, _fromR),
                   getToColor(p, toTexture, ratio, _toR), progress),
               1.0 - 2.0*abs(progress - 0.5));
}


// Author:zhmy
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

bool inBounds (float2 p) {
    const float2 boundMin = float2(0.0, 0.0);
    const float2 boundMax = float2(1.0, 1.0);
    return all(boundMin < p) && all(p < boundMax);
}

fragment float4 LeftRightFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & ratio [[ buffer(0) ]],
                               constant float & progress [[ buffer(1) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    float2 spfr,spto = float2(-1.);

    float size = mix(1.0, 3.0, progress*0.2);
    spto = (uv + float2(-0.5,-0.5))*float2(size,size) + float2(0.5,0.5);
    spfr = (uv - float2(1.-progress, 0.0));
    if(inBounds(spfr)){
        return getToColor(spfr, toTexture, ratio, _toR);
    } else if(inBounds(spto)) {
        return getFromColor(spto, fromTexture, ratio, _fromR) * (1.0 - progress);
    } else {
        return float4(0, 0, 0, 1.0);
    }
}


// Author: gre
// license: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 LinearBlurFragment(VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                   constant float & intensity [[ buffer(0) ]],
                                   constant float & ratio [[ buffer(1) ]],
                                   constant float & progress [[ buffer(2) ]],
                                   sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    const int passes = 6;
    float4 c1 = float4(0.0);
    float4 c2 = float4(0.0);
    float disp = intensity * (0.5 - abs(0.5 - progress));
    for (int xi = 0; xi < passes; xi++) {
        float x = float(xi) / float(passes) - 0.5;
        for (int yi=0; yi<passes; yi++)
        {
            float y = float(yi) / float(passes) - 0.5;
            float2 v = float2(x, y);
            float d = disp;
            c1 += getFromColor( uv + d*v, fromTexture, ratio, _fromR);
            c2 += getToColor( uv + d*v, toTexture, ratio, _toR);
        }
    }
    c1 /= float(passes*passes);
    c2 /= float(passes*passes);
    return mix(c1, c2, progress);
}


// Name: Lissajous Tiles
// Author: Boundless <info@boundless-beta.com>
// License: MIT
// <3

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 LissajousTilesFragment(VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                   constant float & speed [[ buffer(0) ]],
                                   constant float2 & freq [[ buffer(1) ]],
                                   constant float & offset [[ buffer(2) ]],
                                   constant float & zoom [[ buffer(3) ]],
                                   constant float & fade [[ buffer(4) ]],
                                   constant float & ratio [[ buffer(5) ]],
                                   constant float & progress [[ buffer(6) ]],
                                   sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    const float2 grid = float2(10.,10.); // grid size
    float4 col = float4(0.);
    float p = 1.-pow(abs(1.-2.*progress),3.); // transition curve
    for (float h = 0.; h < grid.x*grid.y; h+=1.) {
        float iBig = mod(h,grid.x);
        float jBig = floor(h / grid.x);
        float i = iBig/grid.x;
        float j = jBig/grid.y;
        float2 uv0 = (uv + float2(i,j) - 0.5 + 0.5/grid + float2(cos((i/grid.y+j)*6.28*freq.x+progress*6.*speed)*zoom/2.,sin((i/grid.y+j)*6.28*freq.y+progress*6.*(1.+offset)*speed)*zoom/2.));
        uv0 = uv0*p + uv*(1.-p);
        bool m = uv0.x > i && uv0.x < (i+1./grid.x) && uv0.y > j && uv0.y < (j+1./grid.x); // mask for each (i,j) tile
        col *= 1.-float(m);
        col += mix(
                   getFromColor(uv0, fromTexture, ratio, _fromR),
                   getToColor(uv0, toTexture, ratio, _toR),
                   min(max((progress)*(((1.+fade)*2.)*progress)-(fade)+(i/grid.y+j)*(fade),0.),1.)
                   )*float(m);
    }
    return col;
}


// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 LumaFragment(VertexOut vertexIn [[ stage_in ]],
                             texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                             texture2d<float, access::sample> toTexture [[ texture(1) ]],
                             texture2d<float, access::sample> luma [[ texture(2) ]],
                             constant float & ratio [[ buffer(0) ]],
                             constant float & progress [[ buffer(1) ]],
                             sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    float r = luma.sample(s, uv).r;
    
    return mix(getFromColor(uv, toTexture, ratio, _toR),
               getToColor(uv, fromTexture, ratio, _fromR),
               step(progress, r)
               );
}


// Author: 0gust1
// License: MIT
// Simplex noise :
// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License : MIT
//               2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//


//My own first transition — based on crosshatch code (from pthrasher), using  simplex noise formula (copied and pasted)
//-> cooler with high contrasted images (isolated dark subject on light background f.e.)
//TODO : try to rebase it on DoomTransition (from zeh)?
//optimizations :
//luminance (see http://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color#answer-596241)
// Y = (R+R+B+G+G+G)/6
//or Y = (R+R+R+B+G+G+G+G)>>3

#include <metal_stdlib>

using namespace metalpetal;

float3 mod289(float3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float2 mod289(float2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float3 permute(float3 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float snoise(float2 v) {
    const float4 C = float4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                            0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                            -0.577350269189626,  // -1.0 + 2.0 * C.x
                            0.024390243902439); // 1.0 / 41.0
    // First corner
    float2 i  = floor(v + dot(v, C.yy) );
    float2 x0 = v -   i + dot(i, C.xx);
    
    // Other corners
    float2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    float4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    
    // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    float3 p = permute( permute( i.y + float3(0.0, i1.y, 1.0 ))
                       + i.x + float3(0.0, i1.x, 1.0 ));
    
    float3 m = max(0.5 - float3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;
    
    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
    
    float3 x = 2.0 * fract(p * C.www) - 1.0;
    float3 h = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;
    
    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    
    // Compute final noise value at P
    float3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// Simplex noise -- end

float luminance(float4 color){
  //(0.299*R + 0.587*G + 0.114*B)
  return color.r*0.299+color.g*0.587+color.b*0.114;
}

fragment float4 LuminanceMeltFragment(VertexOut vertexIn [[ stage_in ]],
                                      texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                      texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                      constant bool & direction [[ buffer(0) ]],
                                      constant bool & above [[ buffer(1) ]],
                                      constant float & l_threshold [[ buffer(2) ]],
                                      constant float & ratio [[ buffer(3) ]],
                                      constant float & progress [[ buffer(4) ]],
                                      sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 center = float2(1.0, direction);
    
    float2 p = uv.xy / float2(1.0).xy;
    if (progress == 0.0) {
        return getFromColor(p, fromTexture, ratio, _fromR);
    } else if (progress == 1.0) {
        return getToColor(p, toTexture, ratio, _toR);
    } else {
        float x = progress;
        float dist = distance(center, p)- progress*exp(snoise(float2(p.x, 0.0)));
        float r = x - rand(float2(p.x, 0.1));
        float m;
        if(above){
            m = dist <= r && luminance(getFromColor(p, fromTexture, ratio, _fromR))>l_threshold ? 1.0 : (progress*progress*progress);
        } else{
            m = dist <= r && luminance(getFromColor(p, fromTexture, ratio, _fromR))<l_threshold ? 1.0 : (progress*progress*progress);
        }
        return mix(getFromColor(p, fromTexture, ratio, _fromR),
                   getToColor(p, toTexture, ratio, _toR), m);
    }
}


// Author: paniq
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 MorphFragment(VertexOut vertexIn [[ stage_in ]],
                              texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                              texture2d<float, access::sample> toTexture [[ texture(1) ]],
                              constant float & strength [[ buffer(0) ]],
                              constant float & ratio [[ buffer(1) ]],
                              constant float & progress [[ buffer(2) ]],
                              sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float4 ca = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 cb = getToColor(uv, toTexture, ratio, _toR);
    float2 oa = (((ca.rg + ca.b) * 0.5) * 2.0 - 1.0);
    float2 ob = (((cb.rg + cb.b) * 0.5) * 2.0 - 1.0);
    float2 oc = mix(oa, ob, 0.5) * strength;
    
    float w0 = progress;
    float w1 = 1.0 - w0;
    return mix(getFromColor(uv + oc * w0, fromTexture, ratio, _fromR),
               getToColor(uv - oc * w1, toTexture, ratio, _toR),
               progress);
}


// License: MIT
// Author: Xaychru
// ported by gre from https://gist.github.com/Xaychru/130bb7b7affedbda9df5

#include <metal_stdlib>

using namespace metalpetal;

#define POW2(X) X*X
#define POW3(X) X*X*X

float2 mosaicRotate(float2 v, float a) {
  float2x2 rm = float2x2(float2(cos(a), -sin(a)),
                         float2(sin(a), cos(a)));
  return rm*v;
}

float cosInterpolation(float x) {
    return -cos(x*M_PI_F)/2.0 + 0.5;
}

fragment float4 MosaicFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant int & endy [[ buffer(0) ]],
                               constant int & endx [[ buffer(1) ]],
                               constant float & ratio [[ buffer(2) ]],
                               constant float & progress [[ buffer(3) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 p = uv.xy / float2(1.0).xy - 0.5;
    float2 rp = p;
    float rpr = (progress * 2.0 - 1.0);
    float z = -(rpr * rpr * 2.0) + 3.0;
    float az = abs(z);
    rp *= az;
    rp += mix(float2(0.5, 0.5), float2(float(endx) + 0.5, float(endy) + 0.5), POW2(cosInterpolation(progress)));
    float2 mrp =  rp - 1.0 * floor(rp/1.0);
    float2 crp = rp;
    bool onEnd = int(floor(crp.x)) == endx && int(floor(crp.y)) == endy;
    if(!onEnd) {
        float ang = float(int(rand(floor(crp)) * 4.0)) * 0.5 * M_PI_F;
        mrp = float2(0.5) + mosaicRotate(mrp - float2(0.5), ang);
    }
    if(onEnd || rand(floor(crp)) > 0.5) {
        return getToColor(mrp, toTexture, ratio, _toR);
    } else {
        return getFromColor(mrp, fromTexture, ratio, _fromR);
    }
}


// Author: YueDev
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float2 getMosaicUV(float2 uv, float mosaicNum, float progress) {
    float mosaicWidth = 2.0 / mosaicNum * min(progress, 1.0 - progress);
    float mX = floor(uv.x / mosaicWidth) + 0.5;
    float mY = floor(uv.y / mosaicWidth) + 0.5;
    return float2(mX * mosaicWidth, mY * mosaicWidth);
}

fragment float4 MosaicYueDevFragment(VertexOut vertexIn [[ stage_in ]],
                                      texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                      texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                     constant float & mosaicNum [[ buffer(0) ]],
                                      constant float & ratio [[ buffer(1) ]],
                                      constant float & progress [[ buffer(2) ]],
                                      sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 mosaicUV = min(progress, 1.0 - progress) == 0.0 ? uv : getMosaicUV(uv, mosaicNum, progress);
    
    return mix(
               getFromColor(mosaicUV, fromTexture, ratio, _fromR),
               getToColor(mosaicUV, toTexture, ratio, _toR),
               progress * progress);
}


// Author: Fernando Kuteken
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float4 blend(float4 a, float4 b) {
    return a * b;
}

fragment float4 MultiplyBlendFragment(VertexOut vertexIn [[ stage_in ]],
                                      texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                      texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                      constant float & ratio [[ buffer(0) ]],
                                      constant float & progress [[ buffer(1) ]],
                                      sampler textureSampler [[ sampler(0) ]]) 
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    
    float4 blended = blend(getFromColor(uv, fromTexture, ratio, _fromR), getFromColor(uv, toTexture, ratio, _toR));
    
    if (progress < 0.5) {
        return mix(getFromColor(uv, fromTexture, ratio, _fromR), blended, 2.0 * progress);
    } else {
        return mix(blended, getFromColor(uv, toTexture, ratio, _toR), 2.0 * progress - 1.0);
    }
}


// Author: Ben Zhang
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 OverexposureFragment(VertexOut vertexIn [[ stage_in ]],
                texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                texture2d<float, access::sample> toTexture [[ texture(1) ]],
                constant float & strength [[ buffer(0) ]],
                constant float & ratio [[ buffer(1) ]],
                constant float & progress [[ buffer(2) ]],
                sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float4 from = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 to = getToColor(uv, toTexture, ratio, _toR);
    // Multipliers
    float from_m = 1.0 - progress + sin(PI * progress) * strength;
    float to_m = progress + sin(PI * progress) * strength;

      return float4(
        from.r * from.a * from_m + to.r * to.a * to_m,
        from.g * from.a * from_m + to.g * to.a * to_m,
        from.b * from.a * from_m + to.b * to.a * to_m,
        mix(from.a, to.a, progress)
      );
}


// Author: Yoni Maltsman @friendlyspinach
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 ParametricGlitchFragment(VertexOut vertexIn [[ stage_in ]],
                                         texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                         texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                         constant float & ampx [[ buffer(0) ]],
                                         constant float & ampy [[ buffer(1) ]],
                                         constant float & ratio [[ buffer(2) ]],
                                         constant float & progress [[ buffer(3) ]],
                                         sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float4 from = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 to = getToColor(uv, toTexture, ratio, _toR);
    float r = from.r;
    float g = from.g;
    float b = from.b;
    float sphere = r*r + g*g + b*b - 1.0; //3 to 1
    float spiralX = cos(sphere - uv.x/(progress + .01));
    float spiralY = sin(sphere - uv.y/(progress+.01));
    float2 st = uv;
    st.x = fract(ampx*st.x*spiralX); //1 to 2
    st.y = fract(ampy*st.y*spiralY);
    float2 diff = uv - st;
    from = getFromColor(uv + progress*diff, fromTexture, ratio, _fromR);
    return mix(from, to, progress);
}


// Author: Rich Harris
// License: MIT
// http://byteblacksmith.com/improvements-to-the-canonical-one-liner-glsl-rand-for-opengl-es-2-0/

#include <metal_stdlib>

using namespace metalpetal;

float perlin_random(float2 co, float seed) {
    float a = seed;
    float b = 78.233;
    float c = 43758.5453;
    float dt= dot(co.xy ,float2(a,b));
    float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

// 2D Noise based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float perlin_noise(float2 st, float seed) {
    float2 i = floor(st);
    float2 f = fract(st);
    
    // Four corners in 2D of a tile
    float a = perlin_random(i, seed);
    float b = perlin_random(i + float2(1.0, 0.0), seed);
    float c = perlin_random(i + float2(0.0, 1.0), seed);
    float d = perlin_random(i + float2(1.0, 1.0), seed);
    
    // Smooth Interpolation
    
    // Cubic Hermine Curve.  Same as SmoothStep()
    float2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);
    
    // Mix 4 coorners porcentages
    return mix(a, b, u.x) +
    (c - a)* u.y * (1.0 - u.x) +
    (d - b) * u.x * u.y;
}


fragment float4 PerlinFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & scale [[ buffer(0) ]],
                               constant float & seed [[ buffer(1) ]],
                               constant float & smoothness [[ buffer(2) ]],
                               constant float & ratio [[ buffer(3) ]],
                               constant float & progress [[ buffer(4) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float4 from = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 to = getToColor(uv, toTexture, ratio, _toR);
    float n = perlin_noise(uv * scale, seed);
    
    float p = mix(-smoothness, 1.0 + smoothness, progress);
    float lower = p - smoothness;
    float higher = p + smoothness;
    
    float q = smoothstep(lower, higher, n);
    
    return mix(from, to, 1.0 - q);
}



// Author: Mr Speaker
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 PinwheelFragment(VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                 texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                 constant float & speed [[ buffer(0) ]],
                                 constant float & ratio [[ buffer(1) ]],
                                 constant float & progress [[ buffer(2) ]],
                                 sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 p = uv.xy / float2(1.0).xy;
    
    float circPos = atan2(p.y - 0.5, p.x - 0.5) + progress * speed;
    float modPos = mod(circPos, 3.1415 / 4.);
    float s = sign(progress - modPos);
    
    return mix(getToColor(p, toTexture, ratio, _toR),
               getFromColor(p, fromTexture, ratio, _fromR),
               step(s, 0.5));
}


// Author: gre
// License: MIT
// forked from https://gist.github.com/benraziel/c528607361d90a072e98

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 PixelizeFragment(VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                 texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                 constant uint2 & squaresMin [[ buffer(0) ]],
                                 constant int & steps [[ buffer(1) ]],
                                 constant float & ratio [[ buffer(2) ]],
                                 constant float & progress [[ buffer(3) ]],
                                 sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float d = min(progress, 1.0 - progress);
    float dist = steps >0 ? ceil(d * float(steps)) / float(steps) : d;
    float2 squareSize = 2.0 * dist / float2(squaresMin);
    float2 p = dist>0.0 ? (floor(uv / squareSize) + 0.5) * squareSize : uv;
    return mix(getFromColor(p, fromTexture, ratio, _fromR),
               getToColor(p, toTexture, ratio, _toR),
               progress);
}


// Author: Fernando Kuteken
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 PolarFunctionFragment(VertexOut vertexIn [[ stage_in ]],
                                      texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                      texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                      constant int & segments [[ buffer(0) ]],
                                      constant float & ratio [[ buffer(1) ]],
                                      constant float & progress [[ buffer(2) ]],
                                      sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float angle = atan2(uv.y - 0.5, uv.x - 0.5) - 0.5 * PI;
    //  float normalized = (angle + 1.5 * PI) * (2.0 * PI);
    
    float radius = (cos(float(segments) * angle) + 4.0) / 4.0;
    float difference = length(uv - float2(0.5, 0.5));
    
    if (difference > radius * progress) {
        return getFromColor(uv, fromTexture, ratio, _fromR);
    } else {
        return getFromColor(uv, toTexture, ratio, _toR);
    }
}



// Author: bobylito
// license: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 PolkaDotsCurtainFragment(VertexOut vertexIn [[ stage_in ]],
                                         texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                         texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                         constant float & dots [[ buffer(0) ]],
                                         constant float2 & center [[ buffer(1) ]],
                                         constant float & ratio [[ buffer(2) ]],
                                         constant float & progress [[ buffer(3) ]],
                                         sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    //const float SQRT_2 = 1.414213562373;
    bool nextImage = distance(fract(uv * dots), float2(0.5, 0.5)) < ( progress / distance(uv, center));
    return nextImage ? getToColor(uv, toTexture, ratio, _toR) : getFromColor(uv, fromTexture, ratio, _fromR);
}


// Name: Power Kaleido
// Author: Boundless
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float2 refl(float2 p,float2 o,float2 n)
{
    return 2.0*o+2.0*n*dot(p-o,n)-p;
}

float2 rot(float2 p, float2 o, float a)
{
    float s = sin(a);
    float c = cos(a);
    return o + float2x2(float2(c, -s), float2(s, c)) * (p - o);
}

fragment float4 PowerKaleidoFragment(VertexOut vertexIn [[ stage_in ]],
                                     texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                     texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                     constant float & scale [[ buffer(0) ]],
                                     constant float & z [[ buffer(1) ]],
                                     constant float & speed [[ buffer(2) ]],
                                     constant float & ratio [[ buffer(3) ]],
                                     constant float & progress [[ buffer(4) ]],
                                     sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    const float rad = 120.; // change this value to get different mirror effects
    const float deg = rad / 180. * PI;
    float dist = scale / 10.0;
    
    float2 uv0 = uv;
    uv -= 0.5;
    uv.x *= ratio;
    uv *= z;
    uv = rot(uv, float2(0.0), progress*speed);
    // uv.x = fract(uv.x/l/3.0)*l*3.0;
    //float theta = progress*6.+PI/.5;
    for(int iter = 0; iter < 10; iter++) {
    for(float i = 0.; i < 2. * PI; i+=deg) {
        float ts = sign(asin(cos(i))) == 1.0 ? 1.0 : 0.0;
        if(((ts == 1.0) && (uv.y-dist*cos(i) > tan(i)*(uv.x+dist*+sin(i)))) || ((ts == 0.0) && (uv.y-dist*cos(i) < tan(i)*(uv.x+dist*+sin(i))))) {
            uv = refl(float2(uv.x+sin(i)*dist*2.,uv.y-cos(i)*dist*2.), float2(0.,0.), float2(cos(i),sin(i)));
          }
        }
    }
    uv += 0.5;
    uv = rot(uv, float2(0.5), progress*-speed);
    uv -= 0.5;
    uv.x /= ratio;
    uv += 0.5;
    uv = 2.*abs(uv/2.-floor(uv/2.+0.5));
    float2 uvMix = mix(uv,uv0,cos(progress*PI*2.)/2.+0.5);
    float4 color = mix(getFromColor(uvMix, fromTexture, ratio, _fromR),
                         getToColor(uvMix, toTexture, ratio, _toR),cos((progress-1.)*PI)/2.+0.5);
    return color;
}


// License: MIT
// Author: Xaychru
// ported by gre from https://gist.github.com/Xaychru/ce1d48f0ce00bb379750

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 RadialFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & smoothness [[ buffer(0) ]],
                               constant float & ratio [[ buffer(1) ]],
                               constant float & progress [[ buffer(2) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 rp = uv * 2.0 - 1.0;
    return mix(getToColor(uv, toTexture, ratio, _toR),
               getFromColor(uv, fromTexture, ratio, _fromR),
               smoothstep(0.0, smoothness, atan2(rp.y,rp.x) - (progress - 0.5) * PI * 2.5)
               );
}



// Author:towrabbit
// License: MIT


#include <metal_stdlib>

using namespace metalpetal;

float random (float2 st) {
    return fract(sin(dot(st.xy,float2(12.9898,78.233)))*43758.5453123);
}

fragment float4 MTRandomNoisexFragment(VertexOut vertexIn [[ stage_in ]],
                                      texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                      texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                      constant float & ratio [[ buffer(0) ]],
                                      constant float & progress [[ buffer(1) ]],
                                      sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float4 leftSide = getFromColor(uv, fromTexture, ratio, _fromR);
    float2 uv1 = uv;
//    float2 uv2 = uv;
    float uvz = floor(random(uv1)+progress);
    float4 rightSide = getToColor(uv, toTexture, ratio, _toR);
//    float p = progress*2.0;
    return mix(leftSide,rightSide,uvz);
//    return leftSide * ceil(uv.x*2.-p) + rightSide * ceil(-uv.x*2.+p);
}


// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 RandomSquaresFragment(VertexOut vertexIn [[ stage_in ]],
                                      texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                      texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                      constant float & smoothness [[ buffer(0) ]],
                                      constant float2 & size [[ buffer(1) ]],
                                      constant float & ratio [[ buffer(2) ]],
                                      constant float & progress [[ buffer(3) ]],
                                      sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float r = rand(floor(float2(size) * uv));
    float m = smoothstep(0.0, -smoothness, r - (progress * (1.0 + smoothness)));
    return mix(getFromColor(uv, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               m);
    
}


// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 RippleFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & speed [[ buffer(0) ]],
                               constant float & amplitude [[ buffer(1) ]],
                               constant float & ratio [[ buffer(2) ]],
                               constant float & progress [[ buffer(3) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 dir = uv - float2(.5);
    float dist = length(dir);
    float2 offset = dir * (sin(progress * dist * amplitude - progress * speed) + .5) / 30.;
    return mix(getFromColor(uv + offset, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               smoothstep(0.2, 1.0, progress)
               );
}



// Author: Fernando Kuteken
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 RotateScaleFadeFragment(VertexOut vertexIn [[ stage_in ]],
                                        texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                        texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                        constant float & scale [[ buffer(0) ]],
                                        constant float & rotations [[ buffer(1) ]],
                                        constant float2 & center [[ buffer(2) ]],
                                        constant float4 & backColor [[ buffer(3) ]],
                                        constant float & ratio [[ buffer(4) ]],
                                        constant float & progress [[ buffer(5) ]],
                                        sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    
    float2 difference = uv - center;
    float2 dir = normalize(difference);
    float dist = length(difference);
    
    float angle = 2.0 * PI * rotations * progress;
    
    float c = cos(angle);
    float s = sin(angle);
    
    float currentScale = mix(scale, 1.0, 2.0 * abs(progress - 0.5));
    
    float2 rotatedDir = float2(dir.x  * c - dir.y * s, dir.x * s + dir.y * c);
    float2 rotatedUv = center + rotatedDir * dist / currentScale;
    
    if (rotatedUv.x < 0.0 || rotatedUv.x > 1.0 ||
        rotatedUv.y < 0.0 || rotatedUv.y > 1.0)
        return backColor;
    
    return mix(getFromColor(rotatedUv, fromTexture, ratio, _fromR),
               getToColor(rotatedUv, toTexture, ratio, _toR),
               progress);
}



// Author: haiyoucuv
// License: MIT
#include <metal_stdlib>

using namespace metalpetal;

float2 rotate2D(float2 uv, float angle){
  
  return uv * float2x2(float2(cos(angle), -sin(angle)),
                       float2(sin(angle), cos(angle)));
}

fragment float4 RotateFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & ratio [[ buffer(0) ]],
                               constant float & progress [[ buffer(1) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    float2 p = fract(rotate2D(uv - 0.5, progress * PI * 2.0) + 0.5);
    float4 a = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 b = getToColor(uv, toTexture, ratio, _toR);
    return mix(a, b, step(0.0 + p.x, progress));
}


// Author:haiyoucuv
// License: MIT
#include <metal_stdlib>

using namespace metalpetal;

fragment float4 ScaleInFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & ratio [[ buffer(0) ]],
                               constant float & progress [[ buffer(1) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    float4 a = getFromColor(uv, fromTexture, ratio, _fromR);
    uv = 0.5 + (uv - 0.5) * progress;
    float4 b = getToColor(uv, toTexture, ratio, _toR);
    return mix(a, b, progress);
}


// Author: 0gust1
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float2 simple_zoom(float2 uv, float amount) {
    return 0.5 + ((uv - 0.5) * (1.0-amount));
}

fragment float4 SimpleZoomFragment(VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                   constant float & zoomQuickness [[ buffer(0) ]],
                                   constant float & ratio [[ buffer(1) ]],
                                   constant float & progress [[ buffer(2) ]],
                                   sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float nQuick = clamp(zoomQuickness,0.2,1.0);
    
    return mix(getFromColor(simple_zoom(uv, smoothstep(0.0, nQuick, progress)), fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               smoothstep(nQuick-0.2, 1.0, progress)
               );
}


// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 SquaresWireFragment(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                    texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                    constant float2 & direction [[ buffer(0) ]],
                                    constant int2 & squares [[ buffer(1) ]],
                                    constant float & smoothness [[ buffer(2) ]],
                                    constant float & ratio [[ buffer(3) ]],
                                    constant float & progress [[ buffer(4) ]],
                                    sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    const float2 center = float2(0.5, 0.5);
    
    float2 v = normalize(direction);
    v = v / (abs(v.x) + abs(v.y));
    float d = v.x * center.x + v.y * center.y;
    float offset = smoothness;
    float pr = smoothstep(-offset, 0.0, v.x * uv.x + v.y * uv.y - (d - 0.5 + progress * (1.0 + offset)));
    float2 squarep = fract(uv * float2(squares));
    float2 squaremin = float2(pr/2.0);
    float2 squaremax = float2(1.0 - pr/2.0);
    float a = (1.0 - step(progress, 0.0))
                * step(squaremin.x, squarep.x)
                * step(squaremin.y, squarep.y)
                * step(squarep.x, squaremax.x)
                * step(squarep.y, squaremax.y);
    
    return mix(getFromColor(uv, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               a);
}



// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;
 
fragment float4 SqueezeFragment(VertexOut vertexIn [[ stage_in ]],
                                texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                constant float & colorSeparation [[ buffer(0) ]],
                                constant float & ratio [[ buffer(1) ]],
                                constant float & progress [[ buffer(2) ]],
                                sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float y = 0.5 + (uv.y-0.5) / (1.0-progress);
    if (y < 0.0 || y > 1.0) {
        return getToColor(uv, toTexture, ratio, _toR);
    } else {
        float2 fp = float2(uv.x, y);
        float2 off = progress * float2(0.0, colorSeparation);
        float4 c = getFromColor(fp, fromTexture, ratio, _fromR);
        float4 cn = getFromColor(fp - off, fromTexture, ratio, _fromR);
        float4 cp = getFromColor(fp + off, fromTexture, ratio, _fromR);
        return float4(cn.r, c.g, cp.b, c.a);
    }
}



// Author:Ben Lucas
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

#ifndef PI
#define PI 3.141592653589793
#endif
#define STAR_ANGLE 1.2566370614359172

float2 rotate(float2 v, float theta) {
    float cosTheta = cos(theta);
    float sinTheta = sin(theta);
    
    return float2(
                cosTheta * v.x - sinTheta * v.y,
                sinTheta * v.x + cosTheta * v.y
                );
}

bool inStar(float2 uv, float2 center, float radius, float starRotation){
    float2 uv_centered = uv - center;
    uv_centered = rotate(uv_centered, starRotation * STAR_ANGLE);
    float theta = atan2(uv_centered.y, uv_centered.x) + PI;
    
    float2 uv_rotated = rotate(uv_centered, -STAR_ANGLE * (floor(theta / STAR_ANGLE) + 0.5));
    
    float slope = 0.3;
    if(uv_rotated.y > 0.0){
        return (radius + uv_rotated.x * slope > uv_rotated.y);
    } else{
        return (-radius - uv_rotated.x * slope < uv_rotated.y);
    }
}

fragment float4 StarWipeFragment(VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                 texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                 constant float & borderThickness [[ buffer(0) ]],
                                 constant float & starRotation [[ buffer(1) ]],
                                 constant float4 & borderColor [[ buffer(2) ]],
                                 constant float2 & starCenter [[ buffer(3) ]],
                                 constant float & ratio [[ buffer(4) ]],
                                 constant float & progress [[ buffer(5) ]],
                                 sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float progressScaled = (2.0 * borderThickness + 1.0) * progress - borderThickness;
    if(inStar(uv, starCenter, progressScaled, starRotation)){
        return getToColor(uv, toTexture, ratio, _toR);
    } else if(inStar(uv, starCenter, progressScaled+borderThickness, starRotation)){
        return borderColor;
    }
    else{
        return getFromColor(uv, fromTexture, ratio, _fromR);
    }
}


// Author: Ben Lucas
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

float rnd (float2 st) {
    return fract(sin(dot(st.xy,
                         float2(10.5302340293,70.23492931)))*
                 12345.5453123);
}

float4 staticNoise (float2 st, float offset, float luminosity) {
    float staticR = luminosity * rnd(st * float2(offset * 2.0, offset * 3.0));
    float staticG = luminosity * rnd(st * float2(offset * 3.0, offset * 5.0));
    float staticB = luminosity * rnd(st * float2(offset * 5.0, offset * 7.0));
    return float4(staticR, staticG, staticB, 1.0);
}

float staticIntensity(float t)
{
    float transitionProgress = abs(2.0*(t-0.5));
    float transformedThreshold =1.2*(1.0 - transitionProgress)-0.1;
    return min(1.0, transformedThreshold);
}

fragment float4 StaticFadeFragment(VertexOut vertexIn [[ stage_in ]],
                                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                   constant float & nNoisePixels [[ buffer(0) ]],
                                   constant float & staticLuminosity [[ buffer(1) ]],
                                   constant float & ratio [[ buffer(2) ]],
                                   constant float & progress [[ buffer(3) ]],
                                   sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float baseMix = step(0.5, progress);
    float4 transitionMix = mix(
                               getFromColor(uv, fromTexture, ratio, _fromR),
                               getToColor(uv, toTexture, ratio, _toR),
                               baseMix
                               );
    
    float2 uvStatic = floor(uv * nNoisePixels)/nNoisePixels;
    
    float4 staticColor = staticNoise(uvStatic, progress, staticLuminosity);
    
    float staticThresh = staticIntensity(progress);
    float staticMix = step(rnd(uvStatic), staticThresh);
    
    return mix(transitionMix, staticColor, staticMix);
    
}


// Author: Ted Schundler
// License: BSD 2 Clause
// Free for use and modification by anyone with credit

// Copyright (c) 2016, Theodore K Schundler
// All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

///////////////////////////////////////////////////////////////////////////////
// Stereo Viewer Toy Transition                                              //
//                                                                           //
// Inspired by ViewMaster / Image3D image viewer devices.                    //
// This effect is similar to what you see when you press the device's lever. //
// There is a quick zoom in / out to make the transition 'valid' for GLSL.io //
///////////////////////////////////////////////////////////////////////////////

#include <metal_stdlib>

using namespace metalpetal;

// TODO

#define black float4(0.0, 0.0, 0.0, 1.0)
#define c00 float2(0.0, 0.0) // the four corner points
#define c01 float2(0.0, 1.0)
#define c11 float2(1.0, 1.0)
#define c10 float2(1.0, 0.0)
//
// Check if a point is within a given corner
bool in_corner(float2 p, float2 corner, float2 radius) {
    // determine the direction we want to be filled
    float2 axis = (c11 - corner) - corner;
    
    // warp the point so we are always testing the bottom left point with the
    // circle centered on the origin
    p = p - (corner + axis * radius);
    p *= axis / radius;
    return (p.x > 0.0 && p.y > -1.0) || (p.y > 0.0 && p.x > -1.0) || dot(p, p) < 1.0;
}

// Check all four corners
// return a float for v2 for anti-aliasing?
bool test_rounded_mask(float2 p, float2 corner_size) {
    return
    in_corner(p, c00, corner_size) &&
    in_corner(p, c01, corner_size) &&
    in_corner(p, c10, corner_size) &&
    in_corner(p, c11, corner_size);
}

// Screen blend mode - https://en.wikipedia.org/wiki/Blend_modes
// This more closely approximates what you see than linear blending
float4 screen(float4 a, float4 b) {
  return 1.0 - (1.0 - a) * (1.0 -b);
}

// Given RGBA, find a value that when screened with itself
// will yield the original value.
float4 unscreen(float4 c) {
  return 1.0 - sqrt(1.0 - c);
}

// Grab a pixel, only if it isn't masked out by the rounded corners
float4 sample_with_corners_from(float2 p, float2 corner_size, float zoom, float ratio, texture2d<float, access::sample> fromTexture, float _fromR) {
    p = (p - 0.5) / zoom + 0.5;
    if (!test_rounded_mask(p, corner_size)) {
        return black;
    }
    return unscreen(getFromColor(p, fromTexture, ratio, _fromR));
}

float4 sample_with_corners_to(float2 p, float2 corner_size, float zoom, float ratio, texture2d<float, access::sample> toTexture, float _toR) {
    p = (p - 0.5) / zoom + 0.5;
    if (!test_rounded_mask(p, corner_size)) {
        return black;
    }
    return unscreen(getToColor(p, toTexture, ratio, _toR));
}

// special sampling used when zooming - extra zoom parameter and don't unscreen
float4 simple_sample_with_corners_from(float2 p, float2 corner_size, float zoom_amt, float zoom, float ratio, texture2d<float, access::sample> fromTexture, float _fromR) {
    p = (p - 0.5) / (1.0 - zoom_amt + zoom * zoom_amt) + 0.5;
    if (!test_rounded_mask(p, corner_size)) {
        return black;
    }
    return getFromColor(p, fromTexture, ratio, _fromR);
}

float4 simple_sample_with_corners_to(float2 p, float2 corner_size, float zoom_amt, float zoom, float ratio, texture2d<float, access::sample> toTexture, float _toR) {
    p = (p - 0.5) / (1.0 - zoom_amt + zoom * zoom_amt) + 0.5;
    if (!test_rounded_mask(p, corner_size)) {
        return black;
    }
    return getToColor(p, toTexture, ratio, _toR);
}


// Basic 2D affine transform matrix helpers
// These really shouldn't be used in a fragment shader - I should work out the
// the math for a translate & rotate function as a pair of dot products instead
float3x3 rotate2d(float angle, float ratio) {
    float s = sin(angle);
    float c = cos(angle);
    return float3x3(float3(c, s ,0.0),
                    float3(-s, c, 0.0),
                    float3(0.0, 0.0, 1.0));
}

float3x3 translate2d(float x, float y) {
    return float3x3(float3(1.0, 0.0, 0),
                    float3(0.0, 1.0, 0),
                    float3(-x, -y, 1.0));
}

float3x3 scale2d(float x, float y) {
    return float3x3(float3(x, 0.0, 0),
                    float3(0.0, y, 0),
                    float3(0, 0, 1.0));
}

// Split an image and rotate one up and one down along off screen pivot points
float4 get_cross_rotated(float3 p3, float angle, float2 corner_size, float ratio, float zoom, texture2d<float, access::sample> fromTexture, float _fromR) {
    angle = angle * angle; // easing
    angle /= 2.4; // works out to be a good number of radians
    
    float3x3 center_and_scale = translate2d(-0.5, -0.5) * scale2d(1.0, ratio);
    float3x3 unscale_and_uncenter = scale2d(1.0, 1.0/ratio) * translate2d(0.5,0.5);
    float3x3 slide_left = translate2d(-2.0,0.0);
    float3x3 slide_right = translate2d(2.0,0.0);
    float3x3 rotate = rotate2d(angle, ratio);
    
    float3x3 op_a = center_and_scale * slide_right * rotate * slide_left * unscale_and_uncenter;
    float3x3 op_b = center_and_scale * slide_left * rotate * slide_right * unscale_and_uncenter;
    
    float4 a = sample_with_corners_from((op_a * p3).xy, corner_size, zoom, ratio, fromTexture, _fromR);
    float4 b = sample_with_corners_from((op_b * p3).xy, corner_size, zoom, ratio, fromTexture, _fromR);
    
    return screen(a, b);
}

// Image stays put, but this time move two masks
float4 get_cross_masked(float3 p3, float angle, float2 corner_size, float ratio, float zoom, texture2d<float, access::sample> toTexture, float _toR) {
    angle = 1.0 - angle;
    angle = angle * angle; // easing
    angle /= 2.4;
    
    float4 img;
    
    float3x3 center_and_scale = translate2d(-0.5, -0.5) * scale2d(1.0, ratio);
    float3x3 unscale_and_uncenter = scale2d(1.0 / zoom, 1.0 / (zoom * ratio)) * translate2d(0.5,0.5);
    float3x3 slide_left = translate2d(-2.0,0.0);
    float3x3 slide_right = translate2d(2.0,0.0);
    float3x3 rotate = rotate2d(angle, ratio);
    
    float3x3 op_a = center_and_scale * slide_right * rotate * slide_left * unscale_and_uncenter;
    float3x3 op_b = center_and_scale * slide_left * rotate * slide_right * unscale_and_uncenter;
    
    bool mask_a = test_rounded_mask((op_a * p3).xy, corner_size);
    bool mask_b = test_rounded_mask((op_b * p3).xy, corner_size);
    
    if (mask_a || mask_b) {
        img = sample_with_corners_to(p3.xy, corner_size, zoom, ratio, toTexture, _toR);
        return screen(mask_a ? img : black, mask_b ? img : black);
    } else {
        return black;
    }
}


fragment float4 StereoViewerFragment(VertexOut vertexIn [[ stage_in ]],
                                     texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                     texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                     constant float & cornerRadius [[ buffer(0) ]],
                                     constant float & zoom [[ buffer(1) ]],
                                     constant float & ratio [[ buffer(2) ]],
                                     constant float & progress [[ buffer(3) ]],
                                     sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float a;
    float2 p = uv.xy/float2(1.0).xy;
    float3 p3 = float3(p.xy, 1.0); // for 2D matrix transforms
    // corner is warped to represent to size after mapping to 1.0, 1.0
    float2 corner_size = float2(cornerRadius / ratio, cornerRadius);
    
    if (progress <= 0.0) {
        // 0.0: start with the base frame always
        return getFromColor(p, fromTexture, ratio, _fromR);
    } else if (progress < 0.1) {
        // 0.0-0.1: zoom out and add rounded corners
        a = progress / 0.1;
        return simple_sample_with_corners_from(p, corner_size * a, a, zoom, ratio, fromTexture, _fromR);
    } else if (progress < 0.48) {
        // 0.1-0.48: Split original image apart
        a = (progress - 0.1)/0.38;
        return get_cross_rotated(p3, a, corner_size, ratio, zoom, fromTexture, _fromR);
    } else if (progress < 0.9) {
        // 0.48-0.52: black
        // 0.52 - 0.9: unmask new image
        return get_cross_masked(p3, (progress - 0.52)/0.38, corner_size, ratio, zoom, toTexture, _toR);
    } else if (progress < 1.0) {
        // zoom out and add rounded corners
        a = (1.0 - progress) / 0.1;
        return simple_sample_with_corners_to(p, corner_size * a, a, zoom, ratio, toTexture, _toR);
    } else {
        // 1.0 end with base frame
        return getToColor(p, toTexture, ratio, _toR);
    }
}


// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

bool swap_inBounds (float2 p) {
    const float2 boundMin = float2(0.0, 0.0);
    const float2 boundMax = float2(1.0, 1.0);
    return all(boundMin < p) && all(p < boundMax);
}

float2 swap_project (float2 p) {
    return p * float2(1.0, -1.2) + float2(0.0, -0.02);
}

fragment float4 SwapFragment(VertexOut vertexIn [[ stage_in ]],
                             texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                             texture2d<float, access::sample> toTexture [[ texture(1) ]],
                             constant float & depth [[ buffer(0) ]],
                             constant float & reflection [[ buffer(1) ]],
                             constant float & perspective [[ buffer(2) ]],
                             constant float & ratio [[ buffer(3) ]],
                             constant float & progress [[ buffer(4) ]],
                             sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 pfr, pto = float2(-1.);
    
    float size = mix(1.0, depth, progress);
    float persp = perspective * progress;
    pfr = (uv + float2(-0.0, -0.5)) * float2(size/(1.0 - perspective*progress), size/(1.0 - size * persp * uv.x)) + float2(0.0, 0.5);
    
    size = mix(1.0, depth, 1.-progress);
    persp = perspective * (1.-progress);
    pto = (uv + float2(-1.0, -0.5)) * float2(size/(1.0-perspective*(1.0-progress)), size/(1.0-size*persp*(0.5-uv.x))) + float2(1.0, 0.5);
    
    if (progress < 0.5) {
        if (swap_inBounds(pfr)) {
            return getFromColor(pfr, fromTexture, ratio, _fromR);
        }
        if (swap_inBounds(pto)) {
            return getToColor(pto, toTexture, ratio, _toR);
        }
    }
    if (swap_inBounds(pto)) {
        return getToColor(pto, toTexture, ratio, _toR);
    }
    if (swap_inBounds(pfr)) {
        return getFromColor(pfr, fromTexture, ratio, _fromR);
    }
    
    const float4 black = float4(0.0, 0.0, 0.0, 1.0);
    float4 c = black;
    pfr = swap_project(pfr);
    if (swap_inBounds(pfr)) {
        c += mix(black, getFromColor(pfr, fromTexture, ratio, _fromR), reflection * mix(1.0, 0.0, pfr.y));
    }
    pto = swap_project(pto);
    if (swap_inBounds(pto)) {
        c += mix(black, getToColor(pto, toTexture, ratio, _toR), reflection * mix(1.0, 0.0, pto.y));
    }
    return c;
}


// License: MIT
// Author: Sergey Kosarevsky
// ( http://www.linderdaum.com )
// ported by gre from https://gist.github.com/corporateshark/cacfedb8cca0f5ce3f7c

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 SwirlFragment(VertexOut vertexIn [[ stage_in ]],
                              texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                              texture2d<float, access::sample> toTexture [[ texture(1) ]],
                              constant float & ratio [[ buffer(0) ]],
                              constant float & progress [[ buffer(1) ]],
                              sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float radius = 1.0;
    float t = progress;
    uv -= float2( 0.5, 0.5 );
    float dist = length(uv);
    
    if (dist < radius) {
        float percent = (radius - dist) / radius;
        float a = (t <= 0.5 ) ? mix( 0.0, 1.0, t/0.5) : mix( 1.0, 0.0, (t-0.5)/0.5 );
        float theta = percent * percent * a * 8.0 * 3.14159;
        float s = sin(theta);
        float c = cos(theta);
        uv = float2(dot(uv, float2(c, -s)), dot(uv, float2(s, c)) );
    }
    uv += float2( 0.5, 0.5 );

    float4 c0 = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 c1 = getToColor(uv, toTexture, ratio, _toR);

    return mix(c0, c1, t);
}


// author: Brandon Anzaldi
// license: MIT

#include <metal_stdlib>

using namespace metalpetal;

// Pseudo-random noise function
// http://byteblacksmith.com/improvements-to-the-canonical-one-liner-glsl-rand-for-opengl-es-2-0/
float noise(float2 co, float progress)
{
    float a = 12.9898;
    float b = 78.233;
    float c = 43758.5453;
    float dt= dot(co.xy * progress, float2(a, b));
    float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

fragment float4 TVStaticFragment(VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                 texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                 constant float & offset [[ buffer(0) ]],
                                 constant float & ratio [[ buffer(1) ]],
                                 constant float & progress [[ buffer(2) ]],
                                 sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    if (progress < offset) {
        return getFromColor(uv, fromTexture, ratio, _fromR);
    } else if (progress > (1.0 - offset)) {
        return getToColor(uv, toTexture, ratio, _toR);
    } else {
        return float4(float3(noise(uv, progress)), 1.0);
    }
}


// License: MIT
// Author: chenkai
// ported from https://codertw.com/%E7%A8%8B%E5%BC%8F%E8%AA%9E%E8%A8%80/671116/

#include <metal_stdlib>

using namespace metalpetal;


// motion blur for texture from
float4 motionBlurFrom(float2 _st, float2 speed, float ratio, texture2d<float, access::sample> fromTexture, float _fromR) {
    float2 texCoord = _st.xy / float2(1.0).xy;
    float3 color = float3(0.0);
    float total = 0.0;
    float offset = rand(_st);
    for (float t = 0.0; t <= 20.0; t++) {
        float percent = (t + offset) / 20.0;
        float weight = 4.0 * (percent - percent * percent);
        float2 newuv = texCoord + speed * percent;
        newuv = fract(newuv);
        color += getFromColor(newuv, fromTexture, ratio, _fromR).rgb * weight;
        total += weight;
    }
    return float4(color / total, 1.0);
}

// motion blur for texture to
float4 motionBlurTo(float2 _st, float2 speed, float ratio, texture2d<float, access::sample> toTexture, float _toR) {
    float2 texCoord = _st.xy / float2(1.0).xy;
    float3 color = float3(0.0);
    float total = 0.0;
    float offset = rand(_st);
    for (float t = 0.0; t <= 20.0; t++) {
        float percent = (t + offset) / 20.0;
        float weight = 4.0 * (percent - percent * percent);
        float2 newuv = texCoord + speed * percent;
        newuv = fract(newuv);
        color += getToColor(newuv, toTexture, ratio, _toR).rgb * weight;
        total += weight;
    }
    return float4(color / total, 1.0);
}

// bezier in gpu
float A(float aA1, float aA2) {
    return 1.0 - 3.0 * aA2 + 3.0 * aA1;
}
float B(float aA1, float aA2) {
    return 3.0 * aA2 - 6.0 * aA1;
}
float C(float aA1) {
    return 3.0 * aA1;
}
float GetSlope(float aT, float aA1, float aA2) {
    return 3.0 * A(aA1, aA2)*aT*aT + 2.0 * B(aA1, aA2) * aT + C(aA1);
}
float CalcBezier(float aT, float aA1, float aA2) {
    return ((A(aA1, aA2)*aT + B(aA1, aA2))*aT + C(aA1))*aT;
}
float GetTForX(float aX, float mX1, float mX2) {
    // iteration to solve
    float aGuessT = aX;
    for (int i = 0; i < 4; ++i) {
        float currentSlope = GetSlope(aGuessT, mX1, mX2);
        if (currentSlope == 0.0) return aGuessT;
        float currentX = CalcBezier(aGuessT, mX1, mX2) - aX;
        aGuessT -= currentX / currentSlope;
    }
    return aGuessT;
}
float KeySpline(float aX, float mX1, float mY1, float mX2, float mY2) {
    if (mX1 == mY1 && mX2 == mY2) return aX; // linear
    return CalcBezier(GetTForX(aX, mX1, mX2), mY1, mY2); // x to t, t to y
}

// norm distribution
float normpdf(float x) {
    return exp(-20.*pow(x-.5,2.));
}

float2 rotateUv(float2 uv, float angle, float2 anchor, float zDirection) {
    uv = uv - anchor; // anchor to origin
    float s = sin(angle);
    float c = cos(angle);
    float2x2 m = float2x2(float2(c, -s),
                          float2(s, c));
    uv = m * uv;
    uv += anchor; // anchor back
    return uv;
}

fragment float4 TangentMotionBlurFragment(VertexOut vertexIn [[ stage_in ]],
                                      texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                      texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                      constant float & ratio [[ buffer(0) ]],
                                      constant float & progress [[ buffer(1) ]],
                                      sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    //float2 iResolution = float2(100.0, 100.0); // screen size

    float2 myst = uv;
    //float resolutionRatio = iResolution.x / iResolution.y; // screen ratio
    float animationTime = progress; //getAnimationTime();
    float easingTime = KeySpline(animationTime, .68,.01,.17,.98);
    float blur = normpdf(easingTime);
    float r = 0.;
    float rotation = 180./180.*3.14159;
    if (easingTime <= .5) {
        r = rotation * easingTime;
    } else {
        r = -rotation + rotation * easingTime;
    }

    // rotation for current frame
    float2 mystCurrent = myst;
    mystCurrent.y *= 1./ratio;
    mystCurrent = rotateUv(mystCurrent, r, float2(1., 0.), -1.);
    mystCurrent.y *= ratio;

    // frame timeInterval by fps=30
    float timeInterval = 0.0167*2.0;
    if (easingTime <= .5) {
        r = rotation * (easingTime+timeInterval);
    } else {
        r = -rotation + rotation * (easingTime+timeInterval);
    }

    // rotation for next frame
    float2 mystNext = myst;
    mystNext.y *= 1./ratio;
    mystNext = rotateUv(mystNext, r, float2(1., 0.), -1.);
    mystNext.y *= ratio;

    // get speed at tagent direction
    float2 speed  = (mystNext - mystCurrent) / timeInterval * blur * 0.5;
    if (easingTime <= .5) {
        return motionBlurFrom(mystCurrent, speed, ratio, fromTexture, _fromR);
    } else {
        return motionBlurTo(mystCurrent, speed, ratio, toTexture, _toR);
    }
}


// Author:zhmy
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

bool topBottomInBounds(float2 p) {
    const float2 boundMin = float2(0.0, 0.0);
    const float2 boundMax = float2(1.0, 1.0);
    return all(boundMin < p) && all(p < boundMax);
}

fragment float4 TopBottomFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & ratio [[ buffer(0) ]],
                               constant float & progress [[ buffer(1) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    float2 spfr,spto = float2(-1.);
    float size = mix(1.0, 3.0, progress*0.2);
    spto = (uv + float2(-0.5,-0.5)) * float2(size,size) + float2(0.5,0.5);
    spfr = (uv + float2(0.0, 1.0 - progress));
    if(topBottomInBounds(spfr)) {
        return getToColor(spfr, toTexture, ratio, _toR);
    } else if(topBottomInBounds(spto)) {
        return getFromColor(spto, fromTexture, ratio, _fromR) * (1.0 - progress);
    } else{
        return float4(0, 0, 0, 1);
    }
}


// License: MIT
// Author: pthrasher
// adapted by gre from https://gist.github.com/pthrasher/8e6226b215548ba12734

#include <metal_stdlib>

using namespace metalpetal;

float quadraticInOut(float t) {
    float p = 2.0 * t * t;
    return t < 0.5 ? p : -p + (4.0 * t) - 1.0;
}

float getGradient(float r, float dist, float smoothness) {
    float d = r - dist;
    return mix(smoothstep(-smoothness, 0.0, r - dist * (1.0 + smoothness)),
               -1.0 - step(0.005, d),
               step(-0.005, d) * step(d, 0.01)
               );
}

float getWave(float2 p, float2 center, float progress){
    float2 _p = p - center; // offset from center
    float rads = atan2(_p.y, _p.x);
    float degs = 180.0 * rads / M_PI_F + 180.0;
//    float2 range = float2(0.0, M_PI * 30.0);
//    float2 domain = float2(0.0, 360.0);
    float ratio = (M_PI * 30.0) / 360.0;
    degs = degs * ratio;
    float x = progress;
    float magnitude = mix(0.02, 0.09, smoothstep(0.0, 1.0, x));
    float offset = mix(40.0, 30.0, smoothstep(0.0, 1.0, x));
    float ease_degs = quadraticInOut(sin(degs));
    float deg_wave_pos = (ease_degs * magnitude) * sin(x * offset);
    return x + deg_wave_pos;
}

fragment float4 UndulatingBurnOutFragment(VertexOut vertexIn [[ stage_in ]],
                                          texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                          texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                          constant float3 & color [[ buffer(0) ]],
                                          constant float & smoothness [[ buffer(1) ]],
                                          constant float2 & center [[ buffer(2) ]],
                                          constant float & ratio [[ buffer(3) ]],
                                          constant float & progress [[ buffer(4) ]],
                                          sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float dist = distance(center, uv);
    float m = getGradient(getWave(uv, center, progress), dist, smoothness);
    float4 cfrom = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 cto = getToColor(uv, toTexture, ratio, _toR);
    return mix(mix(cfrom, cto, m), mix(cfrom, float4(color, 1.0), 0.75), step(m, -2.0));
    
}


// Author: Paweł Płóciennik
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 WaterDropFragment(VertexOut vertexIn [[ stage_in ]],
                                  texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                  texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                  constant float & speed [[ buffer(0) ]],
                                  constant float & amplitude [[ buffer(1) ]],
                                  constant float & ratio [[ buffer(2) ]],
                                  constant float & progress [[ buffer(3) ]],
                                  sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float2 dir = uv - float2(0.5);
    float dist = length(dir);
    
    if (dist > progress) {
        return mix(
                   getFromColor(uv, fromTexture, ratio, _fromR),
                   getToColor(uv, fromTexture, ratio, _toR),
                   progress
                   );
    } else {
        float2 offset = dir * sin(dist * amplitude - progress * speed);
        return mix(
                   getFromColor(uv + offset, fromTexture, ratio, _fromR),
                   getToColor(uv, toTexture, ratio, _toR),
                   progress);
    }
}


// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 WindFragment(VertexOut vertexIn [[ stage_in ]],
                texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                texture2d<float, access::sample> toTexture [[ texture(1) ]],
                constant float & size [[ buffer(0) ]],
                constant float & ratio [[ buffer(1) ]],
                constant float & progress [[ buffer(2) ]],
                sampler textureSampler [[ sampler(0) ]]) 
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    float r = rand(float2(0, uv.y));
    float m = smoothstep(0.0, -size, uv.x*(1.0-size) + size*r - (progress * (1.0 + size)));
    return mix(getFromColor(uv, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               m);
}



// Author: Fabien Benetou
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 WindowBlindsFragment(VertexOut vertexIn [[ stage_in ]],
                texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                texture2d<float, access::sample> toTexture [[ texture(1) ]],
                constant float & ratio [[ buffer(0) ]],
                constant float & progress [[ buffer(1) ]],
                sampler textureSampler [[ sampler(0) ]]) 
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float t = progress;
  
    if (mod(floor(uv.y * 100.0 * progress),2.0) == 0.0) {
        t *= 2.0 - 0.5;
    }
    
    return mix(
               getFromColor(uv, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               mix(t, progress, smoothstep(0.8, 1.0, progress))
               );
}


// Author: gre
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 WindowSliceFragment(VertexOut vertexIn [[ stage_in ]],
                texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                texture2d<float, access::sample> toTexture [[ texture(1) ]],
                constant float & count [[ buffer(0) ]],
                constant float & smoothness [[ buffer(1) ]],
                constant float & ratio [[ buffer(2) ]],
                constant float & progress [[ buffer(3) ]],
                sampler textureSampler [[ sampler(0) ]]) 
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    float pr = smoothstep(-smoothness, 0.0, uv.x - progress * (1.0 + smoothness));
    float s = step(pr, fract(count * uv.x));
    return mix(getFromColor(uv, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               s);
}



// Author: Jake Nelson
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 WipeDownFragment(VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                 texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                 constant float & ratio [[ buffer(0) ]],
                                 constant float & progress [[ buffer(1) ]],
                                 sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    float2 p = uv.xy/float2(1.0).xy;
    float4 a = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 b = getToColor(uv, toTexture, ratio, _toR);
    return mix(a, b, step(1.0 - p.y, progress));
}



// Author: Jake Nelson
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 WipeLeftFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & ratio [[ buffer(0) ]],
                               constant float & progress [[ buffer(1) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    float2 p = uv.xy/float2(1.0).xy;
    float4 a = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 b = getToColor(uv, toTexture, ratio, _toR);
    return mix(a, b, step(1.0 - p.x, progress));
}


// Author: Jake Nelson
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 WipeRightFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & ratio [[ buffer(0) ]],
                               constant float & progress [[ buffer(1) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    float2 p = uv.xy/float2(1.0).xy;
    float4 a = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 b = getToColor(uv, toTexture, ratio, _toR);
    return mix(a, b, step(0.0 + p.x, progress));
}



// Author: Jake Nelson
// License: MIT

#include <metal_stdlib>

using namespace metalpetal;

fragment float4 WipeUpFragment(VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                               texture2d<float, access::sample> toTexture [[ texture(1) ]],
                               constant float & ratio [[ buffer(0) ]],
                               constant float & progress [[ buffer(1) ]],
                               sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());

    float2 p = uv.xy/float2(1.0).xy;
    float4 a = getFromColor(uv, fromTexture, ratio, _fromR);
    float4 b = getToColor(uv, toTexture, ratio, _toR);
    return mix(a, b, step(0.0 + p.y, progress));
}


// License: MIT
// Author: dycm8009
// ported by gre from https://gist.github.com/dycm8009/948e99b1800e81ad909a

#include <metal_stdlib>

using namespace metalpetal;

float2 zoom(float2 uv, float amount) {
    return 0.5 + ((uv - 0.5) * amount);
}

fragment float4 ZoomInCirclesFragment(VertexOut vertexIn [[ stage_in ]],
                                      texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                                      texture2d<float, access::sample> toTexture [[ texture(1) ]],
                                      constant float & ratio [[ buffer(0) ]],
                                      constant float & progress [[ buffer(1) ]],
                                      sampler textureSampler [[ sampler(0) ]])
{
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(toTexture.get_width())/float(toTexture.get_height());
    
    // TODO: some timing are hardcoded but should be one or many parameters
    // TODO: should also be able to configure how much circles
    // TODO: if() branching should be avoided when possible, prefer use of step() & other functions
    float2 ratio2 = float2(1.0, 1.0 / ratio);
    float2 r = 2.0 * ((float2(uv.xy) - 0.5) * ratio2);
    float pro = progress / 0.8;
    float z = pro * 0.2;
    float t = 0.0;
    if (pro > 1.0) {
        z = 0.2 + (pro - 1.0) * 5.;
        t = clamp((progress - 0.8) / 0.07, 0.0, 1.0);
    }
    if (length(r) < 0.5+z) {
        // uv = zoom(uv, 0.9 - 0.1 * pro);
    }
    else if (length(r) < 0.8+z*1.5) {
        uv = zoom(uv, 1.0 - 0.15 * pro);
        t = t * 0.5;
    } else if (length(r) < 1.2+z*2.5) {
        uv = zoom(uv, 1.0 - 0.2 * pro);
        t = t * 0.2;
    } else {
        uv = zoom(uv, 1.0 - 0.25 * pro);
    }
    return mix(
               getFromColor(uv, fromTexture, ratio, _fromR),
               getToColor(uv, toTexture, ratio, _toR),
               t);
}



)mttrawstring";

NSURL * MTTransitionsSwiftPMLibrarySourceURL(void) {
    static NSURL *url;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *targetConditionals = [NSString stringWithFormat:@"#ifndef TARGET_OS_SIMULATOR\n#define TARGET_OS_SIMULATOR %@\n#endif",@(TARGET_OS_SIMULATOR)];
        NSString *librarySource = [targetConditionals stringByAppendingString:[NSString stringWithCString:MTTransitionsBuiltinLibrarySource encoding:NSUTF8StringEncoding]];
        MTLCompileOptions *options = [[MTLCompileOptions alloc] init];
        options.fastMathEnabled = YES;
        url = [MTILibrarySourceRegistration.sharedRegistration registerLibraryWithSource:librarySource compileOptions:options];
    });
    return url;
}
