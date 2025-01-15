//
//  AZPainter.h
//  Azoth
//
//  Created by Simon Gornall on 12/12/24.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class AZColour;
@class AZFont;
@class AZImage;
@class AZTextPainter;
@class AZView;

struct SDL_Surface;

@interface AZPainter : NSObject

/*****************************************************************************\
|* Initialisation: view-based
\*****************************************************************************/
- (instancetype) initWithView:(AZView *)view;
+ (AZPainter *) painterForView:(AZView *)view;

/*****************************************************************************\
|* Initialisation: texture-based
\*****************************************************************************/
- (instancetype) initWithTexture:(NSInteger)texture;
+ (AZPainter *) painterForTexture:(NSInteger)texture;

// MARK: Execution of the draw routine

/*****************************************************************************\
|* (Un)Lock focus. Internally (re)stores the previous focus and clip-rect. If
|* the bool is set to YES, the renderer will clear the texture/view once focus
|* is locked.
\*****************************************************************************/
- (void) lockFocus:(BOOL)clearTexture;
- (void) unlockFocus;

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
|* triangle routines (not filled)
\*****************************************************************************/

- (int) triangleWithX:(int)x1 y:(int)y1 x:(int)x2 y:(int)y2 x:(int)x3 y:(int)y3
		colour:(AZColour *)colour;
- (int) triangleWithX:(int)x1 y:(int)y1 x:(int)x2 y:(int)y2 x:(int)x3 y:(int)y3
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* triangle routines (filled)
\*****************************************************************************/

- (int) triangleWithX:(int)x1 y:(int)y1 x:(int)x2 y:(int)y2 x:(int)x3 y:(int)y3
		filled:(BOOL)yn colour:(AZColour *)colour;
- (int) triangleWithX:(int)x1 y:(int)y1 x:(int)x2 y:(int)y2 x:(int)x3 y:(int)y3
		filled:(BOOL)yn withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* Rectangle routines (not filled)
\*****************************************************************************/

- (int) rectangleWithRect:(NSRect)r colour:(AZColour *)colour;
- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h colour:(AZColour *)colour;
- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* Rectangle routines (edge effects)
\*****************************************************************************/
- (void) rectangleWithBezel:(NSRect)r withClip:(NSRect)clip;
- (void) rectangleWithGroove:(NSRect)r withClip:(NSRect)clip;
- (void) rectangleWithButton:(NSRect)r withClip:(NSRect)clip;
- (void) rectangleInRect:(NSRect)r
					 num:(int)num
				  dashes:(int *)onOff
				inColour:(AZColour *)colour
				withClip:(NSRect)clip;

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

- (int) arcAtX:(int)x y:(int)y radius:(int)radius start:(int)start end:(int)end
		colour:(AZColour *)colour;
- (int) arcAtX:(int)x y:(int)y radius:(int)radius start:(int)start end:(int)end
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* pie-of-circle routines
|* 0 degrees is the X axis, extents are measured clockwise
\*****************************************************************************/

- (int) pieAtX:(int)x y:(int)y radius:(int)radius start:(int)start end:(int)end
		filled:(BOOL)yn colour:(AZColour *)colour;
- (int) pieAtX:(int)x y:(int)y radius:(int)radius start:(int)start end:(int)end
		filled:(BOOL)yn withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* circle routines (not filled)
\*****************************************************************************/

- (int) circleAtX:(int)x y:(int)y r:(int)rx colour:(AZColour *)colour;
- (int) circleAtX:(int)x y:(int)y r:(int)rx
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* circle routines
\*****************************************************************************/

- (int) circleAtX:(int)x y:(int)y r:(int)rx filled:(BOOL)yn
		colour:(AZColour *)colour;
- (int) circleAtX:(int)x y:(int)y r:(int)rx filled:(BOOL)yn
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* ellipse routines (not filled)
\*****************************************************************************/

- (int) ellipseWithRect:(NSRect)r colour:(AZColour *)colour;
- (int) ellipseAtX:(int)x y:(int)y rx:(int)rx ry:(int)ry
		colour:(AZColour *)colour;
- (int) ellipseAtX:(int)x y:(int)y rx:(int)rx ry:(int)ry
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* ellipse routines
\*****************************************************************************/

- (int) ellipseWithRect:(NSRect)r filled:(BOOL)yn colour:(AZColour *)colour;
- (int) ellipseAtX:(int)x y:(int)y rx:(int)rx ry:(int)ry
		filled:(BOOL)yn colour:(AZColour *)colour;
