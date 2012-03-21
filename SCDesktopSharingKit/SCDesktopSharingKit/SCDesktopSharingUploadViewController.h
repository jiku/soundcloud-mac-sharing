//
//  SCDesktopSharingUploadViewController.h
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 09.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SCDesktopSharingUploadViewControllerDelegate.h"

@class PMProgressIndicator;
@class SCDesktopSharingClickableImageView;

@interface SCDesktopSharingUploadViewController : NSViewController {
     
    id<SCDesktopSharingUploadViewControllerDelegate> delegate;
    
    NSURL *fileURL;
    NSString *title;
    NSArray *tags;
    NSString *license;
    NSImage *artwork;
    BOOL public;
    NSDictionary *parameters;
    
    NSError *uploadError;
    BOOL uploadSucceeded;
    
    NSDictionary *trackInfo;
    
    BOOL loadingConnections;
    NSArray *availableConnections;
    NSArray *unconnectedServices;
    NSArray *sharingConnections;
    
    SCRequest *request; // assign
    
    NSView *uploadProgressView;
    NSView *privacySettingPublic;
    NSTableView *connectionTableView;
    NSView *privacySettingPrivate;
    NSView *uploadSuccessView;
    PMProgressIndicator *uploadProgressIndicator;
    NSTextField *uploadLabel;
    NSTextField *successLabel;
    NSButton *trackLinkCopyButton;
    NSButton *trackLinkOpenButton;
    NSView *metadataView;
    NSTextField *titleField;
    NSTokenField *tagsField;
    NSPopUpButton *licenseSelection;
    SCDesktopSharingClickableImageView *artworkView;
    NSSegmentedControl *privacySwitch;
    NSView *privacySetting;
    NSButton *logoutButton;
    NSButton *uploadButton;
    NSButton *cancelButton;
    NSImageView *avatarImageView;
    NSTextField *userNameLabel;
    NSBox *box;
}

#pragma mark Accessors

@property (nonatomic, assign) id<SCDesktopSharingUploadViewControllerDelegate> delegate;

@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSArray *tags;
@property (nonatomic, retain) NSString *license;
@property (nonatomic, retain) NSImage *artwork;
@property (nonatomic, assign, getter = isPublic) BOOL public;
@property (nonatomic, retain) NSDictionary *parameters;

@property (nonatomic, retain) NSError *uploadError;
@property (nonatomic, readonly) BOOL uploadSucceeded;

@property (nonatomic, retain) NSDictionary *trackInfo;


#pragma mark Interface Elements

@property (assign) IBOutlet NSButton *logoutButton;
@property (assign) IBOutlet NSButton *uploadButton;
@property (assign) IBOutlet NSButton *cancelButton;

@property (assign) IBOutlet NSImageView *avatarImageView;
@property (assign) IBOutlet NSTextField *userNameLabel;

@property (assign) IBOutlet NSBox *box;

// meta data
@property (assign) IBOutlet NSView *metadataView;
@property (assign) IBOutlet NSTextField *titleField;
@property (assign) IBOutlet NSTokenField *tagsField;
@property (assign) IBOutlet NSPopUpButton *licenseSelection;
@property (assign) IBOutlet SCDesktopSharingClickableImageView *artworkView;
@property (assign) IBOutlet NSSegmentedControl *privacySwitch;
@property (assign) IBOutlet NSView *privacySetting;

// meta data - private
@property (assign) IBOutlet NSView *privacySettingPrivate;

// meta data - public
@property (assign) IBOutlet NSView *privacySettingPublic;
@property (assign) IBOutlet NSTableView *connectionTableView;

// upload progress
@property (assign) IBOutlet NSView *uploadProgressView;
@property (assign) IBOutlet NSTextField *uploadLabel;
@property (assign) IBOutlet PMProgressIndicator *uploadProgressIndicator;

// upload success
@property (assign) IBOutlet NSView *uploadSuccessView;
@property (assign) IBOutlet NSTextField *successLabel;
@property (assign) IBOutlet NSButton *trackLinkCopyButton;
@property (assign) IBOutlet NSButton *trackLinkOpenButton;

#pragma mark Actions

- (IBAction)logout:(id)sender;
- (IBAction)upload:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)copyTrackLink:(id)sender;
- (IBAction)addArtwork:(id)sender;
- (IBAction)dropArtwork:(id)sender;
- (IBAction)privacyChanged:(id)sender;
- (IBAction)openLink:(id)sender;
- (IBAction)showConnections:(id)sender;
- (IBAction)showLicenseHelp:(id)sender;
- (IBAction)licenseChanged:(id)sender;

@end
