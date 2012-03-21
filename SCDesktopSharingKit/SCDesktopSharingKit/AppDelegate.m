//
//  AppDelegate.m
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 06.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <SoundCloudAPI/SCAPI.h>

#import "AppConstants.h"

#import "NSData+SC.h"

#import "AppDelegate.h"


const NSString * DesktopSharingArgumentClientID     = @"client_id";
const NSString * DesktopSharingArgumentClientSecret = @"client_secret";
const NSString * DesktopSharingArgumentRedirectURI  = @"redirect_uri";
const NSString * DesktopSharingArgumentFile         = @"track[asset_data]";
const NSString * DesktopSharingArgumentTitle        = @"track[title]";
const NSString * DesktopSharingArgumentLicense      = @"track[license]";
const NSString * DesktopSharingArgumentTags         = @"track[tag_list]";
const NSString * DesktopSharingArgumentArtwork      = @"track[artwork_data]";


@implementation AppDelegate

@synthesize sharingWindow;

+ (void)initialize;
{
    NSDictionary *args = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSArgumentDomain];
     
    NSString *clientID = [args objectForKey:DesktopSharingArgumentClientID];
    NSString *clientSecret = [args objectForKey:DesktopSharingArgumentClientSecret];
    NSString *redirectURI = [args objectForKey:DesktopSharingArgumentRedirectURI];
    
    // always treat them as a pair
    if (!clientID || !clientSecret) {
        clientID = kClientID;
        clientSecret = kClientSecret;
    }
    
    if (!redirectURI) {
        redirectURI = kClientRedirectURI;
    }
    
    [SCSoundCloud setClientID:clientID
                       secret:clientSecret
                  redirectURL:[NSURL URLWithString:redirectURI]];
}

- (void)dealloc
{
    [sharingWindow release];
    [super dealloc];
}

#pragma mark Accessors

- (SCDesktopSharingWindowController *)sharingWindow;
{
    @synchronized (sharingWindow) {
        if (!sharingWindow) {
            sharingWindow = [[SCDesktopSharingWindowController alloc] init];
        }
    }
    return sharingWindow;
}

- (IBAction)showHelp:(id)sender;
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://help.soundcloud.com"]];
}


#pragma mark AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
    NSDictionary *args = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSArgumentDomain];
    
    NSURL *fileURL = [args objectForKey:DesktopSharingArgumentFile] ? [NSURL fileURLWithPath:[args objectForKey:DesktopSharingArgumentFile]] : nil;
    NSString *title = [args objectForKey:DesktopSharingArgumentTitle];
    
    if (fileURL && !title) {
        title = [[fileURL lastPathComponent] stringByDeletingPathExtension];
        title = [title stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    }
    
    NSString *license = [args objectForKey:DesktopSharingArgumentLicense];
    
    self.sharingWindow.fileURL = fileURL;
    self.sharingWindow.title = title;
    
    if (license) {
        self.sharingWindow.license = license;
    }

    
    if ([args objectForKey:DesktopSharingArgumentTags]) {
        self.sharingWindow.tags = [[args objectForKey:DesktopSharingArgumentTags] componentsSeparatedByString:@" "];
    }
    
    NSString *artworkPath = [args objectForKey:DesktopSharingArgumentArtwork];
    if (artworkPath) {
        NSImage *artwork = [[[NSImage alloc] initWithContentsOfFile:artworkPath] autorelease];
        self.sharingWindow.artwork = artwork;
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    for (NSString *key in [args allKeys]) {
        if ([key hasPrefix:@"track["] && [key hasSuffix:@"]"]) {
            [parameters setObject:[args objectForKey:key] forKey:key];
        }
    }
    self.sharingWindow.parameters = parameters;
    
    [self.sharingWindow.window makeKeyAndOrderFront:self];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag;
{
    [[sharingWindow window] makeKeyAndOrderFront:nil];
    return YES;
}

@end
