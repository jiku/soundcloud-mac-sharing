//
//  SCDesktopSharingSegmentedControl.m
//  SoundCloud Desktop Sharing Kit
//
//  Created by Robert Böhnke on 12/13/11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import "SCDesktopSharingSegmentedControl.h"

#import "NSColor+Hex.h"

@implementation SCDesktopSharingSegmentedCell

@synthesize highlightedSegment;

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.highlightedSegment = NSNotFound;
    }
    return self;
}

- (BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp;
{
    self.highlightedSegment = NSNotFound;
    
    NSPoint location = [controlView convertPoint:event.locationInWindow fromView:nil];
    NSRect  frame    = cellFrame;
    
    for (NSInteger i = 0; i < self.segmentCount; i++) {
        frame.size.width = [self widthForSegment:i];
        if (NSMouseInRect(location, frame, NO)) {
            self.highlightedSegment = i;
            break;
        }
        frame.origin.x += frame.size.width;
    }
    
    [controlView setNeedsDisplay:YES];
    return [super trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag;
{
    self.highlightedSegment = NSNotFound;
    [controlView setNeedsDisplay:YES];
    [super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
}

@end

const CGFloat DesktopSegmentedControlBorderRadius = 5;

@implementation SCDesktopSharingSegmentedControl

+ (Class)cellClass;
{
    return [SCDesktopSharingSegmentedCell class];
}

#pragma mark Life cycle

- (id)initWithFrame:(NSRect)frameRect;
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonAwake];
    }
    return self;
}

-(void)awakeFromNib;
{
    [self commonAwake];
}

- (void)commonAwake;
{
    [SCDesktopSharingSegmentedControl setCellClass:[SCDesktopSharingSegmentedCell class]];
    [self setSegmentStyle:NSSegmentStyleTexturedRounded];
}

#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect;
{
    SInt32 MacVersion;
    
    if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr && MacVersion >= 0x1070) {
        NSRect frame = self.bounds;
        frame.size.height -= 4;

        [self drawBackground:frame];
    } else {
        [super drawRect:dirtyRect];
    }
}

- (void)drawBackground:(NSRect)rect;
{
    rect = NSIntegralRect(rect);
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    NSBezierPath      *path    = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 0.5, 0.5)
                                                                 xRadius:DesktopSegmentedControlBorderRadius
                                                                 yRadius:DesktopSegmentedControlBorderRadius];

    
    NSColor  *borderColor = [NSColor desktop_colorWithRGB:0x838383];
    
    NSShadow *buttonShadow        = [[[NSShadow alloc] init] autorelease];
    buttonShadow.shadowColor      = [NSColor desktop_colorWithRGB:0xCECECE];
    buttonShadow.shadowOffset     = NSMakeSize(0, -1);
    buttonShadow.shadowBlurRadius = 0;
    
    [context saveGraphicsState];
    [buttonShadow set];
    [[NSColor desktop_colorWithRGBA:0xFFFFFFFF] set];
    [path fill];
    [context restoreGraphicsState];
    
    // Clip remaining draw operations
    
    CGFloat segmentWidth  = rect.size.width / self.segmentCount;
    CGFloat segmentHeight = rect.size.height;
    NSRect  segmentFrame  = NSMakeRect(0, 0, segmentWidth, segmentHeight);
    
    [context saveGraphicsState];
    [path setClip];

    for (NSInteger i = 0; i < self.segmentCount; i++) {
        [context saveGraphicsState];

        // Draw background
        NSGradient *gradient = [self gradientForSegment:i];
        [gradient drawInRect:segmentFrame angle:90];
        
        // Draw cell
        [self.cell drawSegment:i inFrame:segmentFrame withView:self];
        
        // Draw seperator
        if (i > 0) {
            NSBezierPath *seperator = [NSBezierPath bezierPath];
            [seperator moveToPoint:NSMakePoint(segmentFrame.origin.x - 0.5,
                                               segmentFrame.origin.y)];
            
            [seperator lineToPoint:NSMakePoint(segmentFrame.origin.x - 0.5,
                                               segmentFrame.origin.y + segmentFrame.size.height)];
            
            seperator.lineWidth = 1;
            
            [borderColor set];
            [seperator stroke];
        }
        
        [context restoreGraphicsState];
        
        segmentFrame.origin.x += segmentWidth;
    }
    
    [context restoreGraphicsState];
    
    // Draw outline
    [context saveGraphicsState];
    [borderColor set];
    [path stroke];
    [context restoreGraphicsState];
}

- (NSGradient *)gradientForSegment:(NSInteger)segment;
{
    if ([self.cell highlightedSegment] == segment) {
        // Highlighted
        if ([self.cell selectedSegment] == segment) {
            if (segment % 2 == 0) {
                // Blue gradient
                NSArray *colors = [NSArray arrayWithObjects:
                                   [NSColor desktop_colorWithRGB:0x0A4394],
                                   [NSColor desktop_colorWithRGB:0x0C4DB9],
                                   [NSColor desktop_colorWithRGB:0x0A4394],
                                   nil];
                
                return [[[NSGradient alloc] initWithColors:colors] autorelease];
            } else {
                // Orange gradient
                NSArray *colors = [NSArray arrayWithObjects:
                                   [NSColor desktop_colorWithRGB:0xEE4908],
                                   [NSColor desktop_colorWithRGB:0xFB4F08],
                                   [NSColor desktop_colorWithRGB:0xEE4F08],
                                   nil];
                
                return [[[NSGradient alloc] initWithColors:colors] autorelease];
            }
        } else {
            NSArray *colors = [NSArray arrayWithObjects:
                               [NSColor desktop_colorWithRGB:0xD2D2D2],
                               [NSColor desktop_colorWithRGB:0xACACAC],
                               nil];
            
            return [[[NSGradient alloc] initWithColors:colors] autorelease];
        }
    } else {
        // Normal
        if ([self.cell selectedSegment] == segment) {
            if (segment % 2 == 0) {
                // Blue gradient
                NSArray *colors = [NSArray arrayWithObjects:
                                   [NSColor desktop_colorWithRGB:0x0A4394],
                                   [NSColor desktop_colorWithRGB:0x0C4DB9],
                                   [NSColor desktop_colorWithRGB:0x0A4394],
                                   nil];
                
                return [[[NSGradient alloc] initWithColors:colors] autorelease];
            } else {
                // Orange gradient
                NSArray *colors = [NSArray arrayWithObjects:
                                   [NSColor desktop_colorWithRGB:0xEE4908],
                                   [NSColor desktop_colorWithRGB:0xFB4F08],
                                   [NSColor desktop_colorWithRGB:0xEE4F08],
                                   nil];
                
                return [[[NSGradient alloc] initWithColors:colors] autorelease];
            }
        } else {
            NSArray *colors = [NSArray arrayWithObjects:
                               [NSColor desktop_colorWithRGB:0xF5F5F5],
                               [NSColor desktop_colorWithRGB:0xCFCFCF],
                               nil];
            
            return [[[NSGradient alloc] initWithColors:colors] autorelease];
        }
    }
}

@end
