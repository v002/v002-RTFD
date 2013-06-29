//
//  v002RTFDProvider.m
//  v002 RTFD
//
//  Created by Tom on 19/07/2011.
//  Copyright 2011 Tom Butterworth. All rights reserved.
//

#import "v002RTFDProvider.h"
#import <OpenGL/CGLMacro.h>

@implementation v002RTFDProvider

- (id)initWithBitmapImageRep:(NSBitmapImageRep *)imageRep
{
    self = [super init];
    if (self)
    {
        _imageRep = imageRep;
    }
    
    return self;
}



- (NSRect)imageBounds
{
	return (NSRect){{0.0, 0.0}, [_imageRep size]};
}

- (CGColorSpaceRef)imageColorSpace
{
	return [[_imageRep colorSpace] CGColorSpace];
}

- (BOOL)shouldColorMatch
{
	return YES;
}

- (NSArray *)supportedRenderedTexturePixelFormats
{
//    NSLog(@"%@", NSStringFromSelector(_cmd));
	NSArray *formats;
	switch ([[_imageRep colorSpace] colorSpaceModel])
	{
		case NSRGBColorSpaceModel:
			formats = @[QCPlugInPixelFormatBGRA8, QCPlugInPixelFormatARGB8, QCPlugInPixelFormatRGBAf];
			break;
		case NSGrayColorSpaceModel:
			formats = @[QCPlugInPixelFormatI8, QCPlugInPixelFormatIf];
			break;
		default:
			formats = nil;
			break;
	}
	return formats;
}

- (GLuint)copyRenderedTextureForCGLContext:(CGLContextObj)cgl_ctx pixelFormat:(NSString *)format bounds:(NSRect)bounds isFlipped:(BOOL *)flipped
{
//    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    NSSize imageSize = [_imageRep size];
    if ((bounds.origin.x + bounds.size.width > imageSize.width)
        || (bounds.origin.y + bounds.size.height > imageSize.height))
    {
        // TODO: this probably will actually happen with a transformation (eg crop) on the output,
        // and perhaps we should deal with it
        return 0;
    }
    
    NSUInteger bufferByteOffset = (bounds.origin.y * [_imageRep bytesPerRow]) + (bounds.origin.x * [_imageRep bitsPerPixel] / 8);
    
    glPushAttrib(GL_ALL_ATTRIB_BITS);
    glPushClientAttrib(GL_CLIENT_ALL_ATTRIB_BITS);
    
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    
    glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT,  [_imageRep bytesPerRow] * [_imageRep pixelsHigh], [_imageRep bitmapData]);
    
    GLuint name;
    glGenTextures(1, &name);
    glBindTexture (GL_TEXTURE_RECTANGLE_ARB, name);
    {
        glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
        glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_CACHED_APPLE);
        glPixelStorei(GL_UNPACK_ROW_BYTES_APPLE, [_imageRep bytesPerRow]);
        
        glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, bounds.size.width , bounds.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, [_imageRep bitmapData] + bufferByteOffset);
        
        glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_PRIVATE_APPLE);
        glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_FALSE);
    }
    glPopClientAttrib();
    glPopAttrib();
    
    *flipped = YES;
    
    return name;
}

- (void)releaseRenderedTexture:(GLuint)name forCGLContext:(CGLContextObj)cgl_ctx
{
//    NSLog(@"%@", NSStringFromSelector(_cmd));
    glDeleteTextures(1, &name);
}

- (BOOL)canRenderWithCGLContext:(CGLContextObj)cgl_ctx
{
//    NSLog(@"%@", NSStringFromSelector(_cmd));
	return NO;
}

- (BOOL)renderWithCGLContext:(CGLContextObj)cgl_ctx forBounds:(NSRect)bounds
{
//    NSLog(@"%@", NSStringFromSelector(_cmd));
	return NO;
}

- (NSArray *)supportedBufferPixelFormats
{
    NSBitmapFormat bitmapFormat = [_imageRep bitmapFormat];
    
    NSArray *formats = nil;
    
    if ([_imageRep samplesPerPixel] == 4)
    {
        if (!(bitmapFormat & NSFloatingPointSamplesBitmapFormat))
        {
            if (bitmapFormat & NSAlphaFirstBitmapFormat)
            {
                formats = @[QCPlugInPixelFormatARGB8];
            }
            else
            {
                formats = @[QCPlugInPixelFormatBGRA8];
            }
        }
        else if (!(bitmapFormat & NSAlphaFirstBitmapFormat)) // RGBAf
        {
            formats = @[QCPlugInPixelFormatRGBAf];
        }
    }
    else if ([_imageRep samplesPerPixel] == 1)
    {
        if (bitmapFormat & NSFloatingPointSamplesBitmapFormat)
        {
            formats = @[QCPlugInPixelFormatIf];
        } else
        {
            formats = @[QCPlugInPixelFormatI8];
        }
    }
    
//    NSLog(@"%@ %@", NSStringFromSelector(_cmd), [formats lastObject]);

    return formats;
}

- (BOOL)renderToBuffer:(void*)baseAddress withBytesPerRow:(NSUInteger)rowBytes pixelFormat:(NSString*)format forBounds:(NSRect)bounds
{
//    NSLog(@"%@ %@ %@", NSStringFromSelector(_cmd), format, NSStringFromRect(bounds));
    
    NSSize buffSize = [_imageRep size];
    
    NSUInteger startY = bounds.origin.y;
    NSUInteger startX = bounds.origin.x;
    
    if (startY < buffSize.height && startX < buffSize.width)
    {
        NSUInteger endY = bounds.origin.y + bounds.size.height;
        if (endY > buffSize.height) endY = buffSize.height;
        
        NSUInteger endX = bounds.origin.x + bounds.size.width;
        if (endX > buffSize.width) endX = buffSize.width;
        
        NSUInteger rowCopyBytes = (endX - startX) * [_imageRep bitsPerPixel] / 8;
        NSUInteger rowInsetBytes = [_imageRep bitsPerPixel] * startX / 8;
        NSUInteger srcRowBytes = [_imageRep bytesPerRow];
        
        for (NSUInteger y = startY; y < endY; y++)
        {
            // The buffer starts with the bounds offset, so start from 0, 0 in the buffer space, but respect bounds width/height
            memcpy(baseAddress + (rowBytes * y), [_imageRep bitmapData] + (srcRowBytes * y) + rowInsetBytes, rowCopyBytes);
        }        
    }
    
	return YES;
}

@end
