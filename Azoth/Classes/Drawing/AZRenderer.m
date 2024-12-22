//
//  AZRenderer.m
//  Azoth
//
//  Created by Simon Gornall on 12/17/24.
//

#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZColour.h"
#import "AZObject.h"
#import "AZRenderer.h"
#import "AZWindow.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZRenderer()
@property(strong, nonatomic)
NSMutableDictionary<NSNumber *, AZObject *> * 				textures;

@end

@implementation AZRenderer

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_renderer 	= AZApp.sharedInstance.window.renderer;

		/*********************************************************************\
		|* Prepare to store the textures
		\*********************************************************************/
		_textures 	= [NSMutableDictionary new];
		}
	return self;
	}


/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZRenderer *) renderer;
	{
	static AZRenderer *tmgr = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		tmgr = [AZRenderer new];
		});
	return tmgr;
	}


/*****************************************************************************\
|* Create an SDL_Texture from a surface
\*****************************************************************************/
- (NSInteger) createTextureWithSurface:(SDL_Surface *)surface
	{
	SDL_Texture *texture = SDL_CreateTextureFromSurface(_renderer, surface);
	if (texture)
		{
		NSNumber *ref 	= [NSNumber numberWithInteger:_textures.count];
		_textures[ref] 	= [AZObject objectWithPointer:texture
											  andHint:kTextureType];
		return ref.integerValue;
		}
	return -1;
	}

/*****************************************************************************\
|* Create an SDL_Texture from parameters
\*****************************************************************************/
- (NSInteger) createTextureOfSize:(NSSize)size
							format:(int)format
						 withFlags:(int)flags
	{
	SDL_Texture *texture = SDL_CreateTexture(_renderer,
											 format,
											 flags,
											 (int)size.width,
											 (int)size.height);

	if (texture)
		{
		NSNumber *ref 	= [NSNumber numberWithInteger:_textures.count];
		_textures[ref] 	= [AZObject objectWithPointer:texture
											  andHint:kTextureType];
		return ref.integerValue;
		}
	return -1;
	}

/*****************************************************************************\
|* Create an SDL_Texture from less parameters
\*****************************************************************************/
- (NSInteger) createTextureOfSize:(NSSize)size
	{
	SDL_Texture *texture = SDL_CreateTexture(_renderer,
											 SDL_PIXELFORMAT_RGBA8888,
											 SDL_TEXTUREACCESS_TARGET,
											 (int)size.width,
											 (int)size.height);

	if (texture)
		{
		NSNumber *ref 	= [NSNumber numberWithInteger:_textures.count];
		_textures[ref] 	= [AZObject objectWithPointer:texture
											  andHint:kTextureType];
		return ref.integerValue;
		}
	return -1;
	}

/*****************************************************************************\
|* Release a texture, removing it from the cache
\*****************************************************************************/
- (void) releaseTexture:(NSInteger)refId
	{
	AZObject *object = _textures[@(refId)];
	if (object && [object.hint isEqualToString:kTextureType])
		{
		SDL_DestroyTexture((SDL_Texture *)object.ptr);
		[_textures removeObjectForKey:@(refId)];
		}
	}

/*****************************************************************************\
|* Return a texture for a given id
\*****************************************************************************/
- (nullable SDL_Texture *) textureFor:(NSInteger)refId
	{
	AZObject *object = _textures[@(refId)];
	if (object && [object.hint isEqualToString:kTextureType])
		return object.ptr;

	return NULL;
	}

/*****************************************************************************\
|* Un/Lock focus on a given texture
\*****************************************************************************/
- (BOOL) lockFocusOn:(NSInteger)refId
	{
	BOOL ok = NO;
	SDL_Texture *texture = [self textureFor:refId];
	if (texture)
		{
		SDL_SetRenderTarget(_renderer, texture);
		ok = YES;
		}
	return ok;
	}

- (void) unlockFocus
	{
	SDL_SetRenderTarget(_renderer, NULL);
	}

/*****************************************************************************\
|* Perform a blit operation
\*****************************************************************************/
- (int) blitFrom:(NSInteger)textureId src:(NSRect)srcRect dst:(NSRect)dstRect
	{
	SDL_Texture *texture = [self textureFor:textureId];
	if (texture)
		{
		SDL_FRect src = SDL_FRECT(srcRect);
		SDL_FRect dst = SDL_FRECT(dstRect);
		return SDL_RenderTexture(_renderer, texture, &src, &dst);
		}

	SDL_Log("Cannot find texture %d to blit from", (int)textureId);
	return -1;
	}

/*****************************************************************************\
|* Perform a tiled blit operation
\*****************************************************************************/
- (int) tileFrom:(NSInteger)textureId src:(NSRect)srcRect dst:(NSRect)dstRect
	{
	SDL_Texture *texture = [self textureFor:textureId];
	if (texture)
		{
		SDL_FRect src = SDL_FRECT(srcRect);
		SDL_FRect dst = SDL_FRECT(dstRect);
		return SDL_RenderTextureTiled(_renderer, texture, &src, 1.0f, &dst);
		}

	SDL_Log("Cannot find texture %d to tile from", (int)textureId);
	return -1;
	}

