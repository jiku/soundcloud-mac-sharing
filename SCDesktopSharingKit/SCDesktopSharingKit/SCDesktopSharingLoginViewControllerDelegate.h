//
//  SCDesktopSharingLoginViewControllerDelegate.h
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 09.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCDesktopSharingLoginViewController;

@protocol SCDesktopSharingLoginViewControllerDelegate <NSObject>
@optional
- (void)loginViewControllerDidCancel:(SCDesktopSharingLoginViewController *)aLoginViewController;
- (void)loginViewController:(SCDesktopSharingLoginViewController *)aLoginViewController didFailWithError:(NSError *)anError;
- (void)loginViewControllerDidFinish:(SCDesktopSharingLoginViewController *)aLoginViewController;
@end
