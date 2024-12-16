//
//  AZFont.m
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//
#import <SDL3/SDL.h>
#import <SDL3_ttf/SDL_ttf.h>
#import <SDL3_image/SDL_image.h>

#import "AZApp.h"
#import "AZColour.h"
#import "AZFont.h"
#import "AZGlyphData.h"
#import "AZObject.h"
#import "AZTypes.h"
#import "AZWindow.h"

#define LOAD_MAX_SURFACES 		10
#define CACHE_PADDING			1

/*****************************************************************************\
|* Target state preservation and restoration helpers
\*****************************************************************************/
typedef struct TargetState
	{
	SDL_Rect 							clip;			// clipping rectangle
	SDL_Rect 							viewport;		// viewport (!)
	int									lWidth;			// logical width
	int 								lHeight;		// logical height
	SDL_RendererLogicalPresentation		lMode;			// logical mode
	bool								clipEnabled;	// are we clipping
	AZScale								scale;			// scaling factors
	} TargetState;

static void _preserveTargetState(TargetState *state, SDL_Renderer *renderer)
	{
	state->clipEnabled = SDL_RenderClipEnabled(renderer);
	if (state->clipEnabled)
		SDL_GetRenderClipRect(renderer, &(state->clip));

	SDL_GetRenderViewport(renderer, &(state->viewport));
	SDL_GetRenderScale(renderer, &(state->scale.x), &(state->scale.y));
	SDL_GetRenderLogicalPresentation(renderer,
									 &(state->lWidth),
									 &(state->lHeight),
									 &(state->lMode));
	}

static void _restoreTargetState(TargetState *state, SDL_Renderer *renderer)
	{
	if (state->clipEnabled)
		SDL_SetRenderClipRect(renderer, &(state->clip));
	if (state->lWidth && state->lHeight)
		SDL_SetRenderLogicalPresentation(renderer,
										 state->lWidth,
										 state->lHeight,
										 state->lMode);
	else
		{
		SDL_SetRenderViewport(renderer, &(state->viewport));
		SDL_SetRenderScale(renderer, state->scale.x, state->scale.y);
		}
	}

/*****************************************************************************\
|* Helper functions for creating various primitives
\*****************************************************************************/
static inline SDL_Rect mkRect(int x, int y, int w, int h)
	{
	SDL_Rect r = {x, y, w, h};
	return r;
	}

static inline SDL_Color mkColour(uint8_t r, uint8_t g, uint8_t b, uint8_t a)
	{
	SDL_Color c = {r, g, b, a};
	return c;
	}

@interface AZFont()
// The list of extents for characters in this font
@property(strong, nonatomic)
NSMutableDictionary<NSNumber*, AZGlyphData *> *					extents;

// Location/size of the last glyph rendered
@property(strong, nonatomic) AZGlyphData *						lastGlyph;
@end

@implementation AZFont

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_renderer		= AZApp.sharedInstance.window.renderer;
		_extents 		= [NSMutableDictionary new];
		_glyphs			= [NSMutableArray new];
		_lastGlyph		= [AZGlyphData new];
		[self _initialiseFont];
		}
	return self;
	}

+ (AZFont *) font
	{
	return [[AZFont alloc] init];
	}

+ (nullable AZFont *) fontWithName:(NSString *)name size:(int)points
	{
	AZFont *font = [[AZFont alloc] init];
	AZFontStyle style =
		{
		.size 	= points,
		.name 	= name,
		.style 	= AZFONT_STYLE_NORMAL
		};
	if ([font load:style])
		return font;
	return nil;
	}

+ (nullable AZFont *) systemFontWithsize:(int)points
	{
	AZApp *app 	 = [AZApp sharedInstance];
	AZFont *font = [[AZFont alloc] init];
	AZFontStyle style =
		{
		.size 	= points,
		.name 	= app.systemFontInfo.name,
		.style 	= AZFONT_STYLE_NORMAL
		};
	if ([font load:style])
		return font;
	return nil;
	}

+ (nullable AZFont *) fontWithStyle:(AZFontStyle)style
	{
	AZFont *font = [[AZFont alloc] init];
	if ([font load:style])
		return font;
	return nil;
	}

