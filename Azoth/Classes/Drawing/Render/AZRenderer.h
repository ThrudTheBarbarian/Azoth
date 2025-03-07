//
//  AZRenderer.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/13/25.
//

#import <Azoth/AZTypes.h>
#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>
#import <SDL3_ttf/SDL_ttf.h>

@class AZColour;
@class AZWindow;

NS_ASSUME_NONNULL_BEGIN

// ==========================================================================\\
// Defines the API for a renderer. We support both 3D (via the GPU API) and
// 2D renderers (via the render API). Both renderers implement this protocol
// ==========================================================================//

@protocol AZRenderer <NSObject>

/*****************************************************************************\
|* Create a window with a given size, title, flags that is compatible with
|* this type of renderer
\*****************************************************************************/
- (BOOL) createWindowWithTitle:(NSString *)title
						 frame:(NSRect)frame
						 style:(NSInteger)styleFlags;


/*****************************************************************************\
|* Return the window that we created for our renderer
\*****************************************************************************/
- (AZWindow *) window;

/*****************************************************************************\
|* Create a new texture and return a reference-id. Returns <0 value on error
|* This will not call SDL_Destroy() on any surface provided! 
\*****************************************************************************/
- (NSInteger) createTextureWithSurface:(struct SDL_Surface *)surface;
- (NSInteger) createTextureOfSize:(NSSize)size;
- (NSInteger) createTextureOfSize:(NSSize)size
							format:(SDL_PixelFormat)format
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
|* Bump a texture's retain count by 1. Note that the various create...
|* methods already retain the texture as needed
\*****************************************************************************/
- (void) retainTexture:(NSInteger)refId;

/*****************************************************************************\
|* Release a texture, removing it from the cache if its retain count = 0
\*****************************************************************************/
- (void) releaseTexture:(NSInteger)refId;

/*****************************************************************************\
|* Lock focus on a given texture
\*****************************************************************************/
- (BOOL) lockFocusOn:(NSInteger)refId;

/*****************************************************************************\
|* UnLock focus, target the screen
\*****************************************************************************/
- (void) unlockFocus;

/*****************************************************************************\
|* Return the current focus, or -1 if it's the screen
\*****************************************************************************/
- (NSInteger) currentFocus;

/*****************************************************************************\
|* Swap focus to a new one
\*****************************************************************************/
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
|* Perform a blit operation with an affine transform:
|*
|* srcRect: the source rectangle or NSZeroRect for the entire texture
|* origin : point where top-left should be mapped to, or NSZeroPoint for the
|*          destination texture's origin
|* right  : point where top-right should be mapped to, or NSZeroPoint for the
|*          destination texture's top-right
|* down   : point where bottom-left should be mapped to, or NSZeroPoint for the
|*          destination texture's bottom-left
\*****************************************************************************/
- (BOOL) blitFrom:(NSInteger)textureId
			  src:(NSRect)src
		   origin:(NSPoint)origin
			right:(NSPoint)right
			 down:(NSPoint)down;

/*****************************************************************************\
|* Perform a 9-way tiled blit operation
\*****************************************************************************/
- (int) blit9WayFrom:(NSInteger)textureId
				 src:(NSRect)srcRect
			   scale:(float)scale
				left:(float)left
			   right:(float)right
			     top:(float)top
			  bottom:(float)bottom
				 dst:(NSRect)dstRect;

/*****************************************************************************\
|* Set the blend mode
\*****************************************************************************/
- (BOOL) setBlendMode:(SDL_BlendMode)blendMode;

/*****************************************************************************\
|* Set the blend mode on a texture
\*****************************************************************************/
- (int) setTexture:(NSInteger)refId blendMode:(uint32_t)blendMode;

/*****************************************************************************\
|* Get the blend mode currently set on a texture
\*****************************************************************************/
- (int) texture:(NSInteger)refId blendMode:(uint32_t*)blendMode;

/*****************************************************************************\
|* Set the colour mod
\*****************************************************************************/
- (int) setTexture:(NSInteger)texId modR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b;

/*****************************************************************************\
|* Set the "mod" alpha on a texture
\*****************************************************************************/
- (int)setTexture:(NSInteger)texId modAlpha:(uint8_t)a;

