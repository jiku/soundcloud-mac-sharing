//
//  SCDesktopSharingLoginViewController.h
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 09.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SCDesktopSharingLoginViewControllerDelegate.h"

@class WebView;

@interface SCDesktopSharingLoginViewController : NSViewController {
    BOOL requestingAccess;
    
    id<SCDesktopSharingLoginViewControllerDelegate> delegate;
    WebView *webView;
    NSProgressIndicator *spinner;
}

#pragma mark Accessors
@property (nonatomic, assign) id<SCDesktopSharingLoginViewControllerDelegate> delegate;

#pragma mark Actions
- (IBAction)requestAccess:(id)sender;
@end