/*****************************************************************************\
|* Load a font
\*****************************************************************************/
- (BOOL) load:(AZFontStyle)style
	{
	BOOL result = NO;

	if (!TTF_WasInit())
		TTF_Init();

	if (!TTF_WasInit())
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					 "Unable to initialise TTF: %s", SDL_GetError());
		}
	else
		{
		NSString *fullpath = [self _fetchPathFor:style.name];
		if (fullpath == nil)
			{
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
						 "Cannot find truetype font '%s'",
						 fullpath.fileSystemRepresentation);
			return NO;
			}

		const char *path = fullpath.fileSystemRepresentation;
		TTF_Font *ttf = TTF_OpenFont(path, style.size);
		if (ttf == NULL)
			{
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
						 "Cannot load truetype font '%s'", path);
			}
		else
			{
			/*****************************************************************\
			|* Check to see if we want it outlined, then set the style
			\*****************************************************************/
			BOOL outline = (style.style & AZFONT_STYLE_OUTLINE) != 0;
			if (outline)
				{
				style.style &= ~AZFONT_STYLE_OUTLINE;
				TTF_SetFontOutline(ttf, 1);
				}
			TTF_SetFontStyle(ttf, style.style);
			
			/*****************************************************************\
			|* Instantiate the font, now it's been loaded
			\*****************************************************************/
			result = [self loadFont:ttf];
			if (result)
				_ownsTTF = true;
			}
		}
	return result;
	}

/*****************************************************************************\
|* Load a font, for real this time
\*****************************************************************************/
- (BOOL) loadFont:(TTF_Font *)ttf
	{
    BOOL ok = (ttf != NULL);
	if (ok)
		{
		[self _reset];

		_ttfFont		= ttf;

		_height 		= TTF_GetFontHeight(ttf);
    	_ascent 		= TTF_GetFontAscent(ttf);
    	_descent 		= -TTF_GetFontDescent(ttf);

		/*********************************************************************\
		|* Handle fonts lying about their statistics
		\*********************************************************************/
		if (_height < _ascent - _descent)
        	_height = _ascent - _descent;
    	_baseline = _height - _descent;

		/*********************************************************************\
		|* Copy glyphs from the surface to the font texture and store the
		|* position data. Pack row by row into a square texture. Try figuring
		|* out dimensions that make sense for the font size
		\*********************************************************************/
        unsigned int w = _height*12;
        unsigned int h = _height*12;
        SDL_Surface* surfaces[LOAD_MAX_SURFACES];
        int numSurfs = 1;
		surfaces[0] = [self _createSurfaceOfWidth:w height:h];

		_lastGlyph.rect = NSMakeRect(CACHE_PADDING,CACHE_PADDING,0,_height+1);

		SDL_Color white = {255, 255, 255, 255};
		int max 		= (int) _loadingString.length;
		for (int i=0; i<max; i++)
			{
			unichar c 			= [_loadingString characterAtIndex:i];
			NSString *character = [NSString stringWithFormat:@"%C", c];
			const char *utf8	= [character UTF8String];
			int len				= (int) strlen(utf8);
            SDL_Surface* glyph 	= TTF_RenderText_Blended(ttf, utf8, len, white);
            if (glyph == NULL)
                continue;

			// Tabs are special, just clear the glyph if this is a tab char
			if (c == '\t')
				SDL_FillSurfaceRect(glyph, NULL, 0);

            // Try packing.  If it fails, create a new surface for the next
            // cache level.
			BOOL packed = ([self _packGlyphDataFor:c
										     width:glyph->w
										  maxWidth:surfaces[numSurfs-1]->w
										 maxHeight:surfaces[numSurfs-1]->h] != NULL);

            if (!packed)
				{
                int i = numSurfs-1;
                if (numSurfs >= LOAD_MAX_SURFACES)
					{
                    // Can't do any more!
						SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
						"FontCache error: Could not create enough cache "
						 "surfaces to fit all of the loading string!\n");
					SDL_DestroySurface(glyph);
                    break;
					}

                // Upload the current surface to the glyph cache now so we can
                // keep the cache level packing cursor up to date as we go.
				[self _uploadGlyphCache:i surface:surfaces[i]];
                SDL_DestroySurface(surfaces[i]);
                SDL_SetTextureBlendMode((SDL_Texture *)(_glyphs[i].ptr),
										SDL_BLENDMODE_BLEND);

                // Update the glyph cursor to the new cache level.  We need
                // to do this here because the actual cache lags behind our
                // use of the packing above.
                _lastGlyph.cacheId = numSurfs;


				surfaces[numSurfs] = [self _createSurfaceOfWidth:w height:h];
				numSurfs++;
				}

            // Try packing for the new surface, then blit onto it.
            if (packed || ([self _packGlyphDataFor:c
										     width:glyph->w
										  maxWidth:surfaces[numSurfs-1]->w
										 maxHeight:surfaces[numSurfs-1]->h] != NULL))
				{
                SDL_SetSurfaceBlendMode(glyph, SDL_BLENDMODE_NONE);
                SDL_Rect src = {0, 0, glyph->w, glyph->h};
                SDL_Rect dst = {_lastGlyph.rect.origin.x,
								_lastGlyph.rect.origin.y,
								_lastGlyph.rect.size.width,
								_lastGlyph.rect.size.height};
                SDL_BlitSurface(glyph, &src, surfaces[numSurfs-1], &dst);
				}

            SDL_DestroySurface(glyph);
			}
		
		int i = numSurfs-1;
		
		[self _uploadGlyphCache:i surface:surfaces[i]];
		SDL_DestroySurface(surfaces[i]);
		SDL_SetTextureBlendMode((SDL_Texture *)(_glyphs[i].ptr),
								SDL_BLENDMODE_BLEND);
        ok = YES;
        }

    return ok;
	}

