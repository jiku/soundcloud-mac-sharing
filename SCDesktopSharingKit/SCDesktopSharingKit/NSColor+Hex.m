//
//  NSColor+Hex.m
//  SoundCloud Desktop Sharing Kit
//
//  Created by Robert Böhnke on 12/13/11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import "NSColor+Hex.h"

@implementation NSColor (Hex)

+ (NSColor *)desktop_colorWithRGB:(NSUInteger)hex;
{
    return [NSColor desktop_colorWithRGBA:(hex << 8) | 0xFF];
}

+ (NSColor *)desktop_colorWithRGBA:(NSUInteger)hex;
{
    NSUInteger r = (hex & 0xFF000000) >> 24;
    NSUInteger g = (hex & 0x00FF0000) >> 16;
    NSUInteger b = (hex & 0x0000FF00) >> 8;
    NSUInteger a = (hex & 0x000000FF);
    
    return [NSColor colorWithCalibratedRed:r / 255.0
                                     green:g / 255.0
                                      blue:b / 255.0
                                     alpha:a / 255.0];
}

@end