/*****************************************************************************\
|* Return some info about a given texture, by id
\*****************************************************************************/
- (float) widthOfTexture:(NSInteger)refId;
- (float) heightOfTexture:(NSInteger)refId;

/*****************************************************************************\
|* Get/Set/Unset the clip
\*****************************************************************************/
- (NSRect) clipRect;
- (BOOL) setClip:(NSRect)clipRect;
- (void) unsetClip;
- (BOOL) clipEnabled;

/*****************************************************************************\
|* Viewport...
\*****************************************************************************/
- (NSRect) viewport;
- (BOOL) setViewport:(NSRect)viewport;

/*****************************************************************************\
|* Scale...
\*****************************************************************************/
- (void) renderScaleX:(float *)xs y:(float *)ys;
- (BOOL) setScaleX:(float)xs y:(float)ys;

/*****************************************************************************\
|* Presentation...
\*****************************************************************************/
- (NSSize) presentationSize;
- (int) presentationMode;
- (void)setPresentationSize:(NSSize)size
					   mode:(SDL_RendererLogicalPresentation)mode;


/*****************************************************************************\
|* Sync to VSync
\*****************************************************************************/
- (void) syncToVsync:(BOOL)yn;

/*****************************************************************************\
|* Clear the current texture target
\*****************************************************************************/
- (BOOL) clear;

/*****************************************************************************\
|* Get/Set the drawing colour
\*****************************************************************************/
- (void) setDrawColour:(AZColour *)colour;
- (int) setDrawColourToRed:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;
- (void) drawColourR:(uint8_t*)r g:(uint8_t*)g b:(uint8_t*)b a:(uint8_t*)a;

/*****************************************************************************\
|* Get/Set the clearing colour
\*****************************************************************************/
- (void) setClearColour:(AZColour *)colour;

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
|* Render points
\*****************************************************************************/
- (int)renderPoints:(NSPoint *)pts count:(int)count;

/*****************************************************************************\
|* Render a line
\*****************************************************************************/
- (int) renderLineFromX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2;
- (int) renderLineFrom:(NSPoint)p1 to:(NSPoint)p2;

/*****************************************************************************\
|* Render lines
\*****************************************************************************/
- (int)renderLines:(NSPoint *)pts count:(int)count;

/*****************************************************************************\
|* Render a rectangle
\*****************************************************************************/
- (int) renderRect:(NSRect)r;

/*****************************************************************************\
|* Render a filled rectangle
\*****************************************************************************/
- (BOOL) renderFilledRect:(NSRect)r;

/*****************************************************************************\
|* Return the area safe for rendering in
\*****************************************************************************/
- (NSRect) safeAreaForRendering;

/*****************************************************************************\
|* Convert the render co-ords to window co-ords
\*****************************************************************************/
- (BOOL) convertRx:(float)rx ry:(float)ry to:(float*)wx wy:(float*)wy;

/*****************************************************************************\
|* The name of the renderer
\*****************************************************************************/
- (NSString *) rendererName;

/*****************************************************************************\
|* The type of the renderer
\*****************************************************************************/
- (AZRendererType) rendererType;

/*****************************************************************************\
|* The text engine for this renderer
\*****************************************************************************/
- (TTF_TextEngine *) textEngine;

/*****************************************************************************\
|* Key/value pairs - like SDL's properties, but hey, we have dictionaries...
\*****************************************************************************/
- (NSDictionary *) properties;

/*****************************************************************************\
|* The renderer, only valid for the 2D case
\*****************************************************************************/
- (SDL_Renderer *) renderer;

/*****************************************************************************\
|* Name a texture
\*****************************************************************************/
- (void) setName:(NSString *)name forTexture:(NSInteger)refId;

// MARK: 3d renderer only
/*****************************************************************************\
|* Return the GPU device we created.
\*****************************************************************************/
- (nullable struct SDL_GPUDevice *) gpu;


@end



@interface AZRenderer : NSObject

/*****************************************************************************\
|* Return the default renderer
\*****************************************************************************/
+ (id<AZRenderer>) renderer;

/*****************************************************************************\
|* Return a renderer of the requested type
\*****************************************************************************/
+ (BOOL) makeDefaultRendererOfType:(AZRendererType)type;

@end

NS_ASSUME_NONNULL_END
