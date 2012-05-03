//
//  v002RTFDProvider.h
//  v002 RTFD
//
//  Created by Tom on 19/07/2011.
//  Copyright 2011 Tom Butterworth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import <OpenGL/OpenGL.h>

@interface v002RTFDProvider : NSObject <QCPlugInOutputImageProvider> {
@private
    NSBitmapImageRep *_imageRep;
}
- (id)initWithBitmapImageRep:(NSBitmapImageRep *)imageRep;
@end