/*****************************************************************************\
|* Return the width of a text string in this font
\*****************************************************************************/
- (int) textWidthFor:(NSString *)text
	{
	if (text == nil)
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					"text=nil in -textWidthFor...");
		return 0;
		}

	int width 		= 0;
	int lineWidth	= 0;
	NSInteger len	= text.length;

	for (NSInteger i=0; i<len; i++)
		{
		unichar c = [text characterAtIndex:i];

		if (c == '\n')
			{
			lineWidth = (lineWidth > width) ? lineWidth : width;
			width = 0;
			continue;
			}
		AZGlyphData *glyph = [self glyphDataFor:c];
		if (glyph)
			width += glyph.rect.size.width;
		else
			{
			glyph = [self glyphDataFor:' '];
			width += glyph.rect.size.width;
			}
		}
	lineWidth = (lineWidth > width) ? lineWidth : width;
	return lineWidth;
	}

/*****************************************************************************\
|* Set the colour to use (for all the texture-caches) when drawing with this
|* font
\*****************************************************************************/
- (void) setColourForAllCaches:(AZColour *)c
	{
	for (AZObject *obj in _glyphs)
		{
		if ([obj.hint isEqualToString:kTextureType])
			{
			SDL_Texture *texture = (SDL_Texture *)obj.ptr;
			SDL_SetTextureColorMod(texture, c.red, c.green, c.blue);
			//SDL_SetTextureAlphaMod(texture, c.alpha);
			}
		}
	}

/*****************************************************************************\
|* Get the cache image for a given cache-id
\*****************************************************************************/
- (nullable SDL_Texture *) glyphsFor:(NSInteger)cacheId
	{
	SDL_Texture *cache = NULL;
	if (cacheId >= 0 || cacheId < _glyphs.count)
        {
        AZObject *obj = _glyphs[cacheId];
		if ([obj.hint isEqualToString:kTextureType])
			cache = (SDL_Texture *)obj.ptr;
        }
	return cache;
	}

