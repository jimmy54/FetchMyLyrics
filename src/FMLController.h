/*******************************************************************************
 * FMLController.h
 * FetchMyLyrics
 *
 * Copyright (C) 2011 by Le Son.
 * Licensed under the MIT License, bundled with the source or available here:
 *     https://raw.github.com/precocity/FetchMyLyrics/master/LICENSE
 ******************************************************************************/

#import <Foundation/Foundation.h>

@class FMLLyricsWrapper, FMLOperation, FMLLyricsWikiOperation, FMLAZLyricsOperation, FMLAZLyricsOperation;

@interface FMLController : NSObject {
    NSOperationQueue *_lyricsFetchOperationQueue;
    NSMutableArray *_lyricsWrappers;

    id _currentInfoOverlay;

    BOOL _ready;
}

- (void)handleSongWithNowPlayingItem:(id)item;
- (NSString *)lyricsForSongWithTitle:(NSString *)title
                              artist:(NSString *)artist;
- (void)operationReportsAvailableLyrics:(FMLOperation *)operation;

- (void)readFromLyricsStorageFile;
- (void)writeToLyricsStorageFile;

- (void)setCurrentInfoOverlay:(id)overlay;
- (void)ridCurrentInfoOverlay;
- (void)reloadDisplayableTextView;

+ (id)sharedController;
- (void)setup;
@end
