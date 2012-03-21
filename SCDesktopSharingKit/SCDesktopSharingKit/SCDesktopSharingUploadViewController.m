//
//  SCDesktopSharingUploadViewController.m
//  SoundCloud Desktop Sharing Kit
//
//  Created by Tobias Kräntzer on 09.12.11.
//  Copyright (c) 2011 SoundCloud Ltd. All rights reserved.
//

#import <Quartz/Quartz.h>

#import <SoundCloudAPI/SCAPI.h>
#import <SoundCloudAPI/SCAccount+Private.h>
#import <JSONKIT/JSONKit.h>
#import <OAuth2Client/NSURL+NXOAuth2.h>
#import <OAuth2Client/NXOAuth2.h>

#import "PMProgressIndicator.h"

#import "SCDesktopSharingClickableImageView.h"

#import "SCDesktopSharingUploadViewController.h"

@interface SCDesktopSharingUploadViewController () <NSTextFieldDelegate, NSTokenFieldDelegate>

@property (nonatomic, retain) NSArray *availableConnections;
@property (nonatomic, retain) NSArray *unconnectedServices;
@property (nonatomic, retain) NSArray *sharingConnections;

@property (nonatomic, retain) NSSet *defaultTags;
@property (nonatomic, retain) NSString *defaultLicense;
@property (nonatomic, assign, getter = isDefaultSharingPrivate) BOOL defaultSharingIsPrivate;
@property (nonatomic, retain) NSArray *defaultSharingConnections;

#pragma mark Helper Methods
+ (NSArray *)validLicenses;

- (NSDictionary *)generateTrackParameters;
- (NSURL *)trackURL;
- (NSString *)generatedPlaceholderTitle;
- (NSString *)generatedTitle;
- (NSString *)generatedSharingNote;
- (NSString *)dateString;
- (void)updateConnections;
- (void)updateMeUser;

#pragma mark Image Picker
- (void)pictureTakerDidEnd:(IKPictureTaker *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

#pragma mark Showing Views
- (void)showMetadataView;
- (void)showUploadProgressView;
- (void)showUploadSuccessView;

#pragma mark Update Views
- (void)updateMetadataView;
- (void)updatePrivacySettingsView;
- (void)updateProgressView;
- (void)updateSuccessView;

#pragma mark Notification
- (void)accountDidChange:(NSNotification *)notification;
- (void)windowDidBecomeMain:(NSNotification *)notification;

#pragma mark User Defaults
- (void)updateUserDefaults;
- (void)addDefaultTags:(NSSet *)someTags;

@end

@implementation SCDesktopSharingUploadViewController

@synthesize delegate;
@synthesize fileURL;
@synthesize title;
@synthesize tags;
@synthesize license;
@synthesize artwork;
@synthesize public;
@synthesize parameters;
@synthesize uploadError;
@synthesize uploadSucceeded;
@synthesize trackInfo;

@synthesize privacySettingPublic;
@synthesize connectionTableView;
@synthesize privacySettingPrivate;
@synthesize availableConnections;
@synthesize unconnectedServices;
@synthesize sharingConnections;

@synthesize uploadProgressView;
@synthesize uploadProgressIndicator;
@synthesize uploadLabel;
@synthesize uploadSuccessView;
@synthesize successLabel;
@synthesize trackLinkCopyButton;
@synthesize trackLinkOpenButton;
@synthesize metadataView;
@synthesize titleField;
@synthesize tagsField;
@synthesize licenseSelection;
@synthesize artworkView;
@synthesize privacySwitch;
@synthesize privacySetting;
@synthesize logoutButton;
@synthesize uploadButton;
@synthesize cancelButton;
@synthesize avatarImageView;
@synthesize userNameLabel;
@synthesize box;

const NSArray *allServices = nil;

#pragma mark Class methods

+ (void)initialize;
{
    allServices = [[NSArray alloc] initWithObjects:
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    NSLocalizedString(@"Twitter", nil), @"displayName",
                    @"twitter", @"service",
                    nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    NSLocalizedString(@"Facebook", nil), @"displayName",
                    @"facebook_profile", @"service",
                    nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    NSLocalizedString(@"Tumblr", nil), @"displayName",
                    @"tumblr", @"service",
                    nil],
                   nil];
}

+ (NSArray *)validLicenses;
{
    return [NSArray arrayWithObjects:@"default", @"no-rights-reserved", @"all-rights-reserved", @"cc-by", @"cc-by-nc", @"cc-by-nd", @"cc-by-sa", @"cc-by-nc-nd", @"cc-by-nc-sa", nil];
}

#pragma mark Life cycle