/*****************************************************************************\
|* Get the metadata for a glyph
\*****************************************************************************/
- (nullable AZGlyphData *) glyphDataFor:(unichar)codepoint
	{
	if (_ttfFont == NULL)
		return nil;

	AZGlyphData *data = _extents[@(codepoint)];
	if (data == nil)
		{
		float w, h;
		SDL_Color white = {255, 255, 255, 255};

		SDL_Texture *cacheImage = [self glyphsFor:_lastGlyph.cacheId];
		if (cacheImage == NULL)
			{
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
				"FontCache: Failed to load cache image, so cannot "
				 "add new glyphs!\n");
			return nil;
			}

		SDL_GetTextureSize(cacheImage, &w, &h);

		NSString *character = [NSString stringWithFormat:@"%C", codepoint];
		const char *utf8	= [character UTF8String];
		int len				= (int)strlen(utf8);
		SDL_Surface *surf 	= TTF_RenderText_Blended(_ttfFont, utf8, len, white);
		if (surf == NULL)
			return nil;

		data = [self _packGlyphDataFor:codepoint
								 width:surf->w
							  maxWidth:(int)w
							 maxHeight:(int)h];

		if (data == nil)
			{
			// Grow the cache
			[self _growGlyphCache];

			// Try packing again
			data = [self _packGlyphDataFor:codepoint
									 width:surf->w
								  maxWidth:(int)w
								 maxHeight:(int)h];
			if (data == nil)
				{
				SDL_DestroySurface(surf);
				return nil;
				}
			}

		// Render onto the cache texture
		[self _addGlyphToCache:surf];

		SDL_DestroySurface(surf);
		}

	return data;
	}

// MARK: Private methods

/*****************************************************************************\
|* Add a glyph to the cache
\*****************************************************************************/
- (BOOL) _addGlyphToCache:(SDL_Surface*) glyph
	{
	BOOL ok = (glyph != NULL);

	if (ok)
		{
		SDL_SetSurfaceBlendMode(glyph, SDL_BLENDMODE_NONE);
		SDL_Texture * dest = [self glyphsFor:_lastGlyph.cacheId];
		if (dest != NULL)
			{
			SDL_Texture* previous = SDL_GetRenderTarget(_renderer);
			TargetState s;
			
			/*****************************************************************\
			|* only backup if previous target existed (SDL will preserve them
			|* for the default target)
			\*****************************************************************/
			if (previous != NULL)
				_preserveTargetState(&s, _renderer);

			SDL_Texture *img = SDL_CreateTextureFromSurface(_renderer, glyph);

			SDL_FRect destrect = {_lastGlyph.rect.origin.x,
								  _lastGlyph.rect.origin.y,
								  _lastGlyph.rect.size.width,
								  _lastGlyph.rect.size.height};
			SDL_SetRenderTarget(_renderer, dest);
			SDL_RenderTexture(_renderer, img, NULL, &destrect);
			SDL_SetRenderTarget(_renderer, previous);
			if (previous != NULL)
				_restoreTargetState(&s, _renderer);

			SDL_DestroyTexture(img);
			ok = true;
			}
		}
	return ok;
	}

/*****************************************************************************\
|* Grow the cache if we still have space
\*****************************************************************************/
- (BOOL) _growGlyphCache
	{
	BOOL ok 			= NO;
    SDL_Texture* cache	= SDL_CreateTexture(_renderer,
											SDL_PIXELFORMAT_RGBA8888,
											SDL_TEXTUREACCESS_TARGET,
											_height * 12,
											_height * 12);

	if (cache == NULL || ![self _setGlyphCache:(int)_glyphs.count texture:cache])
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
			"Error: FontCache ran out of packing space and could not"
			 " add another cache level.\n");
        SDL_DestroyTexture(cache);
		}
	else
		{
		SDL_Texture* previous = SDL_GetRenderTarget(_renderer);
		TargetState s;
		
		/*********************************************************************\
		|* only backup if previous target existed (SDL will preserve them for
		|* the default target)
		\*********************************************************************/
		if (previous != NULL)
			_preserveTargetState(&s, _renderer);

		SDL_SetTextureBlendMode(cache, SDL_BLENDMODE_BLEND);
		SDL_SetRenderTarget(_renderer, cache);

		Uint8 r, g, b, a;
		SDL_GetRenderDrawColor(_renderer, &r, &g, &b, &a);
		SDL_SetRenderDrawColor(_renderer, 0, 0, 0, 0);
		SDL_RenderClear(_renderer);
		SDL_SetRenderDrawColor(_renderer, r, g, b, a);
		SDL_SetRenderTarget(_renderer, previous);
		
		if (previous)
			_restoreTargetState(&s, _renderer);

		ok = true;
		}
		
    return ok;
	}

