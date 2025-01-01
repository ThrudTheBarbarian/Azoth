//
//  AZRenderer.h
//  Azoth
//
//  Created by Simon Gornall on 12/17/24.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class AZColour;

struct SDL_Surface;
struct SDL_Renderer;
struct SDL_FPoint;

@interface AZRenderer : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init NS_UNAVAILABLE;
+ (AZRenderer *) renderer;

/*****************************************************************************\
|* Create a new texture and return a reference-id. Returns <0 value on error
|* This will not call SDL_Destroy() on any surface provided! 
\*****************************************************************************/
- (NSInteger) createTextureWithSurface:(struct SDL_Surface *)surface;
- (NSInteger) createTextureOfSize:(NSSize)size;
- (NSInteger) createTextureOfSize:(NSSize)size
							format:(int)format
						 withFlags:(int)flags;

/*****************************************************************************\
|* Return a surface for a given id
\*****************************************************************************/
- (nullable struct SDL_Surface *) surfaceFor:(NSInteger)refId;

/*****************************************************************************\
|* Return a bounds-rect for a given id, or NSZeroRect if not found
\*****************************************************************************/
- (NSRect) boundsOfTexture:(NSInteger)refId;

/*****************************************************************************\
|* Release a texture, removing it from the cache
\*****************************************************************************/
- (void) releaseTexture:(NSInteger)refId;

/*****************************************************************************\
|* Un/Lock focus on a given texture
\*****************************************************************************/
- (BOOL) lockFocusOn:(NSInteger)refId;
- (void) unlockFocus;
- (NSInteger) currentFocus;
- (void) restoreFocus:(NSInteger)oldFocus;

/*****************************************************************************\
|* Perform a blit operation
\*****************************************************************************/
- (int) blitFrom:(NSInteger)texture src:(NSRect)srcRect dst:(NSRect)dstRect;

/*****************************************************************************\
|* Perform a tiled blit operation
\*****************************************************************************/
- (int) tileFrom:(NSInteger)textureId src:(NSRect)srcRect dst:(NSRect)dstRect;
- (int) tileFrom:(NSInteger)textureId src:(NSRect)srcRect scale:(float)scale
			  dst:(NSRect)dstRect;

/*****************************************************************************\
|* Perform a rotated blit operation
\*****************************************************************************/
- (int) blitFrom:(NSInteger)textureId	// Texture id from cache
			 src:(NSRect)srcRect		// If NSZeroRect, entire texture
			 dst:(NSRect)dstRect		// If NSZeroRect, entire target
		   angle:(NSInteger)degrees		// clockwise positive from x=0
		  center:(NSPoint)p				// Point around which to rotate
			flip:(AZFlipMode)flip;		// Flip-action on texture

/*****************************************************************************\
|* Set the blend mode
\*****************************************************************************/
- (int) setBlendMode:(uint32_t)blendMode;
- (int) setTexture:(NSInteger)refId blendMode:(uint32_t)blendMode;
- (int) texture:(NSInteger)refId blendMode:(uint32_t*)blendMode;

/*****************************************************************************\
|* Set the colour mod
\*****************************************************************************/
- (int) setTexture:(NSInteger)texId modR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b;

/*****************************************************************************\
|* Return some info about a given texture, by id
\*****************************************************************************/
- (float) widthOfTexture:(NSInteger)refId;
- (float) heightOfTexture:(NSInteger)refId;

/*****************************************************************************\
|* Get/Set/Unset the clip
\*****************************************************************************/
- (NSRect) clipRect;
- (void) setClip:(NSRect)clipRect;
- (void) unsetClip;
- (BOOL) clipEnabled;

/*****************************************************************************\
|* Viewport...
\*****************************************************************************/
- (NSRect) viewport;
- (void) setViewport:(NSRect)viewport;

/*****************************************************************************\
|* Scale...
\*****************************************************************************/
- (void) renderScaleX:(float *)xs y:(float *)ys;
- (void) setScaleX:(float)xs y:(float)ys;

/*****************************************************************************\
|* Presentation...
\*****************************************************************************/
- (NSSize) presentationSize;
- (int) presentationMode;
- (void) setPresentationSize:(NSSize)size mode:(NSInteger)mode;


/*****************************************************************************\
|* Clear the current texture target
\*****************************************************************************/
- (void) clear;

/*****************************************************************************\
|* Get/Set the drawing colour
\*****************************************************************************/
- (int) setDrawColour:(AZColour *)colour;
- (int) setDrawColourToRed:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;
- (void) drawColourR:(uint8_t*)r g:(uint8_t*)g b:(uint8_t*)b a:(uint8_t*)a;

/*****************************************************************************\
|* Present the rendering
\*****************************************************************************/
- (void) present;

/*****************************************************************************\
|* Render a point
\*****************************************************************************/
- (int) renderPointAtX:(int)x y:(int)y;
- (int) renderPointAt:(NSPoint)p;

/*****************************************************************************\
|* Render a line
\*****************************************************************************/
- (int) renderLineFromX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2;
- (int) renderLineFrom:(NSPoint)p1 to:(NSPoint)p2;

/*****************************************************************************\
|* Render lines
\*****************************************************************************/
- (int) render:(int)num lines:(struct SDL_FPoint *)pts;

/*****************************************************************************\
|* Render a rectangle
\*****************************************************************************/
- (int) renderRect:(NSRect)r;
- (int) renderFilledRect:(NSRect)r;

/*****************************************************************************\
|* Return the area safe for rendering in
\*****************************************************************************/
- (NSRect) safeAreaForRendering;

/*****************************************************************************\
|* Convert the render co-ords to window co-ords
\*****************************************************************************/
- (BOOL) convertRx:(float)rx ry:(float)ry to:(float*)wx wy:(float*)wy;

@property(assign, nonatomic) struct SDL_Renderer *					renderer;

// The name of the renderer
@property(strong, nonatomic) NSString *							rendererName;
@end

NS_ASSUME_NONNULL_END
