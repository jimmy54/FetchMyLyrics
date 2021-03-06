/*******************************************************************************
 * FMLAZLyricsOperation.m
 * FetchMyLyrics
 *
 * Copyright (C) 2011 by Le Son.
 * Licensed under the MIT License, bundled with the source or available here:
 *     https://raw.github.com/precocity/FetchMyLyrics/master/LICENSE
 ******************************************************************************/

#import "FMLAZLyricsOperation.h"

#import "FMLCommon.h"

@implementation FMLAZLyricsOperation

@synthesize title = _title;
@synthesize artist = _artist;
@synthesize lyrics = _lyrics;

#pragma mark Initialization
/*
 * Function: Initialization.
 * Note    : No one calls -init nowadays.
 */
- (id)init
{
    if ((self = [super init]))
    {
        _title = nil;
        _artist = nil;
        _lyrics = nil;

        _pool = nil;
        
        _executing = NO;
        _finished = NO;
    }

    return self;
}

/*
 * Function: Convenience constructor.
 */
+ (id)operation
{
    return [[[self alloc] init] autorelease];
}

#pragma mark Task
/*
 * Function: Start operation.
 *           Spawns new thread.
 */
- (void)start
{
    // If operation is cancelled, return
    if ([self isCancelled])
    {
        // Mark operation as finished
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];

        return;
    }

    // Begin execution
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main)
                             toTarget:self
                           withObject:nil];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

/*
 * Function: Fetch the lyrics.
 */
- (void)main
{
    _pool = [[NSAutoreleasePool alloc] init];
    
    @try
    {
        // FIRST STEP: URL.

        // Periodic check.
        if ([self isCancelled])
            return;

        NSError *error = NULL;
        NSRegularExpression *nonAlphanumericRegex = [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z0-9]*"
                                                                                     options:NSRegularExpressionCaseInsensitive
                                                                                       error:&error];
        if (error)
            return;

        NSString *titleForURL = [nonAlphanumericRegex stringByReplacingMatchesInString:[self.title lowercaseString]
                                                                               options:0
                                                                                 range:NSMakeRange(0, [self.title length])
                                                                          withTemplate:@""];
        NSString *artistForURL = [nonAlphanumericRegex stringByReplacingMatchesInString:[self.artist lowercaseString]
                                                                                options:0
                                                                                  range:NSMakeRange(0, [self.artist length])
                                                                           withTemplate:@""];
        NSString *URLStringToPage = [@"http://www.azlyrics.com/lyrics/" stringByAppendingFormat:@"%@/%@.html", artistForURL, titleForURL];
        NSURL *URLToPage = [NSURL URLWithString:URLStringToPage];

        // SECOND STEP: Fetch lyrics
        // Fetch lyrics page
        NSData *data = [NSData dataWithContentsOfURL:URLToPage];

        // Periodic check.
        if ([self isCancelled])
            return;

        if (data)
        {
            NSString *pageHTML = [[[NSString alloc] initWithData:data
                                                        encoding:NSUTF8StringEncoding] autorelease];
            // The lyrics is conveniently located between two comments.
            // \s stands for whitespace while \S stands for non-whitespace (dunno why I can't use . here)
            NSRegularExpression *lyricsExtractionRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:<!-- start of lyrics -->)([\\s\\S]*)(?:<!-- end of lyrics -->)"
                                                                                                   options:(NSRegularExpressionCaseInsensitive||NSRegularExpressionDotMatchesLineSeparators)
                                                                                                     error:nil];
            __block NSString *untidiedLyrics = nil;
            [lyricsExtractionRegex enumerateMatchesInString:pageHTML
                                                    options:0
                                                      range:NSMakeRange(0, [pageHTML length])
                                                 usingBlock:
                ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
                {
                    NSRange matchRange = [result rangeAtIndex:1];
                    untidiedLyrics = [pageHTML substringWithRange:matchRange];
                }];

            if (untidiedLyrics)
            {
                NSRegularExpression *tidyRegex = [NSRegularExpression regularExpressionWithPattern:@"(^\\s+)|(<.*>)|(\\s+$)"
                                                                                           options:NSRegularExpressionCaseInsensitive
                                                                                             error:nil];
                self.lyrics = [tidyRegex stringByReplacingMatchesInString:untidiedLyrics
                                                                  options:0
                                                                    range:NSMakeRange(0, [untidiedLyrics length])
                                                             withTemplate:@""];
            }
        }
    }
    @catch (id e)
    {
        DebugLog(@"DUN DUN DUN EXCEPTION: %@", e);
    }
    @finally
    {
        [self completeOperation];
    }
}

/*
 * Function: Wrap up the task.
 */
- (void)completeOperation
{
    // Mark task as finished
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];

    _finished = YES;
    _executing = NO;

    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];

    // Release autorelease pool if it exists
    if (_pool)
    {
        [_pool release];
        _pool = nil;
    }

    // Publish to notification center
    if (self.lyrics)
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.title,  @"title",
                                                                            self.artist, @"artist",
                                                                            self.lyrics, @"lyrics", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FMLOperationDidReturnWithLyrics"
                                                            object:nil
                                                          userInfo:userInfo];
    }
}

/*
 * These methods are necessary to mark our task as concurrent.
 */
- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return _executing;
}

- (BOOL)isFinished
{
    return _finished;
}

#pragma mark Deallocation
- (void)dealloc
{
    self.title = nil;
    self.artist = nil;
    self.lyrics = nil;

    [super dealloc];
}

@end