/*****************************************************************************\
|* Initialise for a new font
\*****************************************************************************/
- (void) _initialiseFont
	{
	_ttfFont		= NULL;
	_tabWidth		= 4;
	_ownsTTF		= NO;
	_height			= 0;
	_maxWidth		= 0;
	_baseline		= 0;
	_ascent			= 0;
	_descent		= 0;
	_lineSpacing	= 0;
	_letterSpacing	= 0;

	/*************************************************************************\
	|* Create the default string of chars-to-cache (the ASCII set)
	\*************************************************************************/
	NSMutableString *chars = [NSMutableString new];
	for (int i=' '; i<127; i++)
		[chars appendFormat:@"%c", i];
	[chars appendFormat:@"%c", '\t'];
	_loadingString = [chars copy];
	}

/*****************************************************************************\
|* Clear everything out for a new font
\*****************************************************************************/
- (void) _reset;
	{
	if (_ownsTTF)
		TTF_CloseFont(_ttfFont);
	_ownsTTF = NO;
	_ttfFont = NULL;

	for (AZObject *object in _glyphs)
		{
		if ([object.hint isEqualToString:kTextureType])
			SDL_DestroyTexture(object.ptr);
		}
	[_glyphs removeAllObjects];
	[_extents removeAllObjects];
	[self _initialiseFont];
	}

/*****************************************************************************\
|* Create an SDL surface of a given size
\*****************************************************************************/
- (SDL_Surface *) _createSurfaceOfWidth:(int)width height:(int)height
	{
	return SDL_CreateSurface(width, height, SDL_PIXELFORMAT_RGBA8888);
	}

/*****************************************************************************\
|* Pack a glyph into a surface, if it will fit
\*****************************************************************************/
- (nullable AZGlyphData*) _packGlyphDataFor:(unichar)codepoint
						         	  width:(int)width
						           maxWidth:(int)maxW
						          maxHeight:(int)maxH
	{
	int X = _lastGlyph.rect.origin.x;
	int Y = _lastGlyph.rect.origin.y;
	int W = _lastGlyph.rect.size.width;
	int H = _lastGlyph.rect.size.height;

    // TAB is special!
    if (codepoint == '\t')
		{
		AZGlyphData *spaceGlyph = [self glyphDataFor:' '];
        width = _tabWidth * spaceGlyph.rect.size.width;
		}

    if (X + W + width >= maxW - CACHE_PADDING)
		{
        if (Y + H + H >= maxH - CACHE_PADDING)
			{
            // Get ready to pack on the next cache level when it is ready
			_lastGlyph.cacheId = (int) _glyphs.count;
			_lastGlyph.rect	= NSMakeRect(CACHE_PADDING, CACHE_PADDING, 0, H);
            return NULL;
			}
        else
			{
            // Go to next row
			_lastGlyph.rect = NSMakeRect(CACHE_PADDING, Y+H, 0, H);
			}
		}
		
	X = _lastGlyph.rect.origin.x;
	Y = _lastGlyph.rect.origin.y;
	W = _lastGlyph.rect.size.width;
	H = _lastGlyph.rect.size.height;

    // Move to next space
	_lastGlyph.rect = NSMakeRect(X+W+1+CACHE_PADDING, Y, width, H);

	_extents[@(codepoint)] = [_lastGlyph copy];
	return [_extents objectForKey:@(codepoint)];
	}

