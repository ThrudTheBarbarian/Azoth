//
//  AZRenderer.h
//  Azoth
//
//  Created by Simon Gornall on 12/17/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct SDL_Renderer;
struct SDL_Texture;
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
|* Return a texture for a given id
\*****************************************************************************/
- (nullable struct SDL_Texture *) textureFor:(NSInteger)refId;


/*****************************************************************************\
|* Release a texture, removing it from the cache
\*****************************************************************************/
- (void) releaseTexture:(NSInteger)refId;

/*****************************************************************************\
|* Un/Lock focus on a given texture
\*****************************************************************************/
- (BOOL) lockFocusOn:(NSInteger)refId;
- (void) unlockFocus;

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
|* Set the blend mode
\*****************************************************************************/
- (int) setBlendMode:(uint32_t)blendMode;
- (int) setTexture:(NSInteger)refId blendMode:(uint32_t)blendMode;

/*****************************************************************************\
|* Get/Set the clip, use NSZeroRect to unset
\*****************************************************************************/
- (NSRect) clipRect;
- (void) setClip:(NSRect)clipRect;

/*****************************************************************************\
|* Clear the current texture target
\*****************************************************************************/
- (void) clear;

/*****************************************************************************\
|* Set the drawing colour
\*****************************************************************************/
- (int) setDrawColour:(AZColour *)colour;
- (int) setDrawColourToRed:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;

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

@property(assign, nonatomic) struct SDL_Renderer *					renderer;
@end

NS_ASSUME_NONNULL_END
