//
//  v002_RTFDPlugIn.m
//  v002 RTFD
//
//  Created by vade on 5/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "v002_RTFDPlugIn.h"

#define	kQCPlugIn_Name				@"v002 RTFD"
#define	kQCPlugIn_Description		@"v002 RTFD description"
#define	kQCPlugIn_Category          [NSArray arrayWithObject:@"v002"]

@implementation v002_RTFDPlugIn

@synthesize drawString;
@synthesize layoutManager;
@synthesize textContainer;
@synthesize stringSize;
@synthesize width;
@synthesize height;
@synthesize scroll;
@synthesize antialias;
@synthesize fontSmoothing;

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

+ (NSDictionary*) attributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey,
            kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, 
            kQCPlugIn_Category, @"categories", nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{	
    
	if([key isEqualToString:@"inputPath"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Path", QCPortAttributeNameKey, nil];
	}

    if([key isEqualToString:@"inputReload"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Reload File", QCPortAttributeNameKey, nil];
	}

    if([key isEqualToString:@"inputWidth"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Width", QCPortAttributeNameKey,
                [NSNumber numberWithUnsignedInteger:1], QCPortAttributeMinimumValueKey,
                [NSNumber numberWithUnsignedInteger:640], QCPortAttributeDefaultValueKey, nil];
	}

    if([key isEqualToString:@"inputHeight"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Height", QCPortAttributeNameKey,
                [NSNumber numberWithUnsignedInteger:1], QCPortAttributeMinimumValueKey,
                [NSNumber numberWithUnsignedInteger:480], QCPortAttributeDefaultValueKey, nil];
	}

    if([key isEqualToString:@"inputScroll"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Scroll", QCPortAttributeNameKey,
                [NSNumber numberWithDouble:0], QCPortAttributeMinimumValueKey,
                [NSNumber numberWithDouble:1], QCPortAttributeMaximumValueKey,
                [NSNumber numberWithDouble:0], QCPortAttributeDefaultValueKey, nil];
	}
    
    if([key isEqualToString:@"inputPageUp"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Page Up", QCPortAttributeNameKey, nil];
	}
    
    if([key isEqualToString:@"inputPageDown"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Page Down", QCPortAttributeNameKey, nil];
	}

    if([key isEqualToString:@"inputAsyncronous"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Asyncronous Rendering", QCPortAttributeNameKey, nil];
	}

    if([key isEqualToString:@"inputAntialias"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Antialias", QCPortAttributeNameKey, nil];
	}

    if([key isEqualToString:@"inputFontSmoothing"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Font Smoothing", QCPortAttributeNameKey, nil];
	}

    if([key isEqualToString:@"outputImage"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Image", QCPortAttributeNameKey, nil];
	}
    
    return nil;
}

+ (NSArray*) sortedPropertyPortKeys
{
    return [NSArray arrayWithObjects:@"inputPath",
            @"inputReload",
            @"inputScroll",
            @"inputWidth",
            @"inputHeight",
            @"inputPageUp",
            @"inputPageDown",
            @"inputAsyncronous"
            @"inputAntialias",
            @"inputFontSmoothing",
            @"outputImage", nil];
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
        rtfdQueue = dispatch_queue_create("info.v002.rtfdQueue", NULL);
                
        _providerLock = OS_SPINLOCK_INIT;
	}
	
	return self;
}

- (void) finalize
{
    dispatch_release(rtfdQueue);
	[super finalize];
}

- (void) dealloc
{
    dispatch_release(rtfdQueue);
    
    self.drawString = nil;
	[super dealloc];
}

- (v002RTFDProvider *)newProvider
{
    OSSpinLockLock(&_providerLock);
    v002RTFDProvider *result = provider;
    provider = nil;
    OSSpinLockUnlock(&_providerLock);
    return result;
}

- (void)setAvailableProvider:(v002RTFDProvider *)prov
{
    [prov retain];
    OSSpinLockLock(&_providerLock);
    [provider release];
    provider = prov;
    OSSpinLockUnlock(&_providerLock);
}

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
        self.drawString = [[[NSTextStorage alloc] initWithPath:self.inputPath documentAttributes:NULL] autorelease];
        
        // TODO: this could probably be optimized away.
        self.stringSize = [self.drawString size].height;
    
        self.layoutManager = [[[NSLayoutManager alloc] init] autorelease];
        [self.layoutManager setUsesScreenFonts:NO];

        self.textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(self.inputWidth, FLT_MAX)] autorelease];        
        
        [self.layoutManager addTextContainer:self.textContainer];
        
        [self.drawString addLayoutManager:self.layoutManager];

        // Force layout calculation (?)
        [self.layoutManager glyphRangeForTextContainer:self.textContainer];
    }
    
    if([self didValueForInputKeyChange:@"inputAntialias"])
        self.antialias = self.inputAntialias;

    if([self didValueForInputKeyChange:@"inputWidth"])
        [self.textContainer setContainerSize:NSMakeSize(self.inputWidth, FLT_MAX)];
    
    if([self didValueForInputKeyChange:@"inputWidth"] || [self didValueForInputKeyChange:@"inputHeight"] || [self didValueForInputKeyChange:@"inputScroll"]
       || [self didValueForInputKeyChange:@"inputPageUp"] || [self didValueForInputKeyChange:@"inputPageDown"] )
    {        
        
        if([self didValueForInputKeyChange:@"inputPageUp"])
        {
            double pageFactor =  self.inputHeight/self.stringSize;
            
            self.scroll = self.scroll - pageFactor;
            NSLog(@"Scroll, %f, factor %f", self.scroll, pageFactor);
        }
        else if([self didValueForInputKeyChange:@"inputPageDown"])
        {
            double pageFactor =  self.inputHeight/self.stringSize;
            
            self.scroll = self.scroll + pageFactor;
            
            NSLog(@"Scroll, %f, factor %f", self.scroll, pageFactor);
        }
            self.scroll = self.inputScroll;

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
    
    v002RTFDProvider *prov = [self newProvider]; // returns retained
    if (prov)
    {
        self.outputImage = prov;
        [prov release];
    }

	return YES;
}

- (void) asyncCreateOutputImageWithContext:(id <QCPlugInContext>)context width:(NSUInteger)w height:(NSUInteger)h
{
    // Use our own queue, so we have asyncronous, but serial provider creation.
    // we use our own background GL context to do our uploading. Yay and shit.

    dispatch_async(rtfdQueue, ^{
    
        [self createOutputImageWithContext:context width:w height:h];
        
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
        NSPoint drawPoint = NSMakePoint(0, -(self.scroll * self.stringSize ));
        NSRect rect =  NSMakeRect(0, (self.scroll * self.stringSize), w, h);
        
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
        
        CGContextSetAllowsFontSmoothing([flipped graphicsPort], fontSmoothing);
        CGContextSetAllowsFontSubpixelPositioning([flipped graphicsPort], fontSmoothing);
        CGContextSetAllowsFontSubpixelQuantization([flipped graphicsPort], fontSmoothing);
        
        
        
        // This is slower. Layout Manager is the way to go.
        // This nets us 80% CPU for our test text - however justification is correct.
        //[self.drawString drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin];

        // This might be optimizable more? This gets us ~ 40% CPU for our test text
        //NSRange glyphRange = [self.layoutManager glyphRangeForTextContainer:self.textContainer];

        // Only give us the glyphs we need for our rect. ~15 - 30% CPU for our test text 
        NSRange glyphRange = [self.layoutManager glyphRangeForBoundingRect:rect inTextContainer:self.textContainer];
        
        //[self.layoutManager ensureLayoutForBoundingRect:rect inTextContainer:self.textContainer];
        //[self.layoutManager ensureGlyphsForGlyphRange:glyphRange];
        
        // Possibly even better?
        //NSRange glyphRange = [self.layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:rect inTextContainer:self.textContainer];
        
        [self.layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:drawPoint];
        [self.layoutManager drawGlyphsForGlyphRange: glyphRange atPoint:drawPoint];
                        
        [NSGraphicsContext restoreGraphicsState];
        
        v002RTFDProvider *prov = [[v002RTFDProvider alloc] initWithBitmapImageRep:bitmapImage];
        [self setAvailableProvider:prov];
        [prov release];
    }
    [bitmapImage release];
}

@end