- (id)init;
{
    self = [super initWithNibName:@"SCDesktopSharingUploadViewController" bundle:nil];
    if (self) {
        self.license = self.defaultLicense;
        self.public = !self.defaultSharingIsPrivate;
        self.sharingConnections = self.defaultSharingConnections;
        
        unconnectedServices = [[NSArray alloc] init];
        availableConnections = [[NSArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountDidChange:)
                                                     name:SCSoundCloudAccountDidChangeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowDidBecomeMain:)
                                                     name:NSWindowDidBecomeKeyNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObject:self];
    
    [availableConnections release];
    [unconnectedServices release];
    [sharingConnections release];
    
    [uploadError release];
    
    [trackInfo release];
    [fileURL release];
    [title release];
    [tags release];
    [license release];
    [artwork release];
    
    [super dealloc];
}

#pragma mark Accessor

- (void)setFileURL:(NSURL *)aFileURL;
{
    if (aFileURL != fileURL) {
        [aFileURL retain];
        [fileURL release];
        fileURL = aFileURL;
        
        if (fileURL && !self.title) {
            NSString *newTitle = [[fileURL lastPathComponent] stringByDeletingPathExtension];
            self.title = [newTitle stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        }
    }
    [self.uploadButton setEnabled:fileURL != nil];
}

- (void)setTitle:(NSString *)aTitle;
{
    if (![aTitle isEqualToString:title]) {
        [title release];
        [aTitle retain];
        title = aTitle;
        [self.titleField setStringValue:title];
        
        if ([self.delegate respondsToSelector:@selector(uploadViewController:didChangeTitle:)]) {
            [self.delegate uploadViewController:self didChangeTitle:title];
        }
    }
}

- (void)setTags:(NSArray *)someTags;
{
    if (![someTags isEqualToArray:tags]) {
        [someTags retain];
        [tags release];
        tags = someTags;
        
        [self.tagsField setObjectValue:tags];
    }
}

- (void)setLicense:(NSString *)aLicense;
{
    if (![aLicense isEqualToString:license]) {
        [license release];
        NSInteger licenseIndex = [[SCDesktopSharingUploadViewController validLicenses] indexOfObject:aLicense];
        if (licenseIndex != NSNotFound) {
            [self.licenseSelection selectItemAtIndex:licenseIndex];
            [aLicense retain];
            license = aLicense;
        } else {
            license = nil;
        }
    }
}

- (void)setArtwork:(NSImage *)someArtwork;
{
    if (someArtwork != artwork) {
        [someArtwork retain];
        [artwork release];
        artwork = someArtwork;
        
        [self.artworkView setImage:artwork];
        
        if ([self.delegate respondsToSelector:@selector(uploadViewController:didChangeArtwork:)]) {
            [self.delegate uploadViewController:self didChangeArtwork:self.artwork];
        }
    }
}

- (void)setPublic:(BOOL)value;
{
    if (public != value) {
        public = value;
        [self updatePrivacySettingsView];
    }
}

- (void)setAvailableConnections:(NSArray *)value;
{
    [value retain];
    [availableConnections release];
    availableConnections = value;
    
    NSMutableArray *newUnconnectedServices = [allServices mutableCopy];
    
    //Set the unconnected Services
    for (NSDictionary *connection in availableConnections) {
        NSDictionary *connectedService = nil;
        for (NSDictionary *unconnectedService in newUnconnectedServices) {
            if ([[connection objectForKey:@"service"] isEqualToString:[unconnectedService objectForKey:@"service"]]) {
                connectedService = unconnectedService;
            }
        }
        if (connectedService) [newUnconnectedServices removeObject:connectedService];
    }
    
    self.unconnectedServices = newUnconnectedServices;
    [newUnconnectedServices release];
    [self.connectionTableView reloadData];
}

- (void)setUploadError:(NSError *)anError;
{
    if (anError != uploadError) {
        [uploadError release];
        [anError retain];
        uploadError = anError;
        
        if (uploadError) {
            if ([self.delegate respondsToSelector:@selector(uploadViewController:didFailWithError:)]) {
                [self.delegate uploadViewController:self didFailWithError:uploadError];
            }
        }
    }
}

#pragma mark NSViewController

- (void)loadView;
{
    [super loadView];
    
    [self.box setContentView:self.metadataView];
    [self.uploadButton setEnabled:fileURL != nil];
    
    [self updatePrivacySettingsView];
    [self updateMetadataView];
    [self updateConnections];
    [self updateMeUser];
    
    [self.tagsField setTokenizingCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.tagsField.delegate = self;
    
    [[self.titleField cell] setPlaceholderString:[self generatedPlaceholderTitle]];
    self.titleField.delegate = self;
    
    [self.artworkView setTarget:self];
    [self.artworkView setClickAction:@selector(addArtwork:)];
}

#pragma mark Actions

- (IBAction)logout:(id)sender;
{
    [SCSoundCloud removeAccess];
}

- (IBAction)upload:(id)sender;
{

    NSError *error = nil;
    if (![self.fileURL checkResourceIsReachableAndReturnError:&error]) {
        self.uploadError = error;
        [self showMetadataView];
        return;
    }
    
    [self showUploadProgressView];
    
    SCAccount *account = [SCSoundCloud account];
    
    request = [SCRequest performMethod:SCRequestMethodPOST
                            onResource:[NSURL URLWithString:@"https://api.soundcloud.com/tracks.json"]
                       usingParameters:[self generateTrackParameters]
                           withAccount:account
                sendingProgressHandler:^(unsigned long long bytesSent, unsigned long long bytesTotal){
                    [self.uploadProgressIndicator setDrawDockProgress:YES];
                    [self.uploadProgressIndicator setIndeterminate:NO];
                    [self.uploadProgressIndicator setDoubleValue:100.0 * (double)bytesSent / bytesTotal];
                }
                       responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                           
                           request = nil;
                           
                           if (error) {
                               // Parse the body of the response and set a localized description if possible
                               NSString *errorMessage = nil;
                               NSDictionary *errorInfo = [data objectFromJSONData];
                               NSArray *errors = [errorInfo objectForKey:@"errors"];
                               if ([errors count] > 0) {
                                   errorMessage = [[errors objectAtIndex:0] objectForKey:@"error_message"];
                               }
                               
                               if ([error.domain isEqualToString:NXOAuth2HTTPErrorDomain] && error.code == 413 && errorMessage == nil) {
                                   // Workaround to get a nice error message if twe have a 413
                                   // TODO: Better error message
                                   errorMessage = NSLocalizedString(@"Your file is too large.", nil);
                               }
                               
                               NSDictionary *userInfo = [[error.userInfo mutableCopy] autorelease];
                               if (errorMessage) {
                                   userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(errorMessage, nil)
                                                                          forKey:NSLocalizedDescriptionKey];
                               }

                               error = [NSError errorWithDomain:error.domain
                                                           code:error.code
                                                       userInfo:userInfo];
                               
                               NSError *newError = nil;
                               
                               if ([error.domain isEqualToString:NXOAuth2HTTPErrorDomain] && error.code == 413) {
                                   
                                   NSString *newDesc = [[error localizedDescription] stringByAppendingString:
                                                        ([error localizedFailureReason] ? [error localizedFailureReason] : @"")];
                                   
                                   NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithCapacity:4];
                                   [newDict setObject:newDesc forKey:NSLocalizedDescriptionKey];
                                   [newDict setObject:self forKey:NSRecoveryAttempterErrorKey];
                                   [newDict setObject:[NSArray arrayWithObjects:NSLocalizedString(@"Ok", nil), NSLocalizedString(@"Help", nil), nil] forKey:NSLocalizedRecoveryOptionsErrorKey];
                                   newError = [[[NSError alloc] initWithDomain:[error domain] code:[error code] userInfo:newDict] autorelease];
                                   
                               } else {
                                   NSString *newDesc = [[error localizedDescription] stringByAppendingString:
                                                        ([error localizedFailureReason] ? [error localizedFailureReason] : @"")];
                                   
                                   NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithCapacity:4];
                                   [newDict setObject:newDesc forKey:NSLocalizedDescriptionKey];
                                   [newDict setObject:NSLocalizedString(@"Would you like to try again?", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
                                   [newDict setObject:self forKey:NSRecoveryAttempterErrorKey];
                                   [newDict setObject:[NSArray arrayWithObjects:NSLocalizedString(@"Ok", nil), nil] forKey:NSLocalizedRecoveryOptionsErrorKey];
                                   newError = [[[NSError alloc] initWithDomain:[error domain] code:[error code] userInfo:newDict] autorelease];
                               }
                               
                               self.uploadError = newError;
                               
                               [self showMetadataView];
                               
                           } else {
                               if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
                                   NSLog(@"Expecting a NSURLHTTPResponse.");
                                   return;
                               }
                               
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               
                               if ([httpResponse statusCode] >= 200 && [httpResponse statusCode] < 300) {
                                   self.trackInfo = [data objectFromJSONData];
                                   [self updateUserDefaults];
                                   [self showUploadSuccessView];
                                   uploadSucceeded = YES;
                               } else {
                                   
                                   NSString *errorMessage = nil;
                                   NSDictionary *errorInfo = [data objectFromJSONData];
                                   NSArray *errors = [errorInfo objectForKey:@"errors"];
                                   if ([errors count] > 0) {
                                       errorMessage = [[errors objectAtIndex:0] objectForKey:@"error_message"];
                                   }
                                   
                                   NSDictionary *userInfo = nil;
                                   if (errorMessage) {
                                       userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(errorMessage, nil)
                                                                              forKey:NSLocalizedDescriptionKey];
                                   }
                                   
                                   self.uploadError = [NSError errorWithDomain:@"HTTPErrorDomain"
                                                                          code:httpResponse.statusCode
                                                                      userInfo:userInfo];
                                   [self showMetadataView];
                               }
                           }
                           [self.uploadProgressIndicator setDrawDockProgress:NO];
                       }];
}

