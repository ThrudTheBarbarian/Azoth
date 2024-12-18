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
|* Un/Lock focus on a given texture
\*****************************************************************************/
- (BOOL) lockFocusOn:(NSInteger)refId;
- (void) unlockFocus;

/*****************************************************************************\
|* Perform a blit operation
\*****************************************************************************/
- (void) blitFrom:(NSInteger)texture src:(NSRect)srcRect dst:(NSRect)dstRect;

/*****************************************************************************\
|* Perform a tiled blit operation
\*****************************************************************************/
- (void) tileFrom:(NSInteger)textureId src:(NSRect)srcRect dst:(NSRect)dstRect;
- (void) tileFrom:(NSInteger)textureId src:(NSRect)srcRect scale:(float)scale
			  dst:(NSRect)dstRect;

/*****************************************************************************\
|* Set the blend mode
\*****************************************************************************/
- (void) setBlendMode:(uint32_t)blendMode;

/*****************************************************************************\
|* Set the clip, use NSZeroRect to unset
\*****************************************************************************/
- (void) setClip:(NSRect)clipRect;

@end

NS_ASSUME_NONNULL_END
