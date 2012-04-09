# SoundCloud Desktop Sharing Kit for Mac OS
## Introduction

The Desktop Sharing Kit is a simple way to add Sharing to SoundCloud to your desktop application.
It comes as a seperate executable for Microsoft Windows and Mac OS that you can include in your application and invoke it from there to let the user share a sound to SoundCloud.

![Screenshot](http://dl.dropbox.com/u/12477597/Permanent/DesktopSharing/mac-sharing.png)

This README describes the Mac OS version. Head over [here to the Microsoft Windows version](https://github.com/soundcloud/soundcloud-win-sharing).

## Installation

You can either download the latest build from [GitHub](https://github.com/soundcloud/soundcloud-mac-sharing/downloads)
or compile it from source yourself. To clone the repository:

$ git clone --recursive git://github.com/soundcloud/soundcloud-mac-sharing.git

Simple as that. Make sure to include the --recursive option to have git fetch the submodules. If you forgot the --recursive you can do a manual git submodule update --init --recursive inside the project folder.

## Configuration

Head over to [SoundCloud to register an application](http://soundcloud.com/you/apps). If you plan to use the Windows version the redirect URI has to be set to
"http://connect.soundcloud.com/desktop", so best use this one in general.

You'll have to pass the client_id, client_secret and redirect_uri later when invoking the executable.
Alternatively you can also hardcode these values in AppConstants.h (remove the line that start's with #error as well) if you prefer to compile the app yourself.

To compile it just select "Share To SoundCloud" as the build target and use Xcodes Archive feature.
Once you created an archive it appears in Xcodes organizer from where you can export the app using the Distribute... function (Save Build Products).

## Usage

Once you've added executable to your application you can call it using it's command line interface.
We use open --new as an easy way to open multiple instances of the same application. This way you can have multiple parallel uploads running. The arguments to the app are passed after open's --args:

    open "Share on SoundCloud.app" --new --args \
      -client_id YOUR_CLIENT_ID \
      -client_secret SOME_CLIENT_SECRET \
      -redirect_uri http://connect.soundcloud.com/desktop \
      -track\[asset_data\] sound.wav \
      -track\[title\] "Test Sound"

The arguments you can pass into the app are:

* ``client_id``: Manually pass in a client ID if you don't want to store it inside the application
* ``client_secret``: The same for the client secret
* ``redirect_uri``: And the redirect URI
* ``track[asset_data]``: The path to the sound
* ``track[title]``: The title
* ``track[license]``: The license
* ``track[tag_list]``: A space seperated list of tags
* ``track[artwork_data]``: The path to an artwork file

There are more options you can pass in using the track[...] arguments. See the complete list inn the [SoundCloud developer documentation](http://developers.soundcloud.com/docs/api/tracks).

Here's a short example how you could call the app from within your Cocoa application:

    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-track[asset_data]", @"sound.wav",
                          @"-track[artwork_asset_data]", @"artwork.jpg",
                          @"-track[title]", @"Test Song",
                          nil];

    NSError *error = nil;
    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Share on SoundCloud.app" ofType:@"app"]]
                                                  options:NSWorkspaceLaunchNewInstance
                                            configuration:[NSDictionary dictionaryWithObject:arguments forKey:NSWorkspaceLaunchConfigurationArguments]
                                                    error:&error];
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }

## Support

You're very welcome to fork this project and send us pull requests. Also if you're running into issues feel free to [reach out to us](http://developers.soundcloud.com/support).