- (IBAction)cancel:(id)sender;
{
    [request cancel];
    request = nil;
    
    if ([self.delegate respondsToSelector:@selector(uploadViewControllerDidCancel:)]) {
        [self.delegate uploadViewControllerDidCancel:self];
    }
}

- (IBAction)copyTrackLink:(id)sender;
{
    
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
    [pasteBoard setString:[[self trackURL] absoluteString] forType:NSStringPboardType];
}

- (IBAction)dropArtwork:(id)sender;
{
    self.artwork = self.artworkView.image;
}

- (IBAction)addArtwork:(id)sender;
{
    
    IKPictureTaker *imagePicker = [IKPictureTaker pictureTaker];
    imagePicker.title = NSLocalizedString(@"Artwork", nil);
    imagePicker.inputImage = self.artwork;
    [imagePicker beginPictureTakerSheetForWindow:nil withDelegate:self didEndSelector:@selector(pictureTakerDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)removeArtwork:(id)sender;
{
    self.artwork = nil;
}

- (IBAction)privacyChanged:(id)sender;
{
    BOOL value = self.privacySwitch.selectedSegment == 0 ? YES : NO;
    if (public != value) {
        public = value;
        [self updatePrivacySettingsView];
    }
}

- (IBAction)openLink:(id)sender;
{
    [[NSWorkspace sharedWorkspace] openURL:[self trackURL]];
}

- (IBAction)showConnections:(id)sender;
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://soundcloud.com/settings/connections"]];
}

- (IBAction)showLicenseHelp:(id)sender;
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://help.soundcloud.com/customer/portal/topics/39593-legal/articles"]];
}

