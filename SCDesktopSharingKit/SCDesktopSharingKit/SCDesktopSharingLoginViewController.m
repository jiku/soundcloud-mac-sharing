//
//  SCDesktopSharingLoginViewController.m
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 09.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <SoundCloudAPI/SCAPI.h>
#import <SoundCloudAPI/SCSoundCloud+Private.h>
#import <OAuth2Client/NSURL+NXOAuth2.h>
#import <OAuth2Client/NXOAuth2.h>

#import "IGIsolatedCookieWebView.h"

#import "SCDesktopSharingLoginViewController.h"

@interface SCDesktopSharingLoginViewController ()

#pragma mark Accessors
@property (nonatomic, readwrite, retain) WebView *webView;
@property (nonatomic, readwrite, retain) NSProgressIndicator *spinner;

#pragma mark Notification
- (void)requestAccessDidFail:(NSNotification *)notification;
- (void)accountDidChange:(NSNotification *)notification;

#pragma mark Misc.
- (void)resizeWindow:(NSSize)size;

@end

@implementation SCDesktopSharingLoginViewController

@synthesize delegate;

@synthesize webView;
@synthesize spinner;

#pragma mark Life cycle

- (id)init;
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(requestAccessDidFail:)
                                                     name:SCSoundCloudDidFailToRequestAccessNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountDidChange:)
                                                     name:SCSoundCloudAccountDidChangeNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc;
{
    self.webView = nil;
    self.spinner = nil;

    [super dealloc];
}

#pragma mark Notification

- (void)requestAccessDidFail:(NSNotification *)notification;
{
    if (requestingAccess) {
        requestingAccess = NO;
        
        NSDictionary *userInfo = notification.userInfo;
        NSError *error = [userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
        
        if ([self.delegate respondsToSelector:@selector(loginViewController:didFailWithError:)]) {
            [self.delegate loginViewController:self didFailWithError:error];
        }
    }
}

- (void)accountDidChange:(NSNotification *)notification;
{
    if ([SCSoundCloud account]) {
        if (requestingAccess) {
            requestingAccess = NO;
            if ([self.delegate respondsToSelector:@selector(loginViewControllerDidFinish:)]) {
                [self.delegate loginViewControllerDidFinish:self];
            }
        }
    }
}

#pragma mark Actions

- (IBAction)requestAccess:(id)sender;
{
    if (requestingAccess)
        return;
 
    requestingAccess = YES;
    
    [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"popup", @"display", nil];
        NSURL *soundcloudURL = [preparedURL nxoauth2_URLByAddingParameters:params];
        [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:soundcloudURL]];
    }];
}

#pragma mark NSViewController

- (void)loadView;
{
    NSView *view = [[[NSView alloc] init] autorelease];
    [view setFrameSize:NSMakeSize(410, 580)];

    self.webView = [[[IGIsolatedCookieWebView alloc] init] autorelease];
    self.webView.hidden            = YES;
    self.webView.UIDelegate        = self;
    self.webView.policyDelegate    = self;
    self.webView.frameLoadDelegate = self;
    self.webView.autoresizingMask  = NSViewWidthSizable | NSViewHeightSizable;
    self.webView.frame             = view.bounds;
    [view addSubview:webView];

    NSSize spinnerSize = NSMakeSize(32, 32);

    self.spinner = [[[NSProgressIndicator alloc] init] autorelease];
    self.spinner.style = NSProgressIndicatorSpinningStyle;
    self.spinner.frame = NSMakeRect((view.bounds.size.width  - spinnerSize.width)  / 2,
                                    (view.bounds.size.height - spinnerSize.height) / 2,
                                    spinnerSize.width,
                                    spinnerSize.height);

    self.spinner.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin;
    [self.spinner startAnimation:nil];

    view.autoresizingMask  = NSViewWidthSizable | NSViewHeightSizable;
    [view addSubview:spinner];

    [self setView:view];
}

#pragma mark WebPolicyDecisionListener

- (void)webView:(WebView *)webView decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)aRequest newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener;
{
    // Open links that have their target-attribute set to '_blank' in
    // the users browser.
    if (frameName && [frameName isEqualToString:@"_blank"]) {
        [listener ignore];
        [[NSWorkspace sharedWorkspace] openURL:aRequest.URL];
    } else {
        [listener use];
    }
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)aRequest frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener;
{
    NSURL *redirectURL = [[SCSoundCloud configuration] objectForKey:kSCConfigurationRedirectURL];
    if ([aRequest.URL.absoluteString hasPrefix:[redirectURL absoluteString]]) {
        [SCSoundCloud handleRedirectURL:aRequest.URL];
        [listener ignore];
    } else {
        [listener use];
    }
}

#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame;
{
    [self.spinner startAnimation:nil];
    self.spinner.hidden = NO;
    self.webView.hidden = YES;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;
{
    [self.spinner stopAnimation:nil];
    self.spinner.hidden = YES;
    self.webView.hidden = NO;
    
    if ([frame isEqual:[webView mainFrame]]) {
        NSURL *mainFrameURL = [NSURL URLWithString:[sender mainFrameURL]];
        if ([[mainFrameURL host] isEqualToString:@"soundcloud.com"]) {
            [self resizeWindow:NSMakeSize(410, 580)];
        }
    }
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;
{
    [self.spinner stopAnimation:nil];
    self.spinner.hidden = YES;
    self.webView.hidden = YES;
    
    requestingAccess = NO;
    
    if ([error.domain isEqualToString:WebKitErrorDomain]) {
        switch (error.code) {
            case 102: // Frame load interrupted
                return;
                break;
                
            default:
                break;
        }
    }
    
    NSString *newDesc = [[error localizedDescription] stringByAppendingString:
                         ([error localizedFailureReason] ? [error localizedFailureReason] : @"")];
    
    NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithCapacity:4];
    [newDict setObject:newDesc forKey:NSLocalizedDescriptionKey];
    [newDict setObject:NSLocalizedString(@"Would you like to try again?", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
    [newDict setObject:self forKey:NSRecoveryAttempterErrorKey];
    [newDict setObject:[NSArray arrayWithObjects:NSLocalizedString(@"Try Again", nil), NSLocalizedString(@"Cancel", nil), nil] forKey:NSLocalizedRecoveryOptionsErrorKey];
    NSError *newError = [[[NSError alloc] initWithDomain:[error domain] code:[error code] userInfo:newDict] autorelease];
    
    if ([self.delegate respondsToSelector:@selector(loginViewController:didFailWithError:)]) {
        [self.delegate loginViewController:self didFailWithError:newError];
    }
}

#pragma mark NSErrorRecoveryAttempting

- (void)attemptRecoveryFromError:(NSError *)error
                     optionIndex:(NSUInteger)recoveryOptionIndex
                        delegate:(id)delegate
              didRecoverSelector:(SEL)didRecoverSelector
                     contextInfo:(void *)contextInfo;
{
    switch (recoveryOptionIndex) {
        case 0:
            [self requestAccess:self];
            break;
            
        default:
            if ([self.delegate respondsToSelector:@selector(loginViewControllerDidCancel:)]) {
                [self.delegate loginViewControllerDidCancel:self];
            }
            break;
    }
}

#pragma mark Misc.

- (void)resizeWindow:(NSSize)size;
{
    NSRect frame = self.view.window.frame;
    frame.origin.x += (frame.size.width  - size.width)  / 2;
    frame.origin.y += (frame.size.height - size.height) / 2;
    frame.size     =  size;
    
    [self.view.window setFrame:frame
                       display:YES
                       animate:YES];
}

@end
