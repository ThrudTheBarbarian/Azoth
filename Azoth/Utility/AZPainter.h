//
//  AZPainter.h
//  Azoth
//
//  Created by Simon Gornall on 12/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZColour;
@class AZView;

@interface AZPainter : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithView:(AZView *)view;
+ (AZPainter *) painterForView:(AZView *)view;


// MARK: Execution of the draw routine

/*****************************************************************************\
|* Set up the context and draw
\*****************************************************************************/
- (BOOL) execute;


// MARK: drawing routines

/*****************************************************************************\
|* Pixel routines
\*****************************************************************************/

// Draw a single pixel in the current colour. No blending
- (int) pixelAtX:(int)x y:(int)y;

// Draw pixel with blending enabled if a<255
- (int) pixelAtX:(int)x y:(int)y colour:(AZColour *)colour;

// Draw pixel with blending enabled if a<255, using r,g,b,a
- (int) pixelAtX:(int)x y:(int)y
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

// Draw pixel with blending enabled if a<255, and weight 'alpha' by 0..255
- (int) pixelAtX:(int)x y:(int)y colour:(AZColour *)colour weight:(int)weight;

// Draw pixel with blending enabled if a<255, and weight 'alpha' by 0..255
- (int) pixelAtX:(int)x y:(int)y alphaWeight:(int)weight
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* line routines
\*****************************************************************************/

// Draw a line in the current colour. No blending
- (int) lineAtX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2;

// Draw a line with blending enabled if a<255
- (int) lineAtX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2 colour:(AZColour *)colr;

// Draw a line with blending enabled if a<255, using r,g,b,a
- (int) lineAtX:(int)x y:(int)y toX:(int)x2 y:(int)y2
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* Rectangle routines (not filled)
\*****************************************************************************/

- (int) rectangleWithRect:(NSRect)r colour:(AZColour *)colour;
- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h colour:(AZColour *)colour;
- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* Rounded rectangle routines (not filled)
\*****************************************************************************/

- (int) rectangleWithRect:(NSRect)r radius:(int)cornerRadius
		colour:(AZColour *)colour;
- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h
		radius:(int)cornerRadius colour:(AZColour *)colour;
- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h radius:(int)radius
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;


/*****************************************************************************\
|* Filled rectangle routines
\*****************************************************************************/

- (int) rectangleWithRect:(NSRect)r filled:(BOOL)yn colour:(AZColour *)colour;
- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h filled:(BOOL)yn
	    colour:(AZColour *)colour;
- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h filled:(BOOL)yn
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* Rounded filled rectangle routines
\*****************************************************************************/

- (int) rectangleWithRect:(NSRect)r radius:(int)cornerRadius
		filled:(BOOL)yn colour:(AZColour *)colour;
- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h
		radius:(int)radius filled:(BOOL)yn colour:(AZColour *)colour;
- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h radius:(int)radius
		filled:(BOOL)yn withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;


/*****************************************************************************\
|* arc-of-circle routines (not filled)
|* 0 degrees is the X axis, extents are measured clockwise
\*****************************************************************************/

// Draw arc-of-circle, with blending if a<255
- (int) arcAtX:(int)x y:(int)y radius:(int)radius start:(int)start end:(int)end
		colour:(AZColour *)colour;
- (int) arcAtX:(int)x y:(int)y radius:(int)radius start:(int)start end:(int)end
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

@end

NS_ASSUME_NONNULL_END
