//
//  SCDesktopSharingLinkStyleButton.m
//  SoundCloud Desktop Sharing Kit
//
//  Created by Robert Böhnke on 12/15/11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import "SCDesktopSharingLinkStyleButton.h"
#import "NSColor+Hex.h"

@interface SCDesktopSharingLinkStyleButton ()

- (void) commonAwake;

@end

@implementation SCDesktopSharingLinkStyleButton

- (id)initWithFrame:(NSRect)frameRect;
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonAwake];
    }
    return self;
}

- (void)dealloc;
{
    [self removeTrackingArea:trackingArea];
    [trackingArea release];
    [super dealloc];
}

- (void)awakeFromNib;
{
    [self commonAwake];
}

- (void)commonAwake;
{
    [self setBordered:NO];
    
    trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                  owner:self
                                               userInfo:nil];
    
    [self addTrackingArea:trackingArea];
    
    NSMutableAttributedString *mutableCopy = [[[self attributedTitle] mutableCopy] autorelease];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUnderlineStyleSingle]
                                                           forKey:NSUnderlineStyleAttributeName];
    
    [mutableCopy addAttributes:attributes range:NSMakeRange(0, mutableCopy.length)];
    
    [super setAttributedTitle:mutableCopy];
    [self.cell setHighlightsBy:NSNoCellMask];
    [self.cell setShowsStateBy:NSNoCellMask];
}

- (void)setTitle:(NSString *)aString;
{
    [super setTitle:aString];
    
    NSMutableAttributedString *title = [[[self attributedTitle] mutableCopy] autorelease];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUnderlineStyleSingle]
                                                           forKey:NSUnderlineStyleAttributeName];
    
    [title addAttributes:attributes range:NSMakeRange(0, title.length)];
    
    [self setAttributedTitle:title];
}

- (void)setAttributedTitle:(NSAttributedString *)aString;
{
    NSMutableAttributedString *mutableCopy = [[aString mutableCopy] autorelease];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUnderlineStyleSingle]
                                                           forKey:NSUnderlineStyleAttributeName];
    
    [mutableCopy addAttributes:attributes range:NSMakeRange(0, mutableCopy.length)];
    
    [super setAttributedTitle:mutableCopy];
}

- (void)resetCursorRects;
{
    [self addCursorRect:self.visibleRect
                 cursor:[NSCursor pointingHandCursor]];
}

- (void)mouseEntered:(NSEvent *)theEvent;
{

}

- (void)mouseExited:(NSEvent *)theEvent;
{

}


@end