/*****************************************************************************\
|* Perform a tiled blit operation
\*****************************************************************************/
- (int) tileFrom:(NSInteger)textureId src:(NSRect)srcRect scale:(float)scale
			 dst:(NSRect)dstRect
	{
	SDL_Texture *texture = [self textureFor:textureId];
	if (texture)
		{
		SDL_FRect src = SDL_FRECT(srcRect);
		SDL_FRect dst = SDL_FRECT(dstRect);
		return SDL_RenderTextureTiled(_renderer, texture, &src, scale, &dst);
		}

	SDL_Log("Cannot find texture %d to tile from", (int)textureId);
	return -1;
	}

/*****************************************************************************\
|* Set the blend mode
\*****************************************************************************/
- (int ) setBlendMode:(uint32_t)blendMode
	{
	return SDL_SetRenderDrawBlendMode(_renderer, blendMode);
	}

- (int) setTexture:(NSInteger)refId blendMode:(uint32_t)blendMode
	{
	SDL_Texture *texture = [self textureFor:refId];
	if (texture)
		return SDL_SetTextureBlendMode(texture, blendMode);
	SDL_Log("Cannot find texture %d to set blend mode on", (int)refId);
	return -1;
	}

- (int) texture:(NSInteger)refId blendMode:(uint32_t*)blendMode
	{
	SDL_Texture *texture = [self textureFor:refId];
	if (texture)
		return SDL_GetTextureBlendMode(texture, blendMode);
	SDL_Log("Cannot find texture %d to get blend mode on", (int)refId);
	return -1;
	}

/*****************************************************************************\
|* Set the clip, use NSZeroRect to unset
\*****************************************************************************/
- (void) setClip:(NSRect)clipRect
	{
	SDL_Rect clip = SDL_RECT(clipRect);
	SDL_SetRenderClipRect(_renderer, &clip);
	}

- (void) unsetClip
	{
	SDL_SetRenderClipRect(_renderer, NULL);
	}

/*****************************************************************************\
|* Get the clip rect
\*****************************************************************************/
- (NSRect) clipRect
	{
	SDL_Rect existing;
	SDL_GetRenderClipRect(_renderer, &existing);
	return NS_RECT(existing);
	}

/*****************************************************************************\
|* Set the drawing colour
\*****************************************************************************/
- (int) setDrawColour:(AZColour *)colour
	{
	return SDL_SetRenderDrawColor(_renderer, colour.red,
											 colour.green,
											 colour.blue,
											 colour.alpha);
	}

/*****************************************************************************\
|* Set the drawing colour
\*****************************************************************************/
- (int) setDrawColourToRed:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	return SDL_SetRenderDrawColor(_renderer, r, g, b, a);
	}

/*****************************************************************************\
|* Clear the current texture target
\*****************************************************************************/
- (void) clear
	{
	SDL_RenderClear(_renderer);
	}

/*****************************************************************************\
|* Present the rendering
\*****************************************************************************/
- (void) present
	{
	SDL_RenderPresent(_renderer);
	}

/*****************************************************************************\
|* Render a point
\*****************************************************************************/
- (int) renderPointAtX:(int)x y:(int)y
	{
	return SDL_RenderPoint(_renderer, x, y);
	}

/*****************************************************************************\
|* Render a point
\*****************************************************************************/
- (int) renderPointAt:(NSPoint)p
	{
	return SDL_RenderPoint(_renderer, p.x, p.y);
	}

/*****************************************************************************\
|* Render a line
\*****************************************************************************/
- (int) renderLineFromX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2
	{
	return SDL_RenderLine(_renderer, x1, y1, x2, y2);
	}

- (int) renderLineFrom:(NSPoint)p1 to:(NSPoint)p2
	{
	return SDL_RenderLine(_renderer, p1.x, p1.y, p2.x, p2.y);
	}

/*****************************************************************************\
|* Render lines
\*****************************************************************************/
- (int) render:(int)num lines:(SDL_FPoint *)pts
	{
	return SDL_RenderLines(_renderer, pts, num);
	}

/*****************************************************************************\
|* Render a rectangle
\*****************************************************************************/
- (int) renderRect:(NSRect)r
	{
	SDL_FRect rect = SDL_FRECT(r);
	return SDL_RenderRect(_renderer, &rect);
	}

/*****************************************************************************\
|* Render a filled rectangle
\*****************************************************************************/
- (int) renderFilledRect:(NSRect)r
	{
	SDL_FRect rect = SDL_FRECT(r);
	return SDL_RenderFillRect(_renderer, &rect);
	}

/*****************************************************************************\
|* Return the area safe for rendering in
\*****************************************************************************/
- (NSRect) safeAreaForRendering
	{
	SDL_Rect safeArea;
	SDL_GetRenderSafeArea(_renderer, &safeArea);
	return NS_RECT(safeArea);
	}

/*****************************************************************************\
|* Convert the render co-ords to window co-ords
\*****************************************************************************/
- (BOOL) convertRx:(float)rx ry:(float)ry to:(float*)wx wy:(float*)wy
	{
	return SDL_RenderCoordinatesToWindow(_renderer, rx, ry, wx, wy);
	}


@end
