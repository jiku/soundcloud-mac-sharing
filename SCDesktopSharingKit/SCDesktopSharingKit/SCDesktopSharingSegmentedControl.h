//
//  SCDesktopSharingSegmentedControl.h
//  SoundCloud Desktop Sharing Kit
//
//  Created by Robert Böhnke on 12/13/11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface SCDesktopSharingSegmentedCell : NSSegmentedCell {
    NSInteger highlightedSegment;
}

@property(assign) NSInteger highlightedSegment;

@end

@interface SCDesktopSharingSegmentedControl : NSSegmentedControl

- (void)commonAwake;

- (void)drawBackground:(NSRect)dirtyRect;

- (NSGradient *)gradientForSegment:(NSInteger)segment;

@end
