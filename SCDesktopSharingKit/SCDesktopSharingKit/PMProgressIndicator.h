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


#import <Cocoa/Cocoa.h>

@interface PMProgressIndicator : NSProgressIndicator
{
    IBOutlet NSTextField *progressText;
    
    NSDate *startTime;
    NSDate *startTime2;
    
    BOOL drawDockProgress;
    BOOL alreadyBounced;
    BOOL displayPercentage;
    BOOL displayTimeRemaining;
    double startFraction;
    double startFraction2;
    int lastValue;
}


- (void)updateProgressText;

//accessors

//set whether the progressbar draws itself in the dock, default is YES
- (void)setDrawDockProgress:(BOOL)newDrawDockProgress;
- (BOOL)drawDockProgress;
//set whether to display an estimate of the time remaining in the textField, default is YES
- (void)setDisplayPercentage:(BOOL)newDisplayPercentage;
- (BOOL)displayPercentage;
//set whether to display an estimate of the percentage done in the textField, default is NO
- (void)setDisplayTimeRemaining:(BOOL)newDisplayTimeRemaining;
- (BOOL)displayTimeRemaining;

@end
