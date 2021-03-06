//
//  v002_RTFDPlugIn.m
//  v002 RTFD
//
//  Created by vade on 5/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLMacro.h>
#import <Appkit/Appkit.h>
#import <libkern/OSAtomic.h>

#import "v002_RTFDPlugIn.h"



#define	kQCPlugIn_Name				@"v002 RTFD"
#define	kQCPlugIn_Description		@"v002 RTFD description"
#define	kQCPlugIn_Category          [NSArray arrayWithObject:@"v002"]

@interface v002_RTFDPlugIn ()

@property (atomic, readwrite, retain) v002RTFDProvider *provider;

@property (atomic, readwrite, assign) dispatch_queue_t rtfdQueue;

@property (atomic, readwrite, retain) NSTextStorage * drawString;
@property (atomic, readwrite, retain) NSLayoutManager *layoutManager;
@property (atomic, readwrite, retain) NSTextContainer *textContainer;
@property (atomic, readwrite, assign) CGFloat stringSize;
@property (atomic, readwrite, assign) BOOL antialias;
@property (atomic, readwrite, assign) BOOL fontSmoothing;

@property (atomic, readwrite, assign) NSUInteger width;
@property (atomic, readwrite, assign) NSUInteger height;
@property (atomic, readwrite, assign) double scroll;

@property (atomic, readwrite, assign) CFStringTokenizerRef wordTokenizer;
@property (atomic, readwrite, assign) CFStringTokenizerRef sentenceTokenizer;
@property (atomic, readwrite, assign) CFStringTokenizerRef paragraphTokenizer;
@property (atomic, readwrite, assign) CFStringTokenizerRef lineTokenizer;

@property (atomic, readwrite, retain) NSMutableArray* wordArray;
@property (atomic, readwrite, retain) NSMutableArray* sentenceArray;
@property (atomic, readwrite, retain) NSMutableArray* paragraphArray;
@property (atomic, readwrite, retain) NSMutableArray* lineArray;

//- (v002RTFDProvider *)newProvider;
//- (void)setAvailableProvider:(v002RTFDProvider *)provider;

@end

@interface v002_RTFDPlugIn (Execution)
- (void) asyncCreateOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger) w height:(NSUInteger)h;
- (void) serialCreateOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger) w height:(NSUInteger)h;
- (void) createOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger) width height:(NSUInteger)height;
@end

@implementation v002_RTFDPlugIn

@synthesize provider;
@synthesize rtfdQueue;

@synthesize drawString;
@synthesize layoutManager;
@synthesize textContainer;
@synthesize stringSize;
@synthesize antialias;
@synthesize fontSmoothing;

@synthesize width;
@synthesize height;
@synthesize scroll;

@synthesize wordTokenizer;
@synthesize sentenceTokenizer;
@synthesize paragraphTokenizer;
@synthesize lineTokenizer;

@synthesize wordArray;
@synthesize sentenceArray;
@synthesize paragraphArray;
@synthesize lineArray;

@dynamic inputPath;
@dynamic inputReload;
@dynamic inputWidth;
@dynamic inputHeight;
@dynamic inputScroll;
@dynamic inputPageUp;
@dynamic inputPageDown;
@dynamic inputAntialias;
@dynamic inputFontSmoothing;
@dynamic inputAsyncronous;

@dynamic outputImage;

@dynamic outputString;
@dynamic outputWords;
@dynamic outputSentences;
@dynamic outputLineEndings;
@dynamic outputParagraphs;

@dynamic outputCurrentWord;
@dynamic outputCurrentSentence;
@dynamic outputCurrentLineEnding;
@dynamic outputCurrentParagraph;

