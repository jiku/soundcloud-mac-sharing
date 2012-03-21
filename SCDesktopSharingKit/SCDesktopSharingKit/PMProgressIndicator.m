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


#import "PMProgressIndicator.h"
#import "PMProgressIndicatorController.h"

#define UPDATE_SPEED_CALCULATIONS 7.0
#define MINIMUM_TIME_SPENT 0.5

@implementation PMProgressIndicator

- (id)init {

    self = [super init];

    return self;
}

- (void)dealloc {
    [self setDrawDockProgress:NO]; //removes the object from the controller
    
    if(startTime){
        [startTime release];
    }

    [super dealloc];
}

//these things don't work in init, because of nib-stuff
- (void)awakeFromNib
{
    drawDockProgress = YES;
    displayPercentage = NO;
    displayTimeRemaining = YES;
    alreadyBounced = NO;

    lastValue = 0;
}

//overwrite to set DockIcon
- (void)setDoubleValue:(double)doubleValue
{
    double fractionDone;

    //progress is jittery with very small updates, so do not update too often, also saves some cycles
    int intValue = (int)doubleValue + 0.5;
    if(intValue != lastValue){
        [super setDoubleValue:doubleValue];

        lastValue = intValue;
        
        if(drawDockProgress){
            //add it again, though this may be redundant
            [[PMProgressIndicatorController sharedInstance] addProgressIndicator:self];
            
            fractionDone = (doubleValue - [self minValue]) / ([self maxValue] - [self minValue]);
            //restore dockIcon if (almost) ready, or if a value of zero/minValue is sent (to reset)
            if(fractionDone > ([self maxValue] - 0.00001) || fractionDone < ([self minValue] + 0.00001)){
                [[PMProgressIndicatorController sharedInstance] removeProgressIndicator:self];
            }
        }
        
        //update the description of the time remaining
        if(progressText){
            [self updateProgressText];
        }

    }
    
}


- (void)updateProgressText
{
    double doubleValue, timeLeft, timeSpent, fractionDone, progressPerSecond;
    NSString *timeLeftString = nil;

    //not necessary if barberpole
    if([self isIndeterminate]){
        [progressText setStringValue:@""];
        return;
    }

    doubleValue = [self doubleValue];
    
    if(doubleValue < ([self minValue] + 0.00001)){ //the text can be reset by sending a value of zero/minValue
        if(startTime){
            [startTime release];
        }
        startTime = nil;
        if(startTime2){
            [startTime2 release];
        }
        startTime2 = nil;
    }
    
    //system to keep updating the calculations, so that the calculation speed is always based on the last 10-15 seconds
    //This can be tweaked a bit using #define UPDATE_SPEED_CALCULATIONS)
    //if first time that the value is given (or after reset), save the startTime and the startFraction
    if(startTime == nil){
        startTime = [[NSDate date] retain];
        startFraction = doubleValue / [self maxValue];
        [progressText setStringValue:@""];
    }
    //if the current startTime is more than five seconds old, make another one
    if(fabs([startTime timeIntervalSinceNow]) > 0.5 * UPDATE_SPEED_CALCULATIONS && startTime2 == nil){
        startTime2 = [[NSDate date] retain];
        startFraction2 = doubleValue / [self maxValue];
    }
    //if startTime2 is more than five seconds old, swap the startTime for startTime2
    if(startTime2 != nil && fabs([startTime2 timeIntervalSinceNow]) > 0.5 * UPDATE_SPEED_CALCULATIONS){
        [startTime release];
        startTime = startTime2;
        startTime2 = nil;
        startFraction = startFraction2;
    }

    timeSpent = fabs([startTime timeIntervalSinceNow]);
    fractionDone = (doubleValue - [self minValue]) / ([self maxValue] - [self minValue]);
    
    //only update if some time has passed (MINIMUM_TIME_SPENT), otherwise we get huuuuge numbers
    if(displayTimeRemaining && timeSpent > MINIMUM_TIME_SPENT){
        progressPerSecond = (fractionDone - startFraction) / timeSpent;
        timeLeft = (1.0 - fractionDone) / progressPerSecond;
        
        //make it into a nice human readable string, don't round too optimistically
        //users like it better if an anlysis takes shorter than expected, than if it takes longer than expected
        if(timeLeft > 615){ //more than about one minute
            timeLeftString = [NSString stringWithFormat:@"About %d minutes remaining", (int) ((timeLeft / 60.0) + 0.75)];
        }
        else if(timeLeft > 555){
            timeLeftString = @"About ten minutes remaining";
        }
        else if(timeLeft > 495){
            timeLeftString = @"About nine minutes remaining";
        }
        else if(timeLeft > 435){
            timeLeftString = @"About eight minutes remaining";
        }
        else if(timeLeft > 375){
            timeLeftString = @"About seven minutes remaining";
        }
        else if(timeLeft > 315){
            timeLeftString = @"About six minutes remaining";
        }
        else if(timeLeft > 255){
            timeLeftString = @"About five minutes remaining";
        }
        else if(timeLeft > 195){
            timeLeftString = @"About four minutes remaining";
        }
        else if(timeLeft > 135){
            timeLeftString = @"About three minutes remaining";
        }
        else if(timeLeft > 75){
            timeLeftString = @"About two minutes remaining";
        }
        else if(timeLeft > 50){
            timeLeftString = @"About one minute remaining";
        }
        else if(timeLeft > 10){ //be more strict with small intervals
            timeLeftString = @"Less than a minute remaining";
        }
        else if(timeLeft > 5){
            timeLeftString = @"About ten seconds remaining";
        }
        else{
            timeLeftString = @"About five seconds remaining";
        }
    }
    
    if(displayPercentage && displayTimeRemaining && timeSpent > MINIMUM_TIME_SPENT){
        [progressText setStringValue:[NSString stringWithFormat:@"%.0f %% completed - %@", 100.0 * fractionDone, timeLeftString]];
    }
    else if(displayPercentage){
        [progressText setStringValue:[NSString stringWithFormat:@"%.0f %% completed", 100.0 * fractionDone]];
    }
    else if(displayTimeRemaining && timeSpent > MINIMUM_TIME_SPENT){
        [progressText setStringValue:timeLeftString];
    }
}

//also redraw text and dockIcon when displaying
- (void)display
{
    if(drawDockProgress){
        [[PMProgressIndicatorController sharedInstance] drawProgressIndicators];
    }
    if(progressText){
        [progressText display];
    }
    
    [super display];
}

#pragma mark -
#pragma mark ACESSORS


- (void)setDrawDockProgress:(BOOL)newDrawDockProgress
{
    drawDockProgress = newDrawDockProgress;

    if(drawDockProgress){
        [[PMProgressIndicatorController sharedInstance] addProgressIndicator:self];
    }
    else{
        [[PMProgressIndicatorController sharedInstance] removeProgressIndicator:self];
    }
}

- (BOOL)drawDockProgress
{
    return drawDockProgress;
}

- (void)setDisplayPercentage:(BOOL)newDisplayPercentage
{
    displayPercentage = newDisplayPercentage;
}

- (BOOL)displayPercentage
{
    return displayPercentage;
}

- (void)setDisplayTimeRemaining:(BOOL)newDisplayTimeRemaining
{
    displayTimeRemaining = newDisplayTimeRemaining;
}

- (BOOL)displayTimeRemaining
{
    return displayTimeRemaining;
}

@end
