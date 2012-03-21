//
//  SCDesktopSharingUploadViewControllerDelegate.h
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 09.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCDesktopSharingUploadViewController;

@protocol SCDesktopSharingUploadViewControllerDelegate <NSObject>
@optional
- (void)uploadViewControllerDidCancel:(SCDesktopSharingUploadViewController *)anUploadViewController;
- (void)uploadViewController:(SCDesktopSharingUploadViewController *)anUploadViewController didChangeArtwork:(NSImage *)anArtwork;
- (void)uploadViewController:(SCDesktopSharingUploadViewController *)anUploadViewController didChangeTitle:(NSString *)aTitle;
- (void)uploadViewController:(SCDesktopSharingUploadViewController *)anUploadViewController didUploadSound:(NSDictionary *)tarckInfo;
- (void)uploadViewController:(SCDesktopSharingUploadViewController *)anUploadViewController didFailWithError:(NSError *)anError;
@end
