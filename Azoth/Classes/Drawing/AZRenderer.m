//
//  AZRenderer.m
//  Azoth
//
//  Created by Simon Gornall on 12/17/24.
//

#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZObject.h"
#import "AZRenderer.h"
#import "AZWindow.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZRenderer()
@property(strong, nonatomic)
NSMutableDictionary<NSNumber *, AZObject *> * 				textures;

@property(assign, nonatomic) SDL_Renderer *					renderer;
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
- (void) blitFrom:(NSInteger)textureId src:(NSRect)srcRect dst:(NSRect)dstRect
	{
	SDL_Texture *texture = [self textureFor:textureId];
	if (texture)
		{
		SDL_FRect src = SDL_FRECT(srcRect);
		SDL_FRect dst = SDL_FRECT(dstRect);
		SDL_RenderTexture(_renderer, texture, &src, &dst);
		}
	else
		SDL_Log("Cannot find texture %d to blit from", (int)textureId);
	}

/*****************************************************************************\
|* Perform a tiled blit operation
\*****************************************************************************/
- (void) tileFrom:(NSInteger)textureId src:(NSRect)srcRect dst:(NSRect)dstRect
	{
	SDL_Texture *texture = [self textureFor:textureId];
	if (texture)
		{
		SDL_FRect src = SDL_FRECT(srcRect);
		SDL_FRect dst = SDL_FRECT(dstRect);
		SDL_RenderTextureTiled(_renderer, texture, &src, 1.0f, &dst);
		}
	else
		SDL_Log("Cannot find texture %d to tile from", (int)textureId);
	}

/*****************************************************************************\
|* Perform a tiled blit operation
\*****************************************************************************/
- (void) tileFrom:(NSInteger)textureId src:(NSRect)srcRect scale:(float)scale
			  dst:(NSRect)dstRect
	{
	SDL_Texture *texture = [self textureFor:textureId];
	if (texture)
		{
		SDL_FRect src = SDL_FRECT(srcRect);
		SDL_FRect dst = SDL_FRECT(dstRect);
		SDL_RenderTextureTiled(_renderer, texture, &src, scale, &dst);
		}
	else
		SDL_Log("Cannot find texture %d to tile from", (int)textureId);
	}

/*****************************************************************************\
|* Set the blend mode
\*****************************************************************************/
- (void) setBlendMode:(uint32_t)blendMode
	{
	SDL_SetRenderDrawBlendMode(_renderer, blendMode);
	}

/*****************************************************************************\
|* Set the clip, use NSZeroRect to unset
\*****************************************************************************/
- (void) setClip:(NSRect)clipRect
	{
	if ((clipRect.size.width == 0) || (clipRect.size.height == 0))
		SDL_SetRenderClipRect(_renderer, NULL);
	else
		{
		SDL_Rect clip = SDL_RECT(clipRect);
		SDL_SetRenderClipRect(_renderer, &clip);
		}
	}

@end
