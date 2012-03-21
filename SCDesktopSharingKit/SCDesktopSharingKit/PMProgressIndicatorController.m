// Copyright (c) 2007, Patrick Meirmans
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the <organization> nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY PATRICK MEIRMANS ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "PMProgressIndicatorController.h"
#import "PMProgressIndicator.h"

#define SPEED 1.5
#define SPINPIXELS 32.0
#define ICONSIZE 128.0
#define BARHEIGHT 14.0
#define SPACING 2.0


@implementation PMProgressIndicatorController

#pragma mark -
#pragma mark Life history

//every program needs only a single controller
+ (PMProgressIndicatorController *) sharedInstance
{
    static PMProgressIndicatorController    *sharedInstance = nil;

    if (sharedInstance == nil)
    {
        sharedInstance = [[self alloc] init];
    }

    return sharedInstance;
}


- (id)init
{
    self = [super init];

    progressIndicators = [[NSMutableArray alloc] init];

    dockIcon = [[NSApp applicationIconImage] copy];
    NSBundle *bundle = [NSBundle mainBundle];
    blueBar = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"blueProgress" ofType:@"tif"]];
    greyBar = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"greyProgress" ofType:@"tif"]];
    barberBar = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"barberProgress" ofType:@"tif"]];
    lastSpin = [[NSDate date] retain];
    
    return self;
}

- (void)dealloc {
    [progressIndicators release];
    [dockIcon release];
    [blueBar release];
    [greyBar release];
    [barberBar release];
    [lastSpin release];
    
    if(theTimer){
        [theTimer invalidate];
        theTimer = nil;
    }
        
    [super dealloc];
}

#pragma mark -
#pragma mark Drawing the dock icon


