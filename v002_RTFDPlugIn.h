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
{
    dispatch_queue_t rtfdQueue;
    
    v002RTFDProvider *provider;
    
    NSTextStorage* drawString;    
    NSLayoutManager *layoutManager; 
    NSTextContainer *textContainer; 
    
    CGFloat stringSize;
    OSSpinLock _providerLock;
        
    NSUInteger width;
    NSUInteger height;
    double scroll;
    
    BOOL antialias;
    BOOL fontSmoothing;
}

- (v002RTFDProvider *)newProvider;
- (void)setAvailableProvider:(v002RTFDProvider *)provider;
//@property (retain) NSAttributedString* drawString;

@property (retain) NSTextStorage * drawString;
@property (retain) NSLayoutManager *layoutManager; 
@property (retain) NSTextContainer *textContainer; 
@property (readwrite) CGFloat stringSize;
@property (readwrite, assign) BOOL antialias;
@property (readwrite, assign) BOOL fontSmoothing;

@property (assign) NSUInteger width;
@property (assign) NSUInteger height;
@property (assign) double scroll;

@property (assign) NSString* inputPath;
@property (assign) BOOL inputReload;
@property (assign) NSUInteger inputWidth;
@property (assign) NSUInteger inputHeight;
@property (assign) double inputScroll;
@property (assign) BOOL inputPageUp;
@property (assign) BOOL inputPageDown;
@property (assign) BOOL inputAntialias;
@property (assign) BOOL inputFontSmoothing;
@property (assign) BOOL inputAsyncronous;

@property (assign) id <QCPlugInOutputImageProvider> outputImage;

@end

@interface v002_RTFDPlugIn (Execution)
- (void) asyncCreateOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger) w height:(NSUInteger)h;
- (void) serialCreateOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger) w height:(NSUInteger)h;
- (void) createOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger) width height:(NSUInteger)height;
@end