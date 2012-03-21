//
//  SCDesktopSharingWindowController.m
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 08.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <SoundCloudAPI/SCAPI.h>
#import <JSONKIT/JSONKit.h>
#import <OAuth2Client/NSURL+NXOAuth2.h>
#import <OAuth2Client/NXOAuth2.h>

#import "SCDesktopSharingLoginViewController.h"
#import "SCDesktopSharingLoginViewControllerDelegate.h"

#import "SCDesktopSharingUploadViewController.h"
#import "SCDesktopSharingUploadViewControllerDelegate.h"

#import "SCDesktopSharingWindowController.h"

const NSSize DesktopSharingWindowControllerLogInSize  = {410, 580};
const NSSize DesktopSharingWindowControllerUploadSize = {670, 400};

@interface SCDesktopSharingWindowController () <SCDesktopSharingLoginViewControllerDelegate, SCDesktopSharingUploadViewControllerDelegate>

#pragma mark Notifications
- (void)accountDidChange:(NSNotification *)notification;

#pragma mark Actions

#pragma mark Login WebView
- (void)presentLogInWebView;
- (void)dismissLogInWebView;

#pragma mark UploadView
- (void)presentUploadView;
- (void)dismissUploadView;

#pragma mark Misc.
- (void)resizeWindow:(NSSize)size;

@end

@implementation SCDesktopSharingWindowController

@synthesize loginViewController;
@synthesize uploadViewController;

@synthesize view;

#pragma mark Life-cycle

- (id)init {
    self = [super initWithWindowNibName:@"SCDesktopSharingWindow"];
    if (self) {
        NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
        [dc addObserver:self
               selector:@selector(accountDidChange:)
                   name:SCSoundCloudAccountDidChangeNotification
                 object:nil];
    }
    return self;
}

- (void)dealloc;
{
    [loginViewController release];
    
    [[NSNotificationCenter defaultCenter] removeObject:self];
    [super dealloc];
}

#pragma mark Accessors

- (void)setFileURL:(NSURL *)aFileURL;
{
    self.uploadViewController.fileURL = aFileURL;
}

- (NSURL *)fileURL;
{
    return self.uploadViewController.fileURL;
}

- (void)setTitle:(NSString *)aTitle;
{
    self.uploadViewController.title = aTitle;
}

- (NSString *)title;
{
    return self.uploadViewController.title;
}

- (void)setTags:(NSArray *)someTags;
{
    self.uploadViewController.tags = someTags;
}

- (NSArray *)tags;
{
    return self.uploadViewController.tags;
}

- (void)setLicense:(NSString *)aLicense;
{
    self.uploadViewController.license = aLicense;
}

- (NSString *)license;
{
    return self.uploadViewController.license;
}

- (void)setArtwork:(NSImage *)someArtwork;
{
    self.uploadViewController.artwork = someArtwork;
}

- (NSImage *)artwork;
{
    return self.uploadViewController.artwork;
}

- (void)setParameters:(NSDictionary *)someParameters;
{
    self.uploadViewController.parameters = someParameters;
}

- (NSDictionary *)parameters;
{
    return self.uploadViewController.parameters;
}

- (SCDesktopSharingLoginViewController *)loginViewController;
{
    if (!loginViewController) {
        loginViewController = [[SCDesktopSharingLoginViewController alloc] init];
        loginViewController.delegate = self;
    }
    return loginViewController;
}

- (SCDesktopSharingUploadViewController *)uploadViewController;
{
    if (!uploadViewController) {
        uploadViewController = [[SCDesktopSharingUploadViewController alloc] init];
        uploadViewController.delegate = self;
    }
    return uploadViewController;
}

#pragma mark NSWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    [self accountDidChange:nil];
}

#pragma mark Notifications

- (void)accountDidChange:(NSNotification *)aNotification;
{
    if ([SCSoundCloud account]) {
        [self dismissLogInWebView];
        [self presentUploadView];
    } else {
        
        if ([self.uploadViewController uploadSucceeded]) {
            [[NSApplication sharedApplication] terminate:self];
        }
        
        [self dismissUploadView];
        [self presentLogInWebView];
        [self.loginViewController requestAccess:nil];
    }
}

