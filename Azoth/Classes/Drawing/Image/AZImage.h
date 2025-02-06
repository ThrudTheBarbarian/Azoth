//
//  AZImage.h
//  Azoth
//
//  Created by Simon Gornall on 12/28/24.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>
#import <Azoth/AZPasteboard.h>

NS_ASSUME_NONNULL_BEGIN

@class AZPainter;
@class AZTexture;

/*****************************************************************************\
|* Typedefs and enums
\*****************************************************************************/

// These are the formats that AZImage can save (and load, though loading is
// far more capable). The LZ4 format is an RGBA8888 pixel format, documented at
// https://tinyurl.com/as8sba5y and is lossless, using LZ4 for compression. It
// is currently not implemented though :)

typedef enum
	{
	AZImageFormatJPEG	= 0,
	AZImageFormatPNG,
	AZImageFormatLZ4,

	AZImageFormatMax
	} AZImageFormat;

// This is the handler block for when creating a draw-on-demand-with-handler
// AZImage. The handler is given a rect within which to draw, the clip rectangle
// will already be set to the rect passed in, and focus will already locked
// for the painter. The routine will be called every time the image is
// rendered.
typedef BOOL (^AZImageDrawingHandler)(NSRect dstRect, AZPainter *painter) ;

@interface AZImage : NSObject <AZPasteboardWriting>

/*****************************************************************************\
|* Initialisation: Don't create images manually, call one of the convenience
|* class methods below
\*****************************************************************************/
- (instancetype) init NS_UNAVAILABLE;

/*****************************************************************************\
|* Initialisation: Load an image from the current bundle's Resources/ directory
\*****************************************************************************/
+ (AZImage *) imageNamed:(NSString *)name;


/*****************************************************************************\
|* Initialisation: Get an image from an atlas
\*****************************************************************************/
+ (AZImage *) imageWithName:(NSString *)name inAtlas:(NSString *)map;

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
|* Initialisation: Create an image that draws on demand
\*****************************************************************************/
+ (AZImage *) imageWithSize:(NSSize) size
			 drawingHandler:(AZImageDrawingHandler) drawingHandler
			clearBeforeDraw:(BOOL)clear;

/*****************************************************************************\
|* Initialisation: Create an image by referencing a texture
\*****************************************************************************/
+ (AZImage *) imageWithTexture:(NSInteger)textureId;

/*****************************************************************************\
|* Force a draw of an on-demand image;
\*****************************************************************************/
- (BOOL) draw;

/*****************************************************************************\
|* Lock focus on the image, which internally creates the AZPainter that will
|* have this image as its context. Optionally clear the image after locking
|* focus
\*****************************************************************************/
- (AZPainter *) lockFocus:(BOOL)clearTexture;

/*****************************************************************************\
|* Unlock focus. The renderer will return its focus to where it was focussed
|* before lockFocus was called. Note that this isn't a stack, it's just storing
|* the old value and restoring it. Typically not needed since the painter
|* will restore the previous focus when it is deallocated, but if you want
|* control over the lifetime of that focus-setting...
\*****************************************************************************/
- (void) unlockFocusWithPainter:(AZPainter *)painter;

/*****************************************************************************\
|* Save the image to a path. Quality is a factor ranging from 0..9, with 0
|* being the lowest quality (highest artifacts) and 9 being the best quality.
|* Note that time to save may be affected by quality (especially LZ4)
\*****************************************************************************/
- (BOOL) saveAs:(NSString *)path
	   inFormat:(AZImageFormat)format
	withQuality:(int)quality;


/*****************************************************************************\
|* Return an AZTexture object referencing this image's texture
\*****************************************************************************/
- (AZTexture *) asTexture;

/*****************************************************************************\
|* Return the image size and position within its parent texture
\*****************************************************************************/
- (NSRect) bounds;

/*****************************************************************************\
|* Properties
\*****************************************************************************/
// The texture-id that the Renderer owns
@property(assign, nonatomic) NSInteger							texture;

// Image dimensions
@property(assign, nonatomic) int								width;
@property(assign, nonatomic) int								height;

// For dynamic images, whether to clear before draw
@property(assign, nonatomic) BOOL								clearBeforeDraw;

// Whether this is a template image
@property(assign, nonatomic) BOOL								isTemplate;

// Just useful in general
@property(strong, nonatomic) NSString *							identifier;

// The location within the texture that defines
// this image. For large, standalone, images, this
// will be the full extent of the image but for
// images placed into a texture-atlas, the srcRect
// tells us the exact co-ords of the image. This may
// be necessary if you want to tile an image-texture
// using the renderer, for example
@property(assign, nonatomic) NSRect								srcRect;

// Whether this image exists in the texture cache
@property(assign, nonatomic) BOOL								isValid;
@end

NS_ASSUME_NONNULL_END
