//
//  AZRenderer.m
//  Azoth
//
//  Created by Simon Gornall on 12/17/24.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZColour.h"
#import "AZObject.h"
#import "AZRenderer2d.h"
#import "AZWindow.h"

static NSInteger 		_textureId;
static SDL_SpinLock 	_textureLock;

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZRenderer2d()
@property(strong, nonatomic)
// The texture map for handing out textures
NSMutableDictionary<NSNumber *, AZObject *> * 						textures;

// The SDL window we associate this renderer with
@property(assign, nonatomic) SDL_Window *							sdlWindow;

// The AZWindow we associate this renderer with
@property(strong, nonatomic) AZWindow *								window;

// The 2D renderer that we represent
@property(assign, nonatomic) SDL_Renderer *							renderer;

// The clear colour
@property(strong, nonatomic) AZColour *								clearColour;

@end

@implementation AZRenderer2d

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_renderer 	= AZApp.window.renderer.renderer;

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
+ (AZRenderer2d *) renderer;
	{
	static AZRenderer2d *azr = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		azr 			= [AZRenderer2d new];
		_textureId 		= 1;
		_textureLock 	= 0;
		});
	return azr;
	}

/*****************************************************************************\
|* The type of the renderer
\*****************************************************************************/
- (AZRendererType) rendererType
	{
	return AZRendererType2d;
	}


/*****************************************************************************\
|* Get a texture-id
\*****************************************************************************/
- (NSNumber *) nextTextureId;
	{
	SDL_LockSpinlock(&_textureLock);
	_textureId ++;
	NSNumber * retVal = [NSNumber numberWithInteger:_textureId];
	SDL_UnlockSpinlock(&_textureLock);
	return retVal;
	}

/*****************************************************************************\
|* Create an SDL_Texture from a surface. Note that we duplicate and copy the
|* data so that the SDL_TEXTUREACCESS_TARGET flag can be set
\*****************************************************************************/
- (NSInteger) createTextureWithSurface:(SDL_Surface *)surface
	{
	SDL_Texture *texture = SDL_CreateTextureFromSurface(_renderer, surface);
	if (texture)
		{
		NSSize size 		  = NSMakeSize(surface->w, surface->h);
		NSInteger realTexture = [self createTextureOfSize:size];

		NSInteger currentFocus = [self currentFocus];
		[self lockFocusOn:realTexture];
		SDL_RenderTexture(_renderer, texture, NULL, NULL);
		[self restoreFocus:currentFocus];

		SDL_DestroyTexture(texture);
		return realTexture;
		}
	return -1;
	}

/*****************************************************************************\
|* Create an SDL_Texture from parameters
\*****************************************************************************/
- (NSInteger) createTextureOfSize:(NSSize)size
							format:(SDL_PixelFormat)format
						 withFlags:(int)flags
	{
	SDL_Texture *texture = SDL_CreateTexture(_renderer,
											 format,
											 flags,
											 (int)size.width,
											 (int)size.height);

	if (texture)
		{
		NSNumber *ref 	= [self nextTextureId];
		_textures[ref] 	= [AZObject objectWithPointer:texture
											  andHint:kTextureType];
		return ref.integerValue;
		}

	SDL_Log("Cannot create surface of size %dx%d",
			(int)size.width, (int)size.height);
	return -1;
	}

/*****************************************************************************\
|* Create an SDL_Texture from less parameters
\*****************************************************************************/
- (NSInteger) createTextureOfSize:(NSSize)size
	{
	SDL_Texture *texture = SDL_CreateTexture(_renderer,
											 SDL_PIXELFORMAT_BGRA8888,
											 SDL_TEXTUREACCESS_TARGET,
											 (int)size.width,
											 (int)size.height);

	if (texture)
		{
		NSNumber *ref 	= [self nextTextureId];
		_textures[ref] 	= [AZObject objectWithPointer:texture
											  andHint:kTextureType];
		return ref.integerValue;
		}

	SDL_Log("Cannot create surface of size %dx%d",
			(int)size.width, (int)size.height);
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
		object.use --;
		if (object.use == 0)
			{
			SDL_DestroyTexture((SDL_Texture *)object.ptr);
			[_textures removeObjectForKey:@(refId)];
			}
		}
	}

