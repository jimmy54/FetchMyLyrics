/*******************************************************************************
 * FMLHook.xm
 * FetchMyLyrics
 *
 * Copyright (C) 2011 by Le Son.
 * Licensed under the MIT License, bundled with the source or available here:
 *     https://raw.github.com/precocity/FetchMyLyrics/master/LICENSE
 ******************************************************************************/

#import <Foundation/Foundation.h>
#import <objc-runtime.h>

#import "FMLController.h"
#import "FMLCommon.h"
#import "NSObject+InstanceVariable.h"

%group iOS5

%hook MediaApplication

/*
 * Hook: - [MediaApplication application:didFinishLaunchingWithOptions:]
 * Goal: Initialize an instance of FMLController to be used later.
 *       Will delegate most of the initialization to another thread
 *       to avoid locking the UI up.
 */
- (BOOL)application:(id)arg1 didFinishLaunchingWithOptions:(id)arg2
{
    // I don't even know why this method's return type is BOOL,
    // what a load of BOOLcrap.

    [[FMLController sharedController] setup];

    return %orig;
}

/*
 * Hook: - [MediaApplication applicationDidBecomeActive:]
 * Goal: Reload the displayable text view every time the application
 *       becomes active, in case the user disables FML via Settings.app.
 */
- (void)applicationDidBecomeActive:(id)arg1
{
    %orig;
    [[FMLController sharedController] reloadDisplayableTextViewForSongTitle:nil artist:nil];
}

%end // %hook MediaApplication

%hook MPQueueFeeder

/*
 * Hook  : - [MPQueueFeeder itemForIndex:]
 * Goal  : Hijack this method to notify FMLController of upcoming now playing items
 *         so that the controller can start lyrics fetching operations.
 * Caveat: Still not sure if this is the right place to hook.
 */
- (id)itemForIndex:(unsigned int)index
{
    id item = %orig;
    [[FMLController sharedController] handleSongWithNowPlayingItem:item];

    return item;
}

%end // %hook MPQueueFeeder

%hook IUMediaQueryNowPlayingItem

/*
 * Hook: - [IUMediaQueryNowPlayingItem displayableText]
 * Goal: Provide our own version of the lyrics if the song has none. 
 * Note: This method is triggered whenever a notification with name
 *       "MPAVItemDisplayableTextAvailableNotification" is posted (through
 *       NSNotificationCenter). Thus, whenever a lyrics-fetching task is complete,
 *       it will post a notification with this name to update the UI.
 *       Took me a few days to find out about this.
 */
- (id)displayableText
{
    NSString *lyrics = (NSString *)%orig;
    if (lyrics == nil)
    {
        // Only replace lyrics with our own if there's no lyrics in user's library
        // TODO: Preference to pick between iTunes library lyrics and only ours
        if (![self respondsToSelector:@selector(mediaItem)]) return nil;
        id mediaItem = objc_msgSend(self, @selector(mediaItem));
        if (![mediaItem respondsToSelector:@selector(valueForProperty:)]) return nil;
        NSString *title = (NSString *)objc_msgSend(mediaItem, @selector(valueForProperty:), @"title");
        NSString *artist = (NSString *)objc_msgSend(mediaItem, @selector(valueForProperty:), @"artist");
        return [[FMLController sharedController] lyricsForSongWithTitle:title artist:artist];
    }

    return lyrics;
}

%end // %hook IUMediaQueryNowPlayingItem

%end // %group iOS5



/*
 * This group contains test code, not indended for production.
 */
/*
%group Testing

%hook IUNowPlayingPortraitViewController

- (void)viewDidAppear:(BOOL)arg1
{
    %orig;

    id __mainController = [self objectInstanceVariable:@"_mainController"];
    id view = objc_msgSend(__mainController, @selector(view));

	CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
	CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
	CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;    
    [(UIView *)view layer].borderColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f].CGColor;
    [(UIView *)view layer].borderWidth = 3.0f;

    DebugLog(@"Main controller: %@", __mainController);
    DebugLog(@"View: %@", view);
}

%end

%hook IUNowPlayingAlbumFrontViewController

- (void)swipableView:(id)arg1 tappedWithCount:(NSUInteger)arg2
{
    // FREE TAP GESTURE RECOGNITION!
    // Plan: Hook here to activate edit mode
    DebugLog(@"About me: %@", self);
    DebugLog(@"Args: %@   %i", arg1, arg2);
    %orig;

    DebugLog(@"Parent view controller: %@", objc_msgSend(self, @selector(parentViewController)));

    // Note: MPPortraitTransportControls: play/pause/next/back/volume bar
    //       IUNowPlayingPortraitInfoOverlay: lyrics + scrubber
    //       MPTextView: lyrics
}

%end

%hook MPPortraitControlsOverlay

- (id)initWithFrame:(CGRect)frame
{
    id view = %orig;

	CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
	CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
	CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;    
    [view layer].borderColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f].CGColor;
    [view layer].borderWidth = 3.0f;

    return view;
}

%end

%hook MPPortraitTransportControls

- (id)initWithFrame:(CGRect)frame
{
    id view = %orig;

	CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
	CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
	CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;    
    [view layer].borderColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f].CGColor;
    [view layer].borderWidth = 3.0f;

    return view;
}

%end

%end*/ // %group Testing

/*
 * Initialization.
 */
%ctor
{
    NSString *iOSVersion = [[UIDevice currentDevice] systemVersion];
    if ([iOSVersion compare:@"5.0" options:NSNumericSearch] != NSOrderedAscending)
        %init(iOS5);
        //%init(Testing);
}

// Hey, if you're a college admission officer reading this source code
// because you found a mention to this tweak in one of my essays,
// THANK YOU FINE SIR/MADAM, LET ME OFFER YOU THIS BIG HUG.
// *hugs*
