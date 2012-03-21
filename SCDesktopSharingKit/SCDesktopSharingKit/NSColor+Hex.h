//
//  NSColor+Hex.h
//  SoundCloud Desktop Sharing Kit
//
//  Created by Robert Böhnke on 12/13/11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSColor (Hex)

+ (NSColor *)desktop_colorWithRGB:(NSUInteger)hex;
+ (NSColor *)desktop_colorWithRGBA:(NSUInteger)hex;

@end
