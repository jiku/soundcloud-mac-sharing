//
//  SCDesktopSharingClickableImageView.h
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 15.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface SCDesktopSharingClickableImageView : NSImageView {
    SEL clickAction;
}

@property (nonatomic, assign) SEL clickAction;

@end