#pragma mark SCDesktopSharingLoginViewControllerDelegate

- (void)loginViewControllerDidCancel:(SCDesktopSharingLoginViewController *)aLoginViewController;
{
    [[NSApplication sharedApplication] terminate:self];
}

- (void)loginViewController:(SCDesktopSharingLoginViewController *)aLoginViewController
           didFailWithError:(NSError *)anError;
{
    if ([[anError domain] isEqualToString:NXOAuth2ErrorDomain]) {
        switch ([anError code]) {
            case -1005: // Cancel
                [[NSApplication sharedApplication] terminate:self];
                break;
                
            default:
                break;
        }
    }
    
    [self presentError:anError modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:nil];
    [[NSApplication sharedApplication] requestUserAttention:NSCriticalRequest];
}

- (void)alertDidEnd:(NSAlert *)alert
         returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        [self.loginViewController requestAccess:nil];
    } else if (returnCode == NSAlertSecondButtonReturn) {
        [[NSApplication sharedApplication] terminate:self];
    }
}

#pragma mark SCDesktopSharingUploadViewControllerDelegate

- (void)uploadViewController:(SCDesktopSharingUploadViewController *)anUploadViewController
            didChangeArtwork:(NSImage *)anArtwork;
{
//    [[NSApplication sharedApplication] setApplicationIconImage:anArtwork];
}

- (void)uploadViewController:(SCDesktopSharingUploadViewController *)anUploadViewController didChangeTitle:(NSString *)aTitle;
{
    if ([aTitle length] > 0) {
        [self.window setTitle:[NSString stringWithFormat:NSLocalizedString(@"Share \"%@\" on SoundCloud", nil), aTitle]];
    } else {
        [self.window setTitle:NSLocalizedString(@"Share on SoundCloud", nil)];
    }
}

- (void)uploadViewControllerDidCancel:(SCDesktopSharingUploadViewController *)anUploadViewController;
{
    [[NSApplication sharedApplication] terminate:self];
}

- (void)uploadViewController:(SCDesktopSharingUploadViewController *)anUploadViewController
            didFailWithError:(NSError *)anError;
{
    [self presentError:anError modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:nil];
    [[NSApplication sharedApplication] requestUserAttention:NSCriticalRequest];
}

#pragma mark Login WebView

- (void)presentLogInWebView;
{
    if (!self.loginViewController.view.superview) {
        [self.view addSubview:self.loginViewController.view];
    }
    
    [self resizeWindow:DesktopSharingWindowControllerLogInSize];
    [self.loginViewController.view setFrame:self.view.bounds /*CGRectMake(0, 0, DesktopSharingWindowControllerLogInSize.width, DesktopSharingWindowControllerLogInSize.height)*/];
    self.loginViewController.view.hidden = NO;
}

- (void)dismissLogInWebView;
{
    self.loginViewController.view.hidden = YES;
}

#pragma mark UploadView

- (void)presentUploadView;
{
    if (!self.uploadViewController.view.superview) {
        [self.view addSubview:self.uploadViewController.view];
    }
    
    [self resizeWindow:DesktopSharingWindowControllerUploadSize];
    [self.uploadViewController.view setFrame:self.view.bounds];
    self.uploadViewController.view.hidden = NO;
    
    if (!self.fileURL) {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger returnCode){
            if (returnCode == NSFileHandlingPanelCancelButton)
                 [[NSApplication sharedApplication] terminate:self];
            
            if ([openPanel.URLs count] > 0) {
                self.fileURL = [openPanel.URLs objectAtIndex:0];
            }
        }];
    }
}

- (void)dismissUploadView;
{
    self.uploadViewController.view.hidden = YES;
}

#pragma mark Misc.

- (void)resizeWindow:(NSSize)size;
{
    NSRect frame = self.window.frame;
    frame.origin.x += (frame.size.width  - size.width)  / 2;
    frame.origin.y += (frame.size.height - size.height) / 2;
    frame.size     =  size;
    
    [self.window setFrame:frame
                  display:YES
                  animate:YES];
}

@end