+ (NSDictionary*) attributes
{
	return @{QCPlugInAttributeNameKey: kQCPlugIn_Name,
            QCPlugInAttributeDescriptionKey: kQCPlugIn_Description, 
            @"categories": kQCPlugIn_Category};
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{	
	if([key isEqualToString:@"inputPath"])
	{
		return @{QCPortAttributeNameKey: @"Path"};
	}

    if([key isEqualToString:@"inputReload"])
	{
		return @{QCPortAttributeNameKey: @"Reload File"};
	}

    if([key isEqualToString:@"inputWidth"])
	{
		return @{QCPortAttributeNameKey: @"Width",
                QCPortAttributeMinimumValueKey: @1U,
                QCPortAttributeDefaultValueKey: @640U};
	}

    if([key isEqualToString:@"inputHeight"])
	{
		return @{QCPortAttributeNameKey: @"Height",
                QCPortAttributeMinimumValueKey: @1U,
                QCPortAttributeDefaultValueKey: @480U};
	}

    if([key isEqualToString:@"inputScroll"])
	{
		return @{QCPortAttributeNameKey: @"Scroll",
                QCPortAttributeMinimumValueKey: @0.0,
                QCPortAttributeMaximumValueKey: @1.0,
                QCPortAttributeDefaultValueKey: @0.0};
	}
    
    if([key isEqualToString:@"inputPageUp"])
	{
		return @{QCPortAttributeNameKey: @"Page Up"};
	}
    
    if([key isEqualToString:@"inputPageDown"])
	{
		return @{QCPortAttributeNameKey: @"Page Down"};
	}

    if([key isEqualToString:@"inputAsyncronous"])
	{
		return @{QCPortAttributeNameKey: @"Asyncronous Rendering"};
	}

    if([key isEqualToString:@"inputAntialias"])
	{
		return @{QCPortAttributeNameKey: @"Antialias"};
	}

    if([key isEqualToString:@"inputFontSmoothing"])
	{
		return @{QCPortAttributeNameKey: @"Font Smoothing"};
	}

    if([key isEqualToString:@"outputImage"])
	{
		return @{QCPortAttributeNameKey: @"Image"};
	}
	
	if([key isEqualToString:@"outputString"])
	{
		return @{QCPortAttributeNameKey: @"String"};
	}
	
	if([key isEqualToString:@"outputWords"])
	{
		return @{QCPortAttributeNameKey: @"Words"};
	}

	if([key isEqualToString:@"outputSentences"])
	{
		return @{QCPortAttributeNameKey: @"Sentences"};
	}
	
	if([key isEqualToString:@"outputLineEndings"])
	{
		return @{QCPortAttributeNameKey: @"Line Endings"};
	}

	if([key isEqualToString:@"outputParagraphs"])
	{
		return @{QCPortAttributeNameKey: @"Paragraphs"};
	}

	if([key isEqualToString:@"outputCurrentWord"])
	{
		return @{QCPortAttributeNameKey: @"Current String"};
	}
	
	if([key isEqualToString:@"outputCurrentSentence"])
	{
		return @{QCPortAttributeNameKey: @"Current Sentence"};
	}
	
	if([key isEqualToString:@"outputCurrentLineEnding"])
	{
		return @{QCPortAttributeNameKey: @"Current Line"};
	}

	if([key isEqualToString:@"outputCurrentParagraph"])
	{
		return @{QCPortAttributeNameKey: @"Current Paragraph"};
	}	
    
    return nil;
}

+ (NSArray*) sortedPropertyPortKeys
{
    return @[@"inputPath",
            @"inputReload",
            @"inputScroll",
            @"inputWidth",
            @"inputHeight",
            @"inputPageUp",
            @"inputPageDown",
            @"inputAsyncronous",
            @"inputAntialias",
            @"inputFontSmoothing",

            @"outputImage",
			@"outputString",
			@"outputWords",
			@"outputSentences",
			@"outputLineEndings",
			@"outputParagraphs",
			@"outputCurrentWord",
			@"outputCurrentSentence",
			@"outputCurrentLineEnding",
			@"outputCurrentParagraph"];
}


+ (QCPlugInExecutionMode) executionMode
{
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode) timeMode
{
	return kQCPlugInTimeModeNone;
}

- (id) init
{
    self = [super init];
	if(self)
    {
		wordTokenizer = NULL;
		paragraphTokenizer = NULL;
		sentenceTokenizer = NULL;
		lineTokenizer = NULL;
		
        rtfdQueue = dispatch_queue_create("info.v002.rtfdQueue", DISPATCH_QUEUE_SERIAL);
                
        _providerLock = OS_SPINLOCK_INIT;
	}
	
	return self;
}


- (void) dealloc
{
	//BUG IN CLIENT OF LIBDISPATCH: Release of a suspended object
	//	dispatch_suspend(rtfdQueue);

	dispatch_release(rtfdQueue);
	rtfdQueue = NULL;

	if(wordTokenizer)
		CFRelease(wordTokenizer);
	
	if(sentenceTokenizer)
		CFRelease(sentenceTokenizer);

	if(paragraphTokenizer)
		CFRelease(paragraphTokenizer);

	if(lineTokenizer)
		CFRelease(lineTokenizer);
	
	[super dealloc];
}

//- (v002RTFDProvider *)newProvider
//{
//    OSSpinLockLock(&_providerLock);
//    v002RTFDProvider *result = provider;
////	[provider release];
//    provider = nil;
//    OSSpinLockUnlock(&_providerLock);
//    return result;
//}
//
//- (void)setAvailableProvider:(v002RTFDProvider *)prov
//{
//    OSSpinLockLock(&_providerLock);
//    provider = prov;
//    OSSpinLockUnlock(&_providerLock);
//}

@end

@implementation v002_RTFDPlugIn (Execution)

- (BOOL) startExecution:(id<QCPlugInContext>)context
{	
	return YES;
}

- (void) enableExecution:(id<QCPlugInContext>)context
{
}

- (void) stopExecution:(id <QCPlugInContext>)context
{
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
    if([self didValueForInputKeyChange:@"inputPath"] || self.inputReload)
    {
//		NSDictionary* docAttributes = @{NSViewSizeDocumentAttribute : [NSValue valueWithSize:NSMakeSize(self.inputWidth, self.inputHeight)]};
		NSDictionary* docAttributes;
        self.drawString = [[[NSTextStorage alloc] initWithPath:self.inputPath documentAttributes:&docAttributes] autorelease];
        
		// get our string, and pull our token counts from it
		[self buildTokenArrays];
		
        // TODO: this could probably be optimized away.
        self.stringSize = [self.drawString size].height;
    
        self.layoutManager = [[[NSLayoutManager alloc] init] autorelease];
        [self.layoutManager setUsesScreenFonts:NO];
		[self.layoutManager setAllowsNonContiguousLayout:YES];
		
        self.textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(self.inputWidth, FLT_MAX)] autorelease];
        
        [self.layoutManager addTextContainer:self.textContainer];
        
        [self.drawString addLayoutManager:self.layoutManager];

        // Force layout calculation (?)
        [self.layoutManager glyphRangeForTextContainer:self.textContainer];
		
		self.outputString = self.drawString.string;
		self.outputWords = self.wordArray;
		self.outputSentences = self.sentenceArray;
		self.outputLineEndings = self.lineArray;
		self.outputParagraphs = self.paragraphArray;
		
		if([self.wordArray count])
			self.outputCurrentWord = [self.wordArray objectAtIndex:0];
	
		if([self.sentenceArray count])
			self.outputCurrentSentence = [self.sentenceArray objectAtIndex:0];

		if([self.lineArray count])
			self.outputCurrentLineEnding = [self.lineArray objectAtIndex:0];

		if([self.paragraphArray count])
			self.outputCurrentParagraph = [self.paragraphArray objectAtIndex:0];
    }
    
    if([self didValueForInputKeyChange:@"inputAntialias"])
        self.antialias = self.inputAntialias;

    if([self didValueForInputKeyChange:@"inputWidth"])
        [self.textContainer setContainerSize:NSMakeSize(self.inputWidth, FLT_MAX)];
    
    if([self didValueForInputKeyChange:@"inputWidth"] ||
	   [self didValueForInputKeyChange:@"inputHeight"] ||
	   [self didValueForInputKeyChange:@"inputScroll"] ||
	   [self didValueForInputKeyChange:@"inputPageUp"] ||
	   [self didValueForInputKeyChange:@"inputPageDown"] )
    {
		if([self didValueForInputKeyChange:@"inputScroll"])
		{
			self.scroll = self.inputScroll;
		}
		
        if([self didValueForInputKeyChange:@"inputPageUp"])
        {
            double pageFactor =  self.inputHeight/(self.stringSize * 2.0);
            self.scroll = self.scroll - pageFactor;
        }
        else if([self didValueForInputKeyChange:@"inputPageDown"])
        {
            double pageFactor =  self.inputHeight/(self.stringSize * 2.0);
            
            self.scroll = self.scroll + pageFactor;
        }
		
		NSUInteger scrollIndexForWord = (NSUInteger)(self.scroll * ((double)self.wordArray.count - 1));
		NSUInteger scrollIndexForSentence = (NSUInteger)(self.scroll * ((double)self.sentenceArray.count - 1));
		NSUInteger scrollIndexForLine = (NSUInteger)(self.scroll * ((double)self.lineArray.count - 1));
		NSUInteger scrollIndexForParagraph = (NSUInteger)(self.scroll * ((double)self.paragraphArray.count - 1));
		
		if([self.wordArray count] > scrollIndexForWord)
			self.outputCurrentWord = [self.wordArray objectAtIndex:scrollIndexForWord];
		
		if([self.sentenceArray count] > scrollIndexForSentence)
			self.outputCurrentSentence = [self.sentenceArray objectAtIndex:scrollIndexForSentence];
		
		if([self.lineArray count] > scrollIndexForLine)
			self.outputCurrentLineEnding = [self.lineArray objectAtIndex:scrollIndexForLine];

		if([self.paragraphArray count] > scrollIndexForParagraph)
			self.outputCurrentParagraph = [self.paragraphArray objectAtIndex:scrollIndexForParagraph];
		
		// I have no idea what this is about...
        if(self.inputWidth >=100 && self.inputHeight >= 100)
        {
            if(self.inputAsyncronous)
                [self asyncCreateOutputImageWithContext:context width:self.inputWidth height:self.inputHeight];
            else
                [self serialCreateOutputImageWithContext:context width:self.inputWidth height:self.inputHeight];
        }
        else
        {
            if(self.inputAsyncronous)
                [self asyncCreateOutputImageWithContext:context width:self.inputWidth height:self.inputHeight];
            else
                [self serialCreateOutputImageWithContext:context width:self.inputWidth height:self.inputHeight];
        }
    }
    
    v002RTFDProvider *prov = self.provider; // returns retained
    if (prov)
    {
        self.outputImage = prov;
    }

	return YES;
}