- (IBAction)licenseChanged:(id)sender;
{
    self.license = [[SCDesktopSharingUploadViewController validLicenses] objectAtIndex:self.licenseSelection.indexOfSelectedItem];
}

#pragma mark Helper Methods

- (NSDictionary *)generateTrackParameters;
{
    NSMutableDictionary *uploadParameters = [[self.parameters mutableCopy] autorelease];
    if (uploadParameters == nil) {
        uploadParameters = [NSMutableDictionary dictionary];
    }
    
    [uploadParameters setObject:[self generatedTitle] forKey:@"track[title]"];
    [uploadParameters setObject:[self generatedSharingNote] forKey:@"track[sharing_note]"];
    
    if ([self.tags count] > 0) {
        [uploadParameters setObject:[self.tags componentsJoinedByString:@" "] forKey:@"track[tag_list]"];
    }
    
    if (self.license && ![self.license isEqualToString:@"default"]) {
        [uploadParameters setObject:self.license forKey:@"track[license]"];
    }
    
    [uploadParameters setObject:self.public ? @"public" : @"private" forKey: @"track[sharing]"];
    
    // sharing
    if (self.isPublic) {
        if (self.sharingConnections.count > 0) {
            NSMutableArray *idArray = [NSMutableArray arrayWithCapacity:self.sharingConnections.count];
            for (NSDictionary *sharingConnection in sharingConnections) {
                [idArray addObject:[NSString stringWithFormat:@"%@", [sharingConnection objectForKey:@"id"]]];
            }
            [uploadParameters setObject:idArray forKey:@"track[post_to][][id]"];
        } else {
            [uploadParameters setObject:@"" forKey:@"track[post_to][]"];
        }
    }
    
    [uploadParameters setObject:@"recording" forKey:@"track[track_type]"];
    
    // artwork
    if (self.artworkView.image) {
        CIImage *myImage = [CIImage imageWithData:[self.artworkView.image TIFFRepresentation]];
        NSBitmapImageRep *bitmapRep = [[[NSBitmapImageRep alloc] initWithCIImage:myImage] autorelease];
        NSData *jpegData = [bitmapRep representationUsingType:NSJPEGFileType properties:nil];
        [uploadParameters setObject:jpegData forKey:@"track[artwork_data]"];
    }
    
    [uploadParameters setObject:self.fileURL forKey: @"track[asset_data]"];
    
    return uploadParameters;
}

