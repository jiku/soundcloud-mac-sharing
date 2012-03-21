//
//  SCDesktopSharingWindowController.h
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 08.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class SCDesktopSharingLoginViewController;
@class SCDesktopSharingUploadViewController;

@interface SCDesktopSharingWindowController : NSWindowController {
    
    NSView *view;
    
    SCDesktopSharingLoginViewController  *loginViewController;
    SCDesktopSharingUploadViewController *uploadViewController;
}

@property (nonatomic, readonly) SCDesktopSharingLoginViewController  *loginViewController;
@property (nonatomic, readonly) SCDesktopSharingUploadViewController *uploadViewController;

@property (assign) IBOutlet NSView *view;

@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSArray *tags;
@property (nonatomic, retain) NSString *license;
@property (nonatomic, retain) NSImage *artwork;
@property (nonatomic, retain) NSDictionary *parameters;

@end