- (void) asyncCreateOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger)w height:(NSUInteger)h
{
    // Use our own queue, so we have asyncronous, but serial provider creation.
    // we use our own background GL context to do our uploading. Yay and shit.

	// Since we own our dispatch queue, and our queue will retain self, we ensure we dont have a temporary or weird retain cycle
	__block __weak v002_RTFDPlugIn* weakSelf = self;
    dispatch_async(rtfdQueue, ^
	{
		if(weakSelf)
		{
			__strong v002_RTFDPlugIn* strongSelf = weakSelf;
			[strongSelf createOutputImageWithContext:context width:w height:h];
		}
    });
}

- (void) serialCreateOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger) w height:(NSUInteger)h
{
    [self createOutputImageWithContext:context width:w height:h];
}

- (void) createOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger) w height:(NSUInteger)h
{
    
    NSBitmapImageRep* bitmapImage = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL 
                                                                pixelsWide:w 
                                                                pixelsHigh:h
                                                             bitsPerSample:8
                                                           samplesPerPixel:4 
                                                                  hasAlpha:YES
                                                                  isPlanar:NO
                                                            colorSpaceName:NSDeviceRGBColorSpace
                                                              bitmapFormat:0
                                                               bytesPerRow:0
                                                              bitsPerPixel:0];
        
    self.width = w;
    self.height = h;

    if(self.drawString && bitmapImage)
    {
        NSPoint drawPoint = NSMakePoint(0, -(self.scroll * (self.stringSize * 2.0) ));
        NSRect rect =  NSMakeRect(0, (self.scroll * (self.stringSize * 2.0)), w, h);
        
        [NSGraphicsContext saveGraphicsState];
        
        // Must supply flipped context for NSLayoutManagers drawing.
        NSGraphicsContext* flipped = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapImage];
        flipped = [NSGraphicsContext graphicsContextWithGraphicsPort:[flipped graphicsPort] flipped:YES];

        [NSGraphicsContext setCurrentContext:flipped]; 

        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:0 yBy:h];
        [transform scaleXBy:1.0 yBy:-1.0];
        [transform concat];

        [flipped setShouldAntialias:self.antialias];
        
        CGContextSetAllowsFontSmoothing([flipped graphicsPort], self.fontSmoothing);
        CGContextSetAllowsFontSubpixelPositioning([flipped graphicsPort], self.fontSmoothing);
        CGContextSetAllowsFontSubpixelQuantization([flipped graphicsPort], self.fontSmoothing);
        
        // This is slower. Layout Manager is the way to go.
        // This nets us 80% CPU for our test text - however justification is correct.
        //[self.drawString drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin];

        // This might be optimizable more? This gets us ~ 40% CPU for our test text
        //NSRange glyphRange = [self.layoutManager glyphRangeForTextContainer:self.textContainer];

        // Only give us the glyphs we need for our rect. ~15 - 30% CPU for our test text 