- (NSURL *)trackURL;
{
    NSString *urlString = nil;
    if ([[self.trackInfo objectForKey:@"sharing"] isEqualToString:@"public"]) {
        urlString = [self.trackInfo objectForKey:@"permalink_url"];
    } else {
        urlString = [NSString stringWithFormat:@"%@/%@", [self.trackInfo objectForKey:@"permalink_url"], [self.trackInfo objectForKey:@"secret_token"]];
    }
    
    return [NSURL URLWithString:urlString];
}

- (NSString *)generatedPlaceholderTitle;
{
    return [NSString stringWithFormat:NSLocalizedString(@"Sounds from %@", nil), [self dateString]];
}

- (NSString *)generatedTitle;
{
    if ([self.title length] > 0) {
        return self.title;
    } else {
        return [self generatedPlaceholderTitle];
    }
}

- (NSString *)generatedSharingNote;
{
    NSString *note = nil;
    if (note) {
        return note;
    }
    
    if ([self.title length] > 0) {
        note = self.title;
    } else {
        note = [NSString stringWithFormat:NSLocalizedString(@"Sounds from %@", nil), [self dateString]];
    }
    
    return note;
}

- (NSString *)dateString;
{
    NSString *weekday = nil;
    NSString *time = nil;
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:(NSWeekdayCalendarUnit | NSHourCalendarUnit) fromDate:[NSDate date]];
    [gregorian release];
    
    switch ([components weekday]) {
        case 1:
            weekday = NSLocalizedString(@"Sunday", nil);
            break;
        case 2:
            weekday = NSLocalizedString(@"Monday", nil);
            break;
        case 3:
            weekday = NSLocalizedString(@"Tuesday", nil);
            break;
        case 4:
            weekday = NSLocalizedString(@"Wednesday", nil);
            break;
        case 5:
            weekday = NSLocalizedString(@"Thursday", nil);
            break;
        case 6:
            weekday = NSLocalizedString(@"Friday", nil);
            break;
        case 7:
            weekday = NSLocalizedString(@"Saturday", nil);
            break;
    }
    
    if ([components hour] <= 12) {
        time = NSLocalizedString(@"morning", nil);
    } else if ([components hour] <= 17) {
        time = NSLocalizedString(@"afternoon", nil);
    } else if ([components hour] <= 21) {
        time = NSLocalizedString( @"evening", nil);
    } else {
        time = NSLocalizedString(@"night", nil);
    }
    
    return [NSString stringWithFormat:@"%@ %@", weekday, time];
}

- (void)updateConnections;
{
    SCAccount *account = [SCSoundCloud account];
    loadingConnections = YES;
    if (account) {
        [SCRequest performMethod:SCRequestMethodGET
                      onResource:[NSURL URLWithString:@"https://api.soundcloud.com/me/connections.json"]
                 usingParameters:nil
                     withAccount:account
          sendingProgressHandler:nil
                 responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                     if (data) {
                         NSError *jsonError = nil;
                         NSArray *result = [data objectFromJSONData];
                         if (result) {
                             
                             self.availableConnections = result;
                         } else {
                             NSLog(@"%s json error: %@", __FUNCTION__, [jsonError localizedDescription]);
                         }
                     } else {
                         NSLog(@"%s error: %@", __FUNCTION__, [error localizedDescription]);
                     }
                     
                     loadingConnections = NO;
                 }];
    }
}

