//
//  AppDelegate.h
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 06.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "SCDesktopSharingWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    SCDesktopSharingWindowController *sharingWindow;
}

@property (nonatomic, readonly) SCDesktopSharingWindowController *sharingWindow;

- (IBAction)showHelp:(id)sender;

@end
