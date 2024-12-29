//
//  AZImage.h
//  Azoth
//
//  Created by Simon Gornall on 12/28/24.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum
	{
	AZImageFormatJPEG	= 0,
	AZImageFormatPNG,
	AZImageFormatFAST,

	AZImageFormatMax
	} AZImageFormat;

@interface AZImage : NSObject

/*****************************************************************************\
|* Initialisation: Don't create images manually, call one of the convenience
|* classes below
\*****************************************************************************/
- (instancetype) init NS_UNAVAILABLE;

/*****************************************************************************\
|* Initialisation: Load an image from the current bundle's Resources/ directory
\*****************************************************************************/
+ (AZImage *) imageNamed:(NSString *)name;

/*****************************************************************************\
|* Initialisation: Get an image from the icon atlas
\*****************************************************************************/
+ (AZImage *) imageWithSystemSymbolName:(NSString *)name;

/*****************************************************************************\
|* Initialisation: Load an image from a file path
\*****************************************************************************/
+ (AZImage *) imageWithContentsOfFile:(NSString *)path;

/*****************************************************************************\
|* Initialisation: Create an image with a GPU texture of a given size
\*****************************************************************************/
+ (AZImage *) imageWithSize:(NSSize) size;

/*****************************************************************************\
|* Initialisation: Get an image from the icon atlas
\*****************************************************************************/
+ (AZImage *) imageWithSize:(NSSize) size
			 drawingHandler:(BOOL (^)(NSRect dstRect)) drawingHandler;



/*****************************************************************************\
|* Lock focus on the image, which internally creates the AZPainter that will
|* have this image as its context.
\*****************************************************************************/
- (void) lockFocus;

/*****************************************************************************\
|* Unlock focus. The renderer will return its focus to where it was focussed
|* before lockFocus was called. Note that this isn't a stack, it's just storing
|* the old value and restoring it.
\*****************************************************************************/
- (void) unlockFocus;

/*****************************************************************************\
|* Save the image to a path
\*****************************************************************************/
- (BOOL) saveAs:(NSString *)path inFormat:(AZImageFormat)format;


/*****************************************************************************\
|* Properties
\*****************************************************************************/
@end

NS_ASSUME_NONNULL_END
