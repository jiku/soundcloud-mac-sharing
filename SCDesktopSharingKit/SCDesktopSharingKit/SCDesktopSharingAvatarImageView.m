//
//  SCDesktopSharingAvatarImageView.m
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 15.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import "SCDesktopSharingAvatarImageView.h"

@implementation SCDesktopSharingAvatarImageView

- (void)drawRect:(NSRect)dirtyRect;
{
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    
    NSRect rect = self.bounds;
    NSRect highlightRect = rect;
    highlightRect.origin.y -= 1;

    NSBezierPath      *clipPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 0.5, 0.5) xRadius:4 yRadius:4];
    NSBezierPath      *highlightPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(highlightRect, 0.5, 0.5) xRadius:4 yRadius:4];
    highlightPath.lineWidth = 2;
    
    NSBezierPath      *borderPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 0.5, 0.5) xRadius:4 yRadius:4];
    
    [context saveGraphicsState];
    [clipPath setClip];
    [self.image drawInRect:rect fromRect:NSMakeRect(0, 0, self.image.size.width, self.image.size.height)
                 operation:NSCompositeSourceOver
                  fraction:1];
    
    [[NSColor colorWithDeviceWhite:1 alpha:0.5] setStroke];
    [highlightPath stroke];
    
    [context restoreGraphicsState];
    
    [context saveGraphicsState];
    
    [[NSColor colorWithDeviceWhite:0.2 alpha:1] setStroke];
    [borderPath stroke];
    
    [context restoreGraphicsState];
}

@end
