# SoundCloud Desktop Sharing Kit 


## Intro

The Desktop Sharing Kit comes as a separate application that your application to which your application can hand over an audio file. You can find [it on GitHub](https://github.com/soundcloud/osx-sharing).


## How To

### Installation

A good first step is to clone the Repository of github.

  - `git clone --recursive git://github.com/soundcloud/osx-sharing.git`

Simple as that. Make sure to include the `--recursive` option to have git fetch the submodules. If you forgot the `--recursive` you can do a manual `git submodule update --init --recursive` inside the project folder.


### Confiuguration

To share to SoundCloud you need to [register your app](http://soundcloud.com/you/apps/new) witg SoundCloud.

![Register your app](https://img.skitch.com/20120403-duw5h9mfabxeewscqq6q2cqs1f.png "Register your app")

While registering your app you'll get a client ID and secret. You also need to specify a redirect URL as in the screen shot.
Enter those values in the [AppConstants.h](SCDesktopSharingKit/SCDesktopSharingKit/AppConstants.html) file and remove the line that start's with `#error`.

Now you can compile the App by selecting `Share To SoundCloud` as the build target and using Xcodes _Archive_ feature.

![Product Archive](https://img.skitch.com/20120403-g8pxjacb8d7subxmp7626kkbk3.png "Build the app")


### Bundling

Once you created an archive it appears in Xcodes organizer from where you can export the app using the _Distribute..._ function (_Save Build Products_).

![Distribute via the Organizer](https://img.skitch.com/20120403-b6t8g2hfe1ds23iwthwru5xjrb.png "Distribute via the Organizer")

In the resulting folder you'll find the _Share on SoundCloud_ application. Take that application and embed it inside your app by draging it into your Xcode project and checking the _copy items into destination_ checkbox.


### Using

Once you've added _Share on SoundCloud_ to your application you can call it via it's command line interface.


#### The Command line interface

We use `open --new` as an easy way to open multiple instances of the same application. This way you can have multiple parallel uploads running. The arguments to the app are passed after open's `--args`.

    open "Share on SoundCloud.app" --new --args \
      -track\[asset_data\] my-song.wav \
      -track\[artwork_asset_data\] artwork.jpg \
      -track\[title\] "Toast Song"

The arguments you can pass into the app are:

- `client_id`: Manually pass in a client ID if you don't want to store it inside the application
- `client_secret`: The same for the client secret
- `redirect_uri`: And the redirect URI
- `track[asset_data]`: The path to the sound
- `track[title]`: The title
- `track[license]`: The license
- `track[tag_list]`: A space seperated list of tags
- `track[artwork_data]`: The path to an artwork file

There are more options you can pass in via track[...] arguments. See the complete list on the [SoundCloud developer documentation](http://developers.soundcloud.com/docs/api/tracks).


#### Calling the app from your Cocoa code

Here's a short example how you could call the app from within your code.

    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-track[asset_data]", @"my-song.wav",
                          @"-track[artwork_asset_data]", @"artwork.jpg",
                          @"-track[title]", @"Toast Song",
                          nil];
    
    NSError *error = nil;
    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Share on SoundCloud" ofType:@"app"]]
                                                  options:NSWorkspaceLaunchNewInstance
                                            configuration:[NSDictionary dictionaryWithObject:arguments forKey:NSWorkspaceLaunchConfigurationArguments]
                                                    error:&error];
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }


### Support

You're very welcome to fork this project and send us pull requests. Also if you're running into issues feel free to post a question on [StackOverflow](http://stackoverflow.com/tags/soundcloud) using the SoundCloud tag.