/*****************************************************************************\
|* Retain a texture, bumping its use-count by +1
\*****************************************************************************/
- (void) retainTexture:(NSInteger)refId
	{
	AZObject *object = _textures[@(refId)];
	if (object)
		object.use ++;
	}

/*****************************************************************************\
|* Return a surface for a given id
\*****************************************************************************/
- (nullable struct SDL_Surface *) surfaceFor:(NSInteger)refId
	{
	SDL_Texture *texture = [self _textureFor:refId];
	if (texture)
		{
		NSInteger oldFocus = [self currentFocus];
		SDL_SetRenderViewport(_renderer, NULL);
		if ([self lockFocusOn:refId])
			{
			SDL_Surface *surface = SDL_RenderReadPixels(_renderer, NULL);
			[self restoreFocus:oldFocus];
			return surface;
			}
		else
			SDL_Log("Couldn't lock onto texture %d", (int)refId);
		}
	else
		SDL_Log("Couldn't find a texture for id %d", (int)refId);
	return NULL;
	}

/*****************************************************************************\
|* Return a texture for a given id
\*****************************************************************************/
- (nullable SDL_Texture *) _textureFor:(NSInteger)refId
	{
	AZObject *object = _textures[@(refId)];
	if (object && [object.hint isEqualToString:kTextureType])
		return object.ptr;

	return NULL;
	}

/*****************************************************************************\
|* Return a bounds-rect for a given id, or NSZeroRect if not found
\*****************************************************************************/
- (NSRect) boundsOfTexture:(NSInteger)refId
	{
	NSRect bounds = NSZeroRect;
	AZObject *object = _textures[@(refId)];
	if (object && [object.hint isEqualToString:kTextureType])
		{
		SDL_Texture *texture = (SDL_Texture *)object.ptr;
		bounds.size.width = texture->w;
		bounds.size.height = texture->h;
		}
	return bounds;
	}


/*****************************************************************************\
|* Return a texture-id for a given texture. Should probably replace with a
|* reverse lookup map...
\*****************************************************************************/
- (NSInteger) textureIdFor:(SDL_Texture *)texture
	{
	for (NSNumber *textureId in _textures)
		{
		AZObject *obj = _textures[textureId];
		if (obj.ptr == texture)
			return textureId.integerValue;
		}

	SDL_Log("Cannot find texture %p in cache", texture);
	return -1;
	}

/*****************************************************************************\
|* Un/Lock focus on a given texture
\*****************************************************************************/
- (BOOL) lockFocusOn:(NSInteger)refId
	{
	BOOL ok = NO;
	SDL_Texture *texture = [self _textureFor:refId];
	if (texture)
		{
		if (SDL_SetRenderTarget(_renderer, texture))
			ok = YES;
		else
			SDL_Log("Failed to set render target: %s", SDL_GetError());
		}
	return ok;
	}

- (void) unlockFocus
	{
	SDL_SetRenderTarget(_renderer, NULL);
	}

- (NSInteger) currentFocus
	{
	SDL_Texture* current = SDL_GetRenderTarget(_renderer);
	return current ? [self textureIdFor:current] : -1;
	}

- (void) restoreFocus:(NSInteger)oldFocus
	{
	if (oldFocus < 0)
		[self unlockFocus];
	else
		[self lockFocusOn:oldFocus];
	}

/*****************************************************************************\
|* Perform a blit operation
\*****************************************************************************/
- (int) blitFrom:(NSInteger)textureId src:(NSRect)srcRect dst:(NSRect)dstRect
	{
	SDL_Texture *texture = [self _textureFor:textureId];
	if (texture)
		{
		SDL_FRect src = SDL_FRECT(srcRect);
		SDL_FRect dst = SDL_FRECT(dstRect);
		return SDL_RenderTexture(_renderer,
								 texture,
								 IS_ZERORECT(srcRect) ? NULL : &src,
								 IS_ZERORECT(dstRect) ? NULL : &dst);
		}

	if (textureId > 0)
		SDL_Log("Cannot find texture %d to blit from", (int)textureId);
	return -1;
	}