/*****************************************************************************\
|* Upload a surface to the glyph cache
\*****************************************************************************/
- (BOOL) _uploadGlyphCache:(int)cacheId surface:(SDL_Surface*)data_surface
	{
	BOOL ok = (data_surface != NULL);

//	if (!IMG_SavePNG(data_surface, "/tmp/letters.png"))
//		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't save surface %s",
//					 SDL_GetError());

	if (ok)
		{
		SDL_Texture* texNew = NULL;

		/*********************************************************************\
		|* Upload with render target enabled so we can add glyphs later
		\*********************************************************************/
		if (!_renderToTarget)
			texNew = SDL_CreateTextureFromSurface(_renderer, data_surface);
		else
			{
			/*****************************************************************\
			|* Create the new texture
			\*****************************************************************/
			texNew = SDL_CreateTexture(_renderer,
									   data_surface->format,
									   SDL_TEXTUREACCESS_TARGET,
									   data_surface->w,
									   data_surface->h);
			SDL_SetTextureBlendMode(texNew, SDL_BLENDMODE_BLEND);

			/*****************************************************************\
			|* Create the texture
			\*****************************************************************/
			SDL_Texture* temp = SDL_CreateTextureFromSurface(_renderer,
															 data_surface);

			/*****************************************************************\
			|* only backup if previous target existed (SDL will preserve them
			|* for the default target)
			\*****************************************************************/
			SDL_Texture* prev_target = SDL_GetRenderTarget(_renderer);
			TargetState s;
			if (prev_target)
				_preserveTargetState(&s, _renderer);

			SDL_SetTextureBlendMode(temp, SDL_BLENDMODE_NONE);
			SDL_SetRenderTarget(_renderer, texNew);

			Uint8 r, g, b, a;
			SDL_GetRenderDrawColor(_renderer, &r, &g, &b, &a);
			SDL_SetRenderDrawColor(_renderer, 0, 0, 0, 0);
			SDL_RenderClear(_renderer);
			SDL_SetRenderDrawColor(_renderer, r, g, b, a);

			SDL_RenderTexture(_renderer, temp, NULL, NULL);
			SDL_SetRenderTarget(_renderer, prev_target);
			if (prev_target)
				_restoreTargetState(&s, _renderer);
			SDL_DestroyTexture(temp);
			}
			
		if (texNew == NULL || ![self _setGlyphCache:cacheId texture:texNew])
			{
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
				"Error: FontCache ran out of packing space and could not "
				"add another cache level.\n");
			SDL_DestroyTexture(texNew);
			ok = NO;
			}
		}
    return ok;
	}

/*****************************************************************************\
|* Store a texture to the glyph cache
\*****************************************************************************/
-(BOOL) _setGlyphCache:(int)cacheId texture:(SDL_Texture*)texture
	{
	BOOL ok 		= YES;
	AZObject *obj 	= [AZObject objectWithPointer:texture andHint:kTextureType];

	/*************************************************************************\
    |* Caches must be sequentially added
    \*************************************************************************/
	if (cacheId == _glyphs.count)
		[_glyphs addObject:obj];

	else if ((cacheId >= 0) && (cacheId < _glyphs.count))
		_glyphs[cacheId] = obj;
	else
		ok = NO;

    return ok;
	}

/*****************************************************************************\
|* Find a path for the font, or return nil
\*****************************************************************************/
- (nullable NSString *) _fetchPathFor:(NSString *)name
	{
	NSFileManager *fm = NSFileManager.defaultManager;

	/*************************************************************************\
	|* If it's an absolute path, use it
	\*************************************************************************/
	if ([name hasPrefix:@"/"])
		return name;

	/*************************************************************************\
	|* If it's an Azoth-provided font, use it
	\*************************************************************************/
	NSString *rsrc = [[NSBundle bundleForClass:[self class]] resourcePath];
	NSString *path = [NSString stringWithFormat:@"%@/%@.ttf", rsrc, name];
	if ([fm fileExistsAtPath:path])
		return path;

	/*************************************************************************\
	|* If it's a user-app-provided font, use it
	\*************************************************************************/
	AZApp *app = AZApp.sharedInstance;
	if (app.delegate)
		{
		NSObject *delegate = (NSObject *)app.delegate;
		rsrc = [[NSBundle bundleForClass:[delegate class]] resourcePath];
		NSString *path = [NSString stringWithFormat:@"%@/%@.ttf", rsrc, name];
		if ([fm fileExistsAtPath:path])
			return path;
		}

	/*************************************************************************\
	|* If it's in the user's Library/Fonts folder, use it
	\*************************************************************************/
	path = [NSString stringWithFormat:@"%@/Library/Fonts/%@.ttf",
			NSHomeDirectory(), name];
	if ([fm fileExistsAtPath:path])
		return path;

	return nil;
	}

@end