//        NSRange glyphRange = [self.layoutManager glyphRangeForBoundingRect:rect inTextContainer:self.textContainer];

		// Possibly even better?
        NSRange glyphRange = [self.layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:rect inTextContainer:self.textContainer];

//		[self.layoutManager ensureLayoutForBoundingRect:rect inTextContainer:self.textContainer];
//		[self.layoutManager ensureGlyphsForGlyphRange:glyphRange];
        
        
        [self.layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:drawPoint];
        [self.layoutManager drawGlyphsForGlyphRange: glyphRange atPoint:drawPoint];
                        
        [NSGraphicsContext restoreGraphicsState];
        
        v002RTFDProvider *prov = [[v002RTFDProvider alloc] initWithBitmapImageRep:bitmapImage];
		self.provider = prov;
		[prov release];
	}

	if(bitmapImage)
		[bitmapImage autorelease];
}

- (void) buildTokenArrays
{
	// reset all of our internal arrays
	self.wordArray = [NSMutableArray array];
	self.sentenceArray = [NSMutableArray array];
	self.paragraphArray = [NSMutableArray array];
	self.lineArray = [NSMutableArray array];
	
	CFLocaleRef locale = CFLocaleCopyCurrent();

	NSString* string = self.drawString.string;
	
	// Build our various tokenizer if we need to, otherwise re-assign them.
	
	// Word
	if(!wordTokenizer)
		wordTokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, (__bridge CFStringRef)(string), CFRangeMake(0, string.length), kCFStringTokenizerUnitWord, locale);
	else
		CFStringTokenizerSetString(self.wordTokenizer, (__bridge CFStringRef)(string), CFRangeMake(0, string.length));
	
	// Sentence
	if(!sentenceTokenizer)
		sentenceTokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, (__bridge CFStringRef)(string), CFRangeMake(0, string.length), kCFStringTokenizerUnitSentence, locale);
	else
		CFStringTokenizerSetString(self.sentenceTokenizer, (__bridge CFStringRef)(string), CFRangeMake(0, string.length));
	
	// Paragraph
	if(!paragraphTokenizer)
		paragraphTokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, (__bridge CFStringRef)(string), CFRangeMake(0, string.length), kCFStringTokenizerUnitParagraph, locale);
	else
		CFStringTokenizerSetString(self.paragraphTokenizer, (__bridge CFStringRef)(string), CFRangeMake(0, string.length));
	
	// Line
	if(!lineTokenizer)
		lineTokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, (__bridge CFStringRef)(string), CFRangeMake(0, string.length), kCFStringTokenizerUnitLineBreak, locale);
	else
		CFStringTokenizerSetString(self.lineTokenizer, (__bridge CFStringRef)(string), CFRangeMake(0, string.length));
	
	// Fill our arrays with the tokenizers output.
	
	// Word
	CFStringTokenizerTokenType tokenType = CFStringTokenizerAdvanceToNextToken(self.wordTokenizer);
	
	while(kCFStringTokenizerTokenNone != tokenType)
	{
		CFRange range = CFStringTokenizerGetCurrentTokenRange(self.wordTokenizer);
		
		NSRange tokenRange = NSMakeRange( range.location == kCFNotFound ? NSNotFound : range.location, range.length );
		
		[self.wordArray addObject:[string substringWithRange:tokenRange]];
		
		tokenType = CFStringTokenizerAdvanceToNextToken(self.wordTokenizer);
	}
	
	tokenType = CFStringTokenizerAdvanceToNextToken(self.sentenceTokenizer);
	
	while(kCFStringTokenizerTokenNone != tokenType)
	{
		CFRange range = CFStringTokenizerGetCurrentTokenRange(self.sentenceTokenizer);
		
		NSRange tokenRange = NSMakeRange( range.location == kCFNotFound ? NSNotFound : range.location, range.length );
		
		[self.sentenceArray addObject:[string substringWithRange:tokenRange]];
		
		tokenType = CFStringTokenizerAdvanceToNextToken(self.sentenceTokenizer);
	}
	
	tokenType = CFStringTokenizerAdvanceToNextToken(self.paragraphTokenizer);
	
	while(kCFStringTokenizerTokenNone != tokenType)
	{
		CFRange range = CFStringTokenizerGetCurrentTokenRange(self.paragraphTokenizer);
		
		NSRange tokenRange = NSMakeRange( range.location == kCFNotFound ? NSNotFound : range.location, range.length );
		
		[self.paragraphArray addObject:[string substringWithRange:tokenRange]];
		
		tokenType = CFStringTokenizerAdvanceToNextToken(self.paragraphTokenizer);
	}
	
	tokenType = CFStringTokenizerAdvanceToNextToken(self.lineTokenizer);
	
	while(kCFStringTokenizerTokenNone != tokenType)
	{
		CFRange range = CFStringTokenizerGetCurrentTokenRange(self.lineTokenizer);
		
		NSRange tokenRange = NSMakeRange( range.location == kCFNotFound ? NSNotFound : range.location, range.length );
		
		[self.lineArray addObject:[string substringWithRange:tokenRange]];
		
		tokenType = CFStringTokenizerAdvanceToNextToken(self.lineTokenizer);
	}
	
	if(locale)
		CFRelease(locale);}

@end