- (int) ellipseAtX:(int)x y:(int)y rx:(int)rx ry:(int)ry filled:(BOOL)yn
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* polygon routines (not filled)
\*****************************************************************************/
// Without alpha-blending
- (int) polygonWith:(int)num points:(NSPoint*)pts;
- (int) polygonWith:(int)num x:(int *)xc y:(int *)yc;

// Alpha blending
- (int) polygonWith:(int)num x:(int *)xc y:(int *)y
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;


/*****************************************************************************\
|* polygon routines (filled)
\*****************************************************************************/

// Coloured fill
- (int) polygonWith:(int)num x:(int *)xc y:(int *)y filled:(BOOL)yn
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

// Textured fill
- (int) texturedPolygonWith:(int)num x:(int *)vx y:(int *)vy
		texture:(struct SDL_Surface *)surface
		textureDx:(int)tdx textureDy:(int)tdy;


/*****************************************************************************\
|* bezier lines
\*****************************************************************************/
- (int) bezierWithPoints:(int)num x:(int *)xc y:(int *)y steps:(int)steps
		colour:(AZColour *)colour;

- (int) bezierWithPoints:(int)num x:(int *)xc y:(int *)y steps:(int)steps
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;


/*****************************************************************************\
|* Draw text
\*****************************************************************************/
- (NSRect) textAtX:(float)x y:(float)y text:(NSString *)text;
- (NSRect) textAtX:(float)x y:(float)y format:(NSString *)fmt, ...;

- (NSRect) textInBox:(NSRect)box text:(NSString *)text;
- (NSRect) textInBox:(NSRect)box format:(NSString *)fmt, ...;

- (NSRect) textColumnsInBox:(NSRect)box text:(NSString *)text;
- (NSRect) textColumnsInBox:(NSRect)box format:(NSString *)fmt, ...;

/*****************************************************************************\
|* Set text colour, separate from drawing colour
\*****************************************************************************/
- (void) setTextColour:(AZColour *)colour;
- (void) setTextColourWithR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

/*****************************************************************************\
|* Set horizontal text alignment
\*****************************************************************************/
- (void) setTextAlignment:(AZTextAlignment)align;

/*****************************************************************************\
|* Set text angle (cardinal angles only for now, 0, 90, 180, 270)
\*****************************************************************************/
- (void) setTextAngle:(int)degrees;

/*****************************************************************************\
|* Set text scale (for effects, use different sized fonts for "normal" use)
\*****************************************************************************/
- (void) setTextScale:(AZScale)scale;

/*****************************************************************************\
|* Set the font to use
\*****************************************************************************/
- (void) setFont:(AZFont *)font;




/*****************************************************************************\
|* Draw an image at a point
\*****************************************************************************/
- (void) image:(AZImage *)img at:(NSPoint)xy;

/*****************************************************************************\
|* Draw an image into a rectangle
\*****************************************************************************/
- (void) image:(AZImage *)img to:(NSRect)dstRect;

/*****************************************************************************\
|* Draw part of an image to a point
\*****************************************************************************/
- (void) image:(AZImage *)img from:(NSRect)srcRect at:(NSPoint)xy;

/*****************************************************************************\
|* Draw part of an image into a rectangle
\*****************************************************************************/
- (void) image:(AZImage *)img from:(NSRect)srcRect to:(NSRect)dstRect;


/*****************************************************************************\
|* Draw an image at a point with a rotation about a point, possibly flipped
|* The point is specifed relative to the center of the image srcRect.
\*****************************************************************************/
- (void) image:(AZImage *)img
			at:(NSPoint)xy
		 angle:(int)degrees
		 about:(NSPoint)center
		  flip:(AZFlipMode)flipMask;

/*****************************************************************************\
|* Draw a subset of an image with a rotation about a point, possibly flipped
|* The point is specifed relative to the center of the image srcRect.
\*****************************************************************************/
- (void) image:(AZImage *)img
		  from:(NSRect)srcRect
			at:(NSPoint)xy
		 angle:(int)degrees
		 about:(NSPoint)center
		  flip:(AZFlipMode)flipMask;




/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Set to draw with the (slower, but nicer looking) anti-aliased line drawing
// routines
@property(assign, nonatomic) BOOL 							usingAntiAliasing;

// Set YES if this is the last line being drawn during anti-aliased draw. If
// (x2,y2) is a mid-point of a set of lines in a line-series, then set to NO
@property(assign, nonatomic) BOOL 							drawAAEndpoint;

// Delegate all the text rendering to a separate object since it's quite the
// task in and of itself
@property(strong, nonatomic) AZTextPainter *				textPainter;
@end

NS_ASSUME_NONNULL_END