/*****************************************************************************\
|* Perform a (possibly) rotated text-blit operation
\*****************************************************************************/
- (int) blitFrom:(NSInteger)textureId	// Texture id from font
			 src:(NSRect)srcRect		// If NSZeroRect, entire texture
			 dst:(NSRect)dstRect		// If NSZeroRect, entire target
		   angle:(NSInteger)degrees		// clockwise positive from x=0
		  center:(NSPoint)p				// Point around which to rotate
			flip:(AZFlipMode)flip		// Flip-action on texture
	{
	SDL_Texture *texture = [self _textureFor:textureId];
	if (texture)
		{
		SDL_FRect src 		= SDL_FRECT(srcRect);
		SDL_FRect dst 		= SDL_FRECT(dstRect);
		SDL_FPoint about  	= (SDL_FPoint){p.x, p.y};
		return SDL_RenderTextureRotated(_renderer,
										texture,
										IS_ZERORECT(srcRect) ? NULL : &src,
										IS_ZERORECT(dstRect) ? NULL : &dst,
										degrees,
										&about,
										(SDL_FlipMode)flip);
		}
	SDL_Log("Cannot find texture %d to [complex] blit from", (int)textureId);
	return -1;
	}

/*****************************************************************************\
|* Perform a tiled blit operation
\*****************************************************************************/
- (int) tileFrom:(NSInteger)textureId src:(NSRect)srcRect dst:(NSRect)dstRect
	{
	SDL_Texture *texture = [self _textureFor:textureId];
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
	SDL_Texture *texture = [self _textureFor:textureId];
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
			  src:(NSRect)srcRect
		   origin:(NSPoint)origin
			right:(NSPoint)right
			 down:(NSPoint)down
	{
	SDL_Texture *texture = [self _textureFor:textureId];
	if (texture)
		{
		SDL_FRect src 		= SDL_FRECT(srcRect);
		SDL_FPoint Origin 	= SDL_FPOINT(origin);
		SDL_FPoint Right  	= SDL_FPOINT(right);
		SDL_FPoint Down		= SDL_FPOINT(down);

		return SDL_RenderTextureAffine(_renderer,
									   texture,
									   IS_ZERORECT(srcRect) ? NULL : &src,
									   IS_ZEROPOINT(origin) ? NULL : &Origin,
									   IS_ZEROPOINT(right)  ? NULL : &Right,
									   IS_ZEROPOINT(down)   ? NULL : &Down);
		}
	return NO;
	}

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
				 dst:(NSRect)dstRect
	{
	SDL_Texture *texture = [self _textureFor:textureId];
	if (texture)
		{
		BOOL srcNull = NSIsEmptyRect(srcRect);
		BOOL dstNull = NSIsEmptyRect(dstRect);

		SDL_FRect src = SDL_FRECT(srcRect);
		SDL_FRect dst = SDL_FRECT(dstRect);

		return SDL_RenderTexture9Grid(_renderer, texture,
									  srcNull ? NULL : &src,
									  left, right, top, bottom,
									  scale,
									  dstNull ? NULL : &dst);
		}

	SDL_Log("Cannot find texture %d to tile from", (int)textureId);
	return -1;
	}

/*****************************************************************************\
|* Set the blend mode
\*****************************************************************************/
- (BOOL) setBlendMode:(uint32_t)blendMode
	{
	return SDL_SetRenderDrawBlendMode(_renderer, blendMode);
	}

- (int) setTexture:(NSInteger)refId blendMode:(uint32_t)blendMode
	{
	SDL_Texture *texture = [self _textureFor:refId];
	if (texture)
		return SDL_SetTextureBlendMode(texture, blendMode);
	SDL_Log("Cannot find texture %d to set blend mode on", (int)refId);
	return -1;
	}

- (int) texture:(NSInteger)refId blendMode:(uint32_t*)blendMode
	{
	SDL_Texture *texture = [self _textureFor:refId];
	if (texture)
		return SDL_GetTextureBlendMode(texture, blendMode);
	SDL_Log("Cannot find texture %d to get blend mode on", (int)refId);
	return -1;
	}

/*****************************************************************************\
|* Set the colour mod
\*****************************************************************************/
- (int) setTexture:(NSInteger)texId modR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b
	{
	SDL_Texture *texture = [self _textureFor:texId];
	if (texture)
		return SDL_SetTextureColorMod(texture, r, g, b);
	SDL_Log("Cannot find texture %d to set colour-mod on", (int)texId);
	return -1;
	}


- (int)setTexture:(NSInteger)texId modAlpha:(uint8_t)a
	{
	SDL_Texture *texture = [self _textureFor:texId];
	if (texture)
		return SDL_SetTextureAlphaMod(texture, a);
	SDL_Log("Cannot find texture %d to set alpha-mod on", (int)texId);
	return -1;
	}



/*****************************************************************************\
|* Return some info about a given texture, by id
\*****************************************************************************/
- (float) widthOfTexture:(NSInteger)refId
	{
	SDL_Texture *texture = [self _textureFor:refId];
	if (texture)
		{
		float w, h;
		SDL_GetTextureSize(texture, &w, &h);
		return w;
		}
	SDL_Log("Cannot find texture %d to set colour-mod on", (int)refId);
	return -1;
	}

- (float) heightOfTexture:(NSInteger)refId
	{
	SDL_Texture *texture = [self _textureFor:refId];
	if (texture)
		{
		float w, h;
		SDL_GetTextureSize(texture, &w, &h);
		return h;
		}
	SDL_Log("Cannot find texture %d to set colour-mod on", (int)refId);
	return -1;
	}

/*****************************************************************************\
|* Test if the clip is set
\*****************************************************************************/
- (BOOL) clipEnabled
	{
	NSRect clip = [self clipRect];
	if (NSEqualRects(clip, NSZeroRect))
		return NO;
	return YES;
	}


/*****************************************************************************\
|* The text engine for this renderer
\*****************************************************************************/
- (TTF_TextEngine *) textEngine
	{
	return TTF_CreateRendererTextEngine(_renderer);
	}

/*****************************************************************************\
|* Presentation...
\*****************************************************************************/
- (NSSize) presentationSize
	{
	int w, h;
	SDL_RendererLogicalPresentation mode;
	SDL_GetRenderLogicalPresentation(_renderer, &w, &h, &mode);
	return NSMakeSize(w,h);
	}

- (int) presentationMode
	{
	int w, h;
	SDL_RendererLogicalPresentation mode;
	SDL_GetRenderLogicalPresentation(_renderer, &w, &h, &mode);
	return (int)mode;
	}

- (void)setPresentationSize:(NSSize)size
					   mode:(SDL_RendererLogicalPresentation)mode
	{
	int w 		= (int)size.width;
	int h 		= (int)size.height;
	SDL_SetRenderLogicalPresentation(_renderer, w, h, mode);
	}


/*****************************************************************************\
|* Viewport...
\*****************************************************************************/
- (NSRect) viewport
	{
	SDL_Rect viewport;
	SDL_GetRenderViewport(_renderer, &viewport);
	return NS_RECT(viewport);
	}

- (BOOL) setViewport:(NSRect)viewport
	{
	SDL_Rect vp = SDL_RECT(viewport);
	return SDL_SetRenderViewport(_renderer, &vp);
	}


/*****************************************************************************\
|* Scale...
\*****************************************************************************/
- (void) renderScaleX:(float *)xs y:(float *)ys
	{
	SDL_GetRenderScale(_renderer, xs, ys);
	}

- (BOOL) setScaleX:(float)xs y:(float)ys
	{
	return SDL_SetRenderScale(_renderer, xs, ys);
	}


/*****************************************************************************\
|* Set the clip
\*****************************************************************************/
- (BOOL) setClip:(NSRect)clipRect
	{
	SDL_Rect clip = SDL_RECT(clipRect);
	SDL_SetRenderClipRect(_renderer, &clip);
	return YES;
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
- (void) setDrawColour:(AZColour *)colour
	{
	SDL_SetRenderDrawColor(_renderer, colour.R,
									  colour.G,
									  colour.B,
									  colour.A);
	}

/*****************************************************************************\
|* Set the drawing colour
\*****************************************************************************/
- (int) setDrawColourToRed:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	return SDL_SetRenderDrawColor(_renderer, r, g, b, a);
	}

- (void) drawColourR:(uint8_t*)r g:(uint8_t*)g b:(uint8_t*)b a:(uint8_t*)a
	{
	SDL_GetRenderDrawColor(_renderer, r, g, b, a);
	}

/*****************************************************************************\
|* Clear the current texture target
\*****************************************************************************/
- (BOOL) clear
	{
	uint8_t a,r,g,b;
	SDL_GetRenderDrawColor(_renderer, &r, &g, &b, &a);
	SDL_SetRenderDrawColor(_renderer, _clearColour.R,
									  _clearColour.G,
									  _clearColour.B,
									  _clearColour.A);
	BOOL ok = SDL_RenderClear(_renderer);
	SDL_SetRenderDrawColor(_renderer, r, g,b , a);
	return ok;
	}


/*****************************************************************************\
|* Sync to VSync
\*****************************************************************************/
- (void) syncToVsync:(BOOL)yn
	{
	SDL_SetRenderVSync(_renderer, yn ? 1 : AZRendererVsyncDisabled);
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
- (BOOL) renderFilledRect:(NSRect)r
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

/*****************************************************************************\
|* Create a window with a given size, title, flags that is compatible with
|* this type of renderer
\*****************************************************************************/
- (BOOL) createWindowWithTitle:(NSString *)title
						 frame:(NSRect)frame
						 style:(NSInteger)styleFlags
	{
	BOOL ok = NO;
	if (!SDL_CreateWindowAndRenderer(title.UTF8String,
									 frame.size.width,
									 frame.size.height,
									 styleFlags,
									 &_sdlWindow,
									 &_renderer))
		{
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
		}
	else
		{
		ok = YES;
		_window = [[AZWindow alloc] initWithWindow:_sdlWindow];
		}

	return ok;
	}


/*****************************************************************************\
|* We do not support the GPU device
\*****************************************************************************/
- (nullable struct SDL_GPUDevice *)gpu
	{
	return NULL;
	}


/*****************************************************************************\
|* Return the renderer name
\*****************************************************************************/
- (nonnull NSString *)rendererName
	{
	return [NSString stringWithFormat:@"%s", SDL_GetRendererName(_renderer)];
	}


/*****************************************************************************\
|* Return the window
\*****************************************************************************/
- (nonnull AZWindow *)window
	{
	return _window;
	}

/*****************************************************************************\
|* Return an empty dictionary because this class uses the renderer for its
|* properties
\*****************************************************************************/
- (nonnull NSDictionary *)properties
	{
	return NSDictionary.new;
	}


/*****************************************************************************\
|* Render a bunch of lines
\*****************************************************************************/
- (int)renderLines:(nonnull NSPoint *)pts count:(int)count
	{
	BOOL isStack;
	SDL_FPoint *points = AZSmallAlloc(SDL_FPoint, count, &isStack);
	for (int i=0; i<count; i++)
		{
		points[i].x = pts[i].x;
		points[i].y = pts[i].y;
		}
	SDL_RenderLines(_renderer, points, count);
	AZSmallFree(points, isStack);
	return YES;
	}


/*****************************************************************************\
|* Render a bunch of points
\*****************************************************************************/
- (int)renderPoints:(nonnull NSPoint *)pts count:(int)count
	{
	BOOL isStack;
	SDL_FPoint *points = AZSmallAlloc(SDL_FPoint, count, &isStack);
	for (int i=0; i<count; i++)
		{
		points[i].x = pts[i].x;
		points[i].y = pts[i].y;
		}
	SDL_RenderPoints(_renderer, points, count);
	AZSmallFree(points, isStack);
	return YES;
	}


/*****************************************************************************\
|* Set the clear-colour
\*****************************************************************************/
- (void)setClearColour:(nonnull AZColour *)colour
	{
	_clearColour = colour.copy;
	}




@end