- (void)updateMeUser;
{
    SCAccount *account = [SCSoundCloud account];
    
    NSImage *avatar = [[account userInfo] objectForKey:@"avatar"];
    if (avatar) {
        self.avatarImageView.image = avatar;
    }
    
    NSString *username = [[[account userInfo] objectForKey:@"me"] objectForKey:@"username"];
    if (username) {
        [self.userNameLabel setStringValue:username];
    }
    
    if (account) {
        [SCRequest performMethod:SCRequestMethodGET
                      onResource:[NSURL URLWithString:@"https://api.soundcloud.com/me.json"]
                 usingParameters:nil
                     withAccount:account
          sendingProgressHandler:nil
                 responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                     if (data) {
                         NSError *jsonError = nil;
                         NSDictionary *result = [data objectFromJSONData];
                         if (result) {
                                                          
                             NSString *avatarURLString = [result objectForKey:@"avatar_url"];
                             if (avatarURLString) {
                                 NSURL *avatarURL = [NSURL URLWithString:avatarURLString];
                                 NSImage *avatar = [[NSImage alloc] initByReferencingURL:avatarURL];
                                 // TODO: resize the avatar image
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     self.avatarImageView.image = avatar;
                                 });
                                 [SCSoundCloud account].userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    result, @"me",
                                                                    avatar, @"avatar", nil];
                             } else {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     self.avatarImageView.image = nil;
                                 });
                                 [SCSoundCloud account].userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    result, @"me", nil];
                             }
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self.userNameLabel setStringValue:[result objectForKey:@"username"]];
                             });
                             

                             
                         } else {
                             NSLog(@"%s json error: %@", __FUNCTION__, [jsonError localizedDescription]);
                         }
                     } else {
                         NSLog(@"%s error: %@", __FUNCTION__, [error localizedDescription]);
                     }
                 }];
    }
}

#pragma mark Image Picker

- (void)pictureTakerDidEnd:(IKPictureTaker *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSOKButton) {
        NSImage *image = sheet.outputImage;
        self.artwork = image;
    }
}

#pragma mark Showing Views

- (void)showMetadataView;
{
    [self.box setContentView:self.metadataView];
    [self updateMetadataView];
    [self.logoutButton setEnabled:YES];
    [self.uploadButton setEnabled:YES];
    
    if (self.uploadError) {
        [self.uploadButton setTitle:NSLocalizedString(@"Retry", nil)];
    } else {
        [self.uploadButton setTitle:NSLocalizedString(@"Upload", nil)];
    }
}

- (void)showUploadProgressView;
{
    [self.uploadButton setEnabled:NO];
    [self.logoutButton setEnabled:NO];
    
    [self.box setContentView:self.uploadProgressView];
    
    [self.uploadProgressIndicator startAnimation:nil];
    [self.uploadProgressIndicator setMaxValue:100];
    [self.uploadProgressIndicator setMinValue:0];
    
    [self updateProgressView];
}

- (void)showUploadSuccessView;
{
    [self.logoutButton setEnabled:YES];
    [self.box setContentView:self.uploadSuccessView];
    
    NSRect buttonFrame = [self.uploadButton frame];
    [self.uploadButton removeFromSuperview];
    
    [self.cancelButton setFrame:buttonFrame];
    
    [self.cancelButton setTitle:NSLocalizedString(@"Done", nil)];
    [self updateSuccessView];
}

#pragma mark Update Views

- (void)updateMetadataView;
{
    if (self.title) {
        self.titleField.stringValue = self.title;
    }
    
    if ([self.tags count] > 0) {
        self.tagsField.objectValue = self.tags;
    }
    
    NSInteger licenseIndex = [[SCDesktopSharingUploadViewController validLicenses] indexOfObject:self.license];
    if (licenseIndex != NSNotFound) {
        [self.licenseSelection selectItemAtIndex:licenseIndex];
    }
    
    [self.artworkView setImage:self.artwork];
}

- (void)updatePrivacySettingsView;
{
    self.privacySwitch.selectedSegment = self.isPublic ? 0 : 1;
    if (self.isPublic) {
        [self.privacySettingPrivate removeFromSuperview];
        [self.privacySetting addSubview:self.privacySettingPublic];
    } else {
        [self.privacySettingPublic removeFromSuperview];
        [self.privacySetting addSubview:self.privacySettingPrivate];
    }
}

- (void)updateProgressView;
{
    [self.uploadLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Uploading \"%@\"...", nil), [self generatedTitle]]];
}

- (void)updateSuccessView;
{
    [self.successLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" is now available at", nil), [self generatedTitle]]];
    [self.trackLinkOpenButton setTitle:[[self trackURL] absoluteString]];
}

#pragma mark NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor;
{
    if (control == self.titleField) {
        self.title = self.titleField.stringValue;
    } else if (control == self.tagsField) {
        self.tags = self.tagsField.objectValue;
    }
    
    return YES;
}

#pragma mark NSTokenFieldDelegate

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex;
{
    NSArray *storedTags = [self.defaultTags allObjects];
    
    NSMutableArray *completions = [NSMutableArray array];
    for (NSString *tag in storedTags) {
        if ([tag hasPrefix:substring] && ![self.tagsField.objectValue containsObject:tag]) {
            [completions addObject:tag];
        }
    }
    return completions;
}

