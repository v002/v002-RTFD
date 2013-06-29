//
//  v002_RTFDPlugIn.h
//  v002 RTFD
//
//  Created by vade on 5/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <Appkit/Appkit.h>
#import <OpenGL/OpenGL.h>
#import <libkern/OSAtomic.h>
#import "v002RTFDProvider.h"

@interface v002_RTFDPlugIn : QCPlugIn

@property (strong) NSString* inputPath;
@property (assign) BOOL inputReload;
@property (assign) NSUInteger inputWidth;
@property (assign) NSUInteger inputHeight;
@property (assign) double inputScroll;
@property (assign) BOOL inputPageUp;
@property (assign) BOOL inputPageDown;
@property (assign) BOOL inputAntialias;
@property (assign) BOOL inputFontSmoothing;
@property (assign) BOOL inputAsyncronous;

@property (strong) id <QCPlugInOutputImageProvider> outputImage;

@property (strong) NSString* outputString;
@property (strong) NSArray* outputWords;
@property (strong) NSArray* outputSentences;
@property (strong) NSArray* outputLineEndings;
@property (strong) NSArray* outputParagraphs;

@property (copy) NSString* outputCurrentWord;
@property (copy) NSString* outputCurrentSentence;
@property (copy) NSString* outputCurrentLineEnding;
@property (copy) NSString* outputCurrentParagraph;

@end

@interface v002_RTFDPlugIn (Execution)
- (void) asyncCreateOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger) w height:(NSUInteger)h;
- (void) serialCreateOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger) w height:(NSUInteger)h;
- (void) createOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger) width height:(NSUInteger)height;
@end