-(void)drawProgressIndicators
{
    //cancel any scheduled requests to perform this method
    //this prevents that it is being called rediculously often, especially when there is a barberpole
    [NSRunLoop cancelPreviousPerformRequestsWithTarget:self selector:@selector(drawProgressIndicators) object:self];

    int i;
    BOOL anyIndeterminate = NO;
    BOOL draw = YES;
    
    //It may be nice to give your users a preference in the user defaults e.g.:
    //if([[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"displayDockProgress"] != nil){
    //    draw = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"displayDockProgress"] boolValue];
    //}

    if(theTimer){
        [theTimer invalidate];
        theTimer = nil;
    }
    
    PMProgressIndicator *indicator;
    NSPoint point;
    
    //use a copy of the original appIcon rather than fetch the current one
    NSImage *mainIcon = [[dockIcon copy] autorelease];
    
    double scaleFactor = mainIcon.size.width / ICONSIZE;

    //only draw bars if necessary
    if(draw && [progressIndicators count] > 0){
        //Lock image ops onto the default icon.
        [mainIcon lockFocus];

        //loop over all indicators, only draw as many as fit onto the icon
        NSEnumerator *enumerator = [progressIndicators objectEnumerator];
        i = 0;
        while(indicator = [enumerator nextObject]){
            float yCoord = (i * (BARHEIGHT * scaleFactor + SPACING * scaleFactor));

            if([indicator isIndeterminate]){
                //for the barberpole to work, there should always be the image "barberProgress.tif"
            
                anyIndeterminate = YES;
                //get time difference since last draw
                double spin = SPINPIXELS * scaleFactor;
                double diff = fabs([lastSpin timeIntervalSinceNow]);
                
                diff -= (int)diff; //get only miliseconds
                        
                //shift the x-coordinate a bit so that it looks like the barberpole has spun a bit further
                //the amount is determined by the time difference since last draw, for smoother animation
                spin -= (SPEED * diff * SPINPIXELS * scaleFactor);
                if(spin < 0.0){
                    spin = SPINPIXELS * scaleFactor + spin;
                }
                point = NSMakePoint(0.0 - spin, yCoord);
                [barberBar compositeToPoint:point operation:NSCompositeSourceOver];
                
                [lastSpin release];
                lastSpin = [[NSDate date] retain];
            }
            else{
                //get the point where blue turns into grey
                float barWidth = (float) (ICONSIZE * scaleFactor * [indicator doubleValue]) / ([indicator maxValue] - [indicator minValue]);
                float whiteWidth = ICONSIZE * scaleFactor - barWidth;
                
                 //if the correct images are available, use them (greyProgress.tif & blueProgress.tif)
                if(blueBar != nil && greyBar != nil){
                    //composite the progress indicator image onto the dock icon.
                    point = NSMakePoint((barWidth - ICONSIZE * scaleFactor), yCoord);
                    [blueBar compositeToPoint:point operation:NSCompositeSourceOver];
                    point.x = barWidth;
                    [greyBar compositeToPoint:point operation:NSCompositeSourceOver];
                }
                //if no images are available, draw a small bar ourselves (with a little transparency for added effects)
                else{
                    //bluish part of the bar
                    [[NSColor colorWithDeviceRed:(129.0/255.0) green:(204.0/255.0) blue:(255.0/255.0) alpha:0.78] set];
                    [NSBezierPath fillRect:NSMakeRect(0, yCoord, barWidth, 11 * scaleFactor)];
                    
                    [[NSColor colorWithDeviceRed:(105.0/255.0) green:(183.0/255.0) blue:(255.0/255.0) alpha:0.78] set];
                    [NSBezierPath fillRect:NSMakeRect(0, yCoord+3 * scaleFactor, barWidth, 6 * scaleFactor)];
                    
                    [[NSColor colorWithDeviceRed:(94.0/255.0) green:(171.0/255.0) blue:(254.0/255.0) alpha:0.78] set];
                    [NSBezierPath fillRect:NSMakeRect(0, yCoord+4 * scaleFactor, barWidth, 4 * scaleFactor)];
                    
                    [[NSColor colorWithDeviceRed:(76.0/255.0) green:(148.0/255.0) blue:(229.0/255.0) alpha:0.78] set];
                    [NSBezierPath fillRect:NSMakeRect(0, yCoord+5 * scaleFactor, barWidth, 2 * scaleFactor)];

                    [[NSColor colorWithDeviceRed:(94.0/255.0) green:(147.0/255.0) blue:(213.0/255.0) alpha:0.78] set];
                    [NSBezierPath fillRect:NSMakeRect(0, yCoord+11 * scaleFactor, barWidth, 1 * scaleFactor)];

                    [[NSColor colorWithDeviceRed:(59.0/255.0) green:(120.0/255.0) blue:(185.0/255.0) alpha:0.78] set];
                    [NSBezierPath fillRect:NSMakeRect(0, yCoord+12 * scaleFactor, barWidth, 1 * scaleFactor)];

                    //whitish part of bar
                    [[NSColor colorWithDeviceRed:(241.0/255.0) green:(241.0/255.0) blue:(241.0/255.0) alpha:0.78] set];
                    [NSBezierPath fillRect:NSMakeRect(barWidth, yCoord, whiteWidth, 11 * scaleFactor)];
                    
                    [[NSColor colorWithDeviceRed:(228.0/255.0) green:(228.0/255.0) blue:(228.0/255.0) alpha:0.78] set];
                    [NSBezierPath fillRect:NSMakeRect(barWidth, yCoord+3 * scaleFactor, whiteWidth, 6 * scaleFactor)];
                    
                    [[NSColor colorWithDeviceRed:(210.0/255.0) green:(210.0/255.0) blue:(210.0/255.0) alpha:0.78] set];
                    [NSBezierPath fillRect:NSMakeRect(barWidth, yCoord+4 * scaleFactor, whiteWidth, 4 * scaleFactor)];
                    
                    [[NSColor colorWithDeviceRed:(200.0/255.0) green:(200.0/255.0) blue:(200.0/255.0) alpha:0.78] set];
                    [NSBezierPath fillRect:NSMakeRect(barWidth, yCoord+5 * scaleFactor, whiteWidth, 2 * scaleFactor)];
                    
                    [[NSColor colorWithDeviceRed:(200.0/255.0) green:(210.0/255.0) blue:(210.0/255.0) alpha:0.78] set];
                    [NSBezierPath fillRect:NSMakeRect(barWidth, yCoord+11 * scaleFactor, whiteWidth, 1 * scaleFactor)];
                    
                    [[NSColor colorWithDeviceRed:(160.0/255.0) green:(160.0/255.0) blue:(160.0/255.0) alpha:0.78] set];
                    [NSBezierPath fillRect:NSMakeRect(barWidth, yCoord+12 * scaleFactor, whiteWidth, 1 * scaleFactor)];
                }
            }
            i++;
        }
        [mainIcon unlockFocus];

        //use timer to animate when any indicators are indeterminate
        if(anyIndeterminate){
            [self performSelector:@selector(drawProgressIndicators) withObject:self afterDelay:0.1];
        }
    }
    
    //Replace the dock icon with the image that may contain the progress bar.
    //NSAutoreleasePool is necessary to prevent some AppKit bug (IIRC)
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSApp setApplicationIconImage:mainIcon];
    [pool release];

}

//draws the original icon; if something goes wrong, call this method
- (IBAction)restoreIcon:(id)sender
{
    //the autoreleasepool is necessary because of a Cocoa bug
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSApp setApplicationIconImage:dockIcon];
    [pool release];
}


#pragma mark -
#pragma mark Handling progress indicators


- (NSUInteger)numProgressIndicators
{
    return [progressIndicators count];
}

- (void)addProgressIndicator:(PMProgressIndicator *)theProgress
{
    if(![progressIndicators containsObject:theProgress]){
        [progressIndicators addObject:theProgress];
    }
    [self performSelector:@selector(drawProgressIndicators) withObject:self afterDelay:0.1]; //only redraw after a delay, prevents drawing too often
}

- (void)removeProgressIndicator:(PMProgressIndicator *)theProgress
{
    [progressIndicators removeObject:theProgress];
    [self performSelector:@selector(drawProgressIndicators) withObject:self afterDelay:0.1]; //only redraw after a delay, prevents drawing too often
}



@end