#pragma mark NSTableViewDelegate

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
{
    NSString *identifier = [aTableColumn identifier];
    if (rowIndex < self.availableConnections.count) {
        if ([identifier isEqualToString:@"settings"]) {
            return [[[NSCell alloc] init] autorelease];
        } else {
            return nil;
        }
    } else {
        if ([identifier isEqualToString:@"selected"]) {
            return [[[NSCell alloc] init] autorelease];
        } else if ([identifier isEqualToString:@"name"]) {
            NSTextFieldCell *cell = [[NSTextFieldCell alloc] init];
            [cell setTextColor:[NSColor grayColor]];
            return [cell autorelease];
        } else {
            return nil;
        }
    }
}


#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
{
    return self.availableConnections.count + self.unconnectedServices.count;;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
{
    if (rowIndex < self.availableConnections.count) {
        NSDictionary *connection = [self.availableConnections objectAtIndex:rowIndex];
        
        NSString *identifier = [aTableColumn identifier];
        
        if ([identifier isEqualToString:@"selected"]) {
            __block NSInteger state = NSOffState;
            [self.sharingConnections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
                if ([[obj objectForKey:@"id"] isEqual:[connection objectForKey:@"id"]]) {
                    state = NSOnState;
                    *stop = YES;
                }
            }];
            return [NSNumber numberWithInteger:state];
        } else if ([identifier isEqualToString:@"icon"]) {
            return [NSImage imageNamed:[NSString stringWithFormat:@"service_%@.png", [connection objectForKey:@"service"]]];
        } else if ([identifier isEqualToString:@"name"]) {
            if ([[connection objectForKey:@"service"] isEqualToString:@"facebook_page"]) {
                return [NSString stringWithFormat:@"Page: %@", [connection objectForKey:@"display_name"]];
            } else {
                return [connection objectForKey:@"display_name"];
            }
        } else {
            return nil;
        }
        
    } else {
        NSDictionary *service = [self.unconnectedServices objectAtIndex:rowIndex - self.availableConnections.count];
        
        NSString *identifier = [aTableColumn identifier];
        
        if ([identifier isEqualToString:@"selected"]) {
            return nil;
        } else if ([identifier isEqualToString:@"icon"]) {
            return [NSImage imageNamed:[NSString stringWithFormat:@"service_%@_inactive.png", [service objectForKey:@"service"]]];
        } else if ([identifier isEqualToString:@"name"]) {
            return [service objectForKey:@"displayName"];
        } else if ([identifier isEqualToString:@"settings"]) {
            return nil;
        } else {
            return nil;
        }
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
{
    NSString *identifier = [aTableColumn identifier];
    
    if ([identifier isEqualToString:@"selected"]) {
        BOOL selected = [(NSNumber *)anObject boolValue];
        
        
        NSDictionary *connection = [availableConnections objectAtIndex:rowIndex];
        
        NSMutableArray *newSharingConnections = [self.sharingConnections mutableCopy];
        if (selected) {
            [newSharingConnections addObject:connection];
        } else {
            NSIndexSet *idxs = [newSharingConnections indexesOfObjectsPassingTest:^(id obj, NSUInteger i, BOOL *stop){
                if ([[obj objectForKey:@"id"] isEqual:[connection objectForKey:@"id"]]) {
                    *stop = YES;
                    return YES;
                } else {
                    return NO;
                }
            }];
            [newSharingConnections removeObjectsAtIndexes:idxs];
        }
        
        self.sharingConnections = newSharingConnections;
        [newSharingConnections release];
        [self.connectionTableView reloadData];
    } else if ([identifier isEqualToString:@"settings"]) {
        
        if (rowIndex < self.availableConnections.count) {
        } else {
            NSDictionary *service = [self.unconnectedServices objectAtIndex:rowIndex - self.availableConnections.count];
            SCAccount *account = [SCSoundCloud account];
            if (account) {
                
                NSMutableDictionary *options = [NSMutableDictionary dictionary];
                [options setValue:[service objectForKey:@"service"] forKey:@"service"];
                [options setValue:@"http://soundcloud.com/settings/connections" forKey:@"redirect_uri"];
                
                [SCRequest performMethod:SCRequestMethodPOST
                              onResource:[NSURL URLWithString:@"https://api.soundcloud.com/me/connections.json"]
                         usingParameters:options
                             withAccount:account
                  sendingProgressHandler:nil
                         responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                             if (data) {
                                 NSError *jsonError = nil;
                                 NSDictionary *result = [data objectFromJSONData];
                                 if (result) {
                                     NSURL *authURL = [NSURL URLWithString:[result objectForKey:@"authorize_url"]];
                                     if (authURL) {
                                         [[NSWorkspace sharedWorkspace] openURL:authURL];
                                     }
                                 } else {
                                     NSLog(@"%s json error: %@", __FUNCTION__, [jsonError localizedDescription]);
                                 }
                             } else {
                                 NSLog(@"%s error: %@", __FUNCTION__, [error localizedDescription]);
                             }
                         }];
            }
        }
    }
}

#pragma mark Notification

- (void)accountDidChange:(NSNotification *)notification;
{
    [self updateConnections];
    [self updateMeUser];
}

- (void)windowDidBecomeMain:(NSNotification *)notification;
{
    if (notification.object == self.view.window) {
        [self updateConnections];
    }
}

#pragma mark User Defaults

- (void)updateUserDefaults;
{
    [self addDefaultTags:[NSSet setWithArray:self.tags]];
    self.defaultLicense = self.license;
    [self setDefaultSharingIsPrivate:!self.isPublic];
    if (self.isPublic) {
        self.defaultSharingConnections = self.sharingConnections;
    }
}

- (NSSet *)defaultTags;
{
    NSString *userDefaultsKey = [NSString stringWithFormat:@"%@::tags", [[NSBundle mainBundle] bundleIdentifier]];
    return [NSSet setWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:userDefaultsKey]];
}

