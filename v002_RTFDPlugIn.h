//
//  v002_RTFDPlugIn.h
//  v002 RTFD
//
//  Created by vade on 5/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "v002RTFDProvider.h"

@interface v002_RTFDPlugIn : QCPlugIn
{
    v002RTFDProvider *provider;
    OSSpinLock _providerLock;
	
	// Fuck Obj-C 32 runtime
	NSTextStorage * drawString;
	NSLayoutManager *layoutManager;
	NSTextContainer *textContainer;
	CGFloat stringSize;
	BOOL antialias;
	BOOL fontSmoothing;
	NSUInteger width;
	NSUInteger height;
	double scroll;
	CFStringTokenizerRef wordTokenizer;
	CFStringTokenizerRef sentenceTokenizer;
	CFStringTokenizerRef paragraphTokenizer;
	CFStringTokenizerRef lineTokenizer;
	NSMutableArray* wordArray;
	NSMutableArray* sentenceArray;
	NSMutableArray* paragraphArray;
	NSMutableArray* lineArray;
	
	dispatch_queue_t rtfdQueue;
}

@property (copy) NSString* inputPath;
@property (assign) BOOL inputReload;
@property (assign) NSUInteger inputWidth;
@property (assign) NSUInteger inputHeight;
@property (assign) double inputScroll;
@property (assign) BOOL inputPageUp;
@property (assign) BOOL inputPageDown;
@property (assign) BOOL inputAntialias;
@property (assign) BOOL inputFontSmoothing;
@property (assign) BOOL inputAsyncronous;

@property (retain) id <QCPlugInOutputImageProvider> outputImage;

@property (retain) NSString* outputString;
@property (retain) NSArray* outputWords;
@property (retain) NSArray* outputSentences;
@property (retain) NSArray* outputLineEndings;
@property (retain) NSArray* outputParagraphs;

@property (copy) NSString* outputCurrentWord;
@property (copy) NSString* outputCurrentSentence;
@property (copy) NSString* outputCurrentLineEnding;
@property (copy) NSString* outputCurrentParagraph;

@end