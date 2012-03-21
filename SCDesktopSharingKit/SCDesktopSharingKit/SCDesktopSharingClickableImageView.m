//
//  SCDesktopSharingClickableImageView.m
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 15.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import "SCDesktopSharingClickableImageView.h"

@implementation SCDesktopSharingClickableImageView

@synthesize clickAction;

- (void)mouseUp:(NSEvent *)event;
{
    // Do nothing
}

- (void)mouseDown:(NSEvent *)event;
{
    if ([event type] == NSLeftMouseDown  /*&& [event clickCount] > 1*/) {
        [[self target] performSelector:[self clickAction] withObject:self];
    }
}

- (void)drawRect:(NSRect)dirtyRect;
{
    [super drawRect:dirtyRect];
    
    if (!self.image) {
        NSImage *cloud = [NSImage imageNamed:@"cloud_wbg"];
        [cloud drawInRect:NSInsetRect(self.bounds, 9, 9)
                 fromRect:NSZeroRect
                operation:NSCompositeSourceOver
                 fraction:1];

    }
}

@end