- (void)addDefaultTags:(NSSet *)someTags;
{
    NSString *userDefaultsKey = [NSString stringWithFormat:@"%@::tags", [[NSBundle mainBundle] bundleIdentifier]];
    
    NSMutableSet *storedTags = [NSMutableSet setWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:userDefaultsKey]];
    [storedTags addObjectsFromArray:[someTags allObjects]];
    [[NSUserDefaults standardUserDefaults] setValue:[storedTags allObjects] forKey:userDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setDefaultTags:(NSSet *)someTags;
{
    NSString *userDefaultsKey = [NSString stringWithFormat:@"%@::tags", [[NSBundle mainBundle] bundleIdentifier]];
    [[NSUserDefaults standardUserDefaults] setValue:[someTags allObjects] forKey:userDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)defaultLicense;
{
    NSString *userDefaultsKey = [NSString stringWithFormat:@"%@::license", [[NSBundle mainBundle] bundleIdentifier]];
    NSString *storedLicense = [[NSUserDefaults standardUserDefaults] stringForKey:userDefaultsKey];
    if (storedLicense == nil) {
        storedLicense = @"default";
    }
    return storedLicense;
}

- (void)setDefaultLicense:(NSString *)aLicense;
{
    NSString *userDefaultsKey = [NSString stringWithFormat:@"%@::license", [[NSBundle mainBundle] bundleIdentifier]];
    if (aLicense) {
        [[NSUserDefaults standardUserDefaults] setValue:aLicense forKey:userDefaultsKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:userDefaultsKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isDefaultSharingPrivate;
{
    NSString *userDefaultsKey = [NSString stringWithFormat:@"%@::sharing_is_private", [[NSBundle mainBundle] bundleIdentifier]];
    return [[NSUserDefaults standardUserDefaults] boolForKey:userDefaultsKey];
}

- (void)setDefaultSharingIsPrivate:(BOOL)private;
{
    NSString *userDefaultsKey = [NSString stringWithFormat:@"%@::sharing_is_private", [[NSBundle mainBundle] bundleIdentifier]];
    [[NSUserDefaults standardUserDefaults] setBool:private forKey:userDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)defaultSharingConnections;
{
    NSString *userDefaultsKey = [NSString stringWithFormat:@"%@::sharing_connections", [[NSBundle mainBundle] bundleIdentifier]];
    
    NSArray *result = [[NSUserDefaults standardUserDefaults] arrayForKey:userDefaultsKey];
    if (!result) {
        result = [NSArray array];
    }
    return result;
}

- (void)setDefaultSharingConnections:(NSSet *)someSharingConnections;
{
    NSString *userDefaultsKey = [NSString stringWithFormat:@"%@::sharing_connections", [[NSBundle mainBundle] bundleIdentifier]];
    [[NSUserDefaults standardUserDefaults] setValue:someSharingConnections forKey:userDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark NSErrorRecoveryAttempting

- (void)attemptRecoveryFromError:(NSError *)error
                     optionIndex:(NSUInteger)recoveryOptionIndex
                        delegate:(id)delegate
              didRecoverSelector:(SEL)didRecoverSelector
                     contextInfo:(void *)contextInfo;
{
    if ([error.domain isEqualToString:NXOAuth2HTTPErrorDomain] && error.code == 413) {
        if (recoveryOptionIndex == 1) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://help.soundcloud.com/"]];
        } else {
            [self cancel:self];
        }
    }
}

@end
