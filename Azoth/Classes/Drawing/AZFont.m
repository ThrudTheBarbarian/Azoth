//
//  AZFont.m
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//
#import <SDL3/SDL.h>
#import <SDL3_ttf/SDL_ttf.h>
#import <SDL3_image/SDL_image.h>

#import "AZApplication.h"
#import "AZColour.h"
#import "AZFont.h"
#import "AZGlyphData.h"
#import "AZObject.h"
#import "AZRenderer.h"
#import "AZTypes.h"
#import "AZWindow.h"

#define LOAD_MAX_SURFACES 		10
#define CACHE_PADDING			1

/*****************************************************************************\
|* Target state preservation and restoration helpers
\*****************************************************************************/
typedef struct TargetState
	{
	NSRect 			clip;			// clipping rectangle
	NSRect 			viewport;		// viewport (!)
	NSSize 			lSize;			// logical size
	NSInteger		lMode;			// logical mode
	bool			clipEnabled;	// are we clipping
	AZScale			scale;			// scaling factors
	} TargetState;

static void _preserveTargetState(TargetState *state, AZRenderer *azr)
	{
	state->clipEnabled = azr.clipEnabled;
	if (state->clipEnabled)
		state->clip = azr.clipRect;
	state->viewport = azr.viewport;
	[azr renderScaleX:&(state->scale.x) y:&(state->scale.y)];
	state->lSize = azr.presentationSize;
	state->lMode = azr.presentationMode;
	}

static void _restoreTargetState(TargetState *state, AZRenderer *azr)
	{
	if (state->clipEnabled)
		[azr setClip:state->clip];

	if (state->lSize.width && state->lSize.height)
		[azr setPresentationSize:state->lSize mode:state->lMode];
	else
		{
		azr.viewport = state->viewport;
		[azr setScaleX:state->scale.x y:state->scale.y];
		}
	}

@interface AZFont()
// The list of extents for characters in this font
@property(strong, nonatomic)
NSMutableDictionary<NSNumber*, AZGlyphData *> *					extents;

// Location/size of the last glyph rendered
@property(strong, nonatomic) AZGlyphData *						lastGlyph;

// The style flags to pass to SDL_TTF, given that we may
// have modified the flags passed to us if there was a
// style-specific font available
@property(assign, nonatomic) int								ttfStyle;
@end

@implementation AZFont

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_extents 		= [NSMutableDictionary new];
		_textures		= [NSMutableArray new];
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
		.style 	= AZFONT_REGULAR
		};
	if ([font load:style])
		return font;
	return nil;
	}

+ (nullable AZFont *) systemFontWithsize:(int)points
	{
	AZFont *font = [[AZFont alloc] init];
	AZFontStyle style =
		{
		.size 	= points,
		.name 	= AZApp.systemFontInfo.name,
		.style 	= AZFONT_REGULAR
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
		_ttfStyle = style.style;
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
			BOOL outline = (_ttfStyle & AZFONT_OUTLINE) != 0;
			if (outline)
				{
				_ttfStyle &= ~AZFONT_OUTLINE;
				TTF_SetFontOutline(ttf, 1);
				}
			TTF_SetFontStyle(ttf, _ttfStyle);
			
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
	AZRenderer *azr = AZRenderer.renderer;

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
				NSInteger textureId = _textures[i].integerValue;
				[azr setTexture:textureId blendMode:SDL_BLENDMODE_BLEND];

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
		NSInteger textureId = _textures[i].integerValue;
		[azr setTexture:textureId blendMode:SDL_BLENDMODE_BLEND];
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
|* Return the bounds of a text string in this font
\*****************************************************************************/
- (NSSize) boundsFor:(NSString *)text
	{
	if (text == nil)
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					"text=nil in -boundsFor...");
		return NSZeroSize;
		}
	int w, h;
	TTF_GetStringSize(_ttfFont, text.UTF8String, 0, &w, &h);
	return NSMakeSize(w,h);
	}


/*****************************************************************************\
|* Set the colour to use (for all the texture-caches) when drawing with this
|* font
\*****************************************************************************/
- (void) setColourForAllCaches:(AZColour *)c
	{
	AZRenderer *azr = AZRenderer.renderer;

	for (NSNumber *textureId in _textures)
		{
		[azr setTexture:textureId.integerValue modR:c.red g:c.green b:c.blue];
		//SDL_SetTextureAlphaMod(texture, c.alpha);
		}
	}

/*****************************************************************************\
|* Get the cache image for a given cache-id
\*****************************************************************************/
- (NSInteger) glyphsFor:(NSInteger)cacheId
	{
	NSInteger cache = -1;
	if (cacheId >= 0 || cacheId < _textures.count)
		cache = _textures[cacheId].integerValue;

	return cache;
	}

/*****************************************************************************\
|* Get the metadata for a glyph
\*****************************************************************************/
- (nullable AZGlyphData *) glyphDataFor:(unichar)codepoint
	{
	if (_ttfFont == NULL)
		return nil;

	AZRenderer *azr 	= AZRenderer.renderer;
	AZGlyphData *data 	= _extents[@(codepoint)];

	if (data == nil)
		{
		float w 		= [azr widthOfTexture:_lastGlyph.cacheId];
		float h 		= [azr heightOfTexture:_lastGlyph.cacheId];
		SDL_Color white = {255, 255, 255, 255};

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
		AZRenderer *azr = AZRenderer.renderer;
		SDL_SetSurfaceBlendMode(glyph, SDL_BLENDMODE_NONE);
		// move [azr lockFocusOn:_lastGlyph.cacheId];

		NSInteger previous = azr.currentFocus;
		TargetState s;

		/*****************************************************************\
		|* only backup if previous target existed (SDL will preserve them
		|* for the default target)
		\*****************************************************************/
		if (previous > 0)
			_preserveTargetState(&s, azr);

		NSInteger img = [azr createTextureWithSurface:glyph];

		[azr lockFocusOn:img];
		[azr blitFrom:img src:NSZeroRect dst:_lastGlyph.rect];
		[azr unlockFocus];

		if (previous > 0)
			{
			[azr lockFocusOn:previous];
			_restoreTargetState(&s, azr);
			}

		[azr releaseTexture:img];
		ok = true;
		}
	return ok;
	}

/*****************************************************************************\
|* Grow the cache if we still have space
\*****************************************************************************/
- (BOOL) _growGlyphCache
	{
	BOOL ok 			= NO;
	AZRenderer *azr		= AZRenderer.renderer;

	NSSize size			= NSMakeSize(_height * 12,_height * 12);
	NSInteger cache 	= [azr createTextureOfSize:size
											format:SDL_PIXELFORMAT_RGBA8888
										 withFlags:SDL_TEXTUREACCESS_TARGET];

	if (cache < 0 || ![self _setGlyphCache:(int)_textures.count texture:cache])
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
			"Error: FontCache ran out of packing space and could not"
			 " add another cache level.\n");
		[azr releaseTexture:cache];
		}
	else
		{
		NSInteger previous = azr.currentFocus;
		TargetState s;
		
		/*********************************************************************\
		|* only backup if previous target existed (SDL will preserve them for
		|* the default target)
		\*********************************************************************/
		if (previous >= 0)
			_preserveTargetState(&s, azr);

		[azr setTexture:cache blendMode:SDL_BLENDMODE_BLEND];
		[azr lockFocusOn:cache];

		Uint8 r, g, b, a;
		[azr drawColourR:&r g:&g b:&b a:&a];
		[azr setDrawColourToRed:0 g:0 b:0 a:0];
		[azr clear];
		[azr setDrawColourToRed:r g:g b:b a:a];
		[azr unlockFocus];

		if (previous >= 0)
			{
			[azr lockFocusOn:previous];
			_restoreTargetState(&s, azr);
			}

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

	AZRenderer *azr = AZRenderer.renderer;
	for (NSNumber *textureId in _textures)
		[azr releaseTexture:textureId.integerValue];
	[_textures removeAllObjects];
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
			_lastGlyph.cacheId = (int) _textures.count;
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
	AZRenderer *azr = AZRenderer.renderer;

	BOOL ok = (data_surface != NULL);

//	if (!IMG_SavePNG(data_surface, "/tmp/letters.png"))
//		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't save surface %s",
//					 SDL_GetError());

	if (ok)
		{
		NSInteger texNew = -1;

		/*********************************************************************\
		|* Upload with render target enabled so we can add glyphs later
		\*********************************************************************/
		if (!_renderToTarget)
			texNew = [azr createTextureWithSurface:data_surface];
		else
			{
			/*****************************************************************\
			|* Create the new texture
			\*****************************************************************/
			NSSize size = NSMakeSize(data_surface->w, data_surface->h);
			texNew 	    = [azr createTextureOfSize:size
											format:data_surface->format
										 withFlags:SDL_TEXTUREACCESS_TARGET];
			[azr setTexture:texNew blendMode:SDL_BLENDMODE_BLEND];

			/*****************************************************************\
			|* Create the texture
			\*****************************************************************/
			NSInteger temp	= [azr createTextureWithSurface:data_surface];

			/*****************************************************************\
			|* only backup if previous target existed (SDL will preserve them
			|* for the default target)
			\*****************************************************************/
			NSInteger prevTarget = azr.currentFocus;

			TargetState s;
			if (prevTarget >= 0)
				_preserveTargetState(&s, azr);

			[azr setTexture:temp blendMode:SDL_BLENDMODE_NONE];
			[azr lockFocusOn:texNew];

			Uint8 r, g, b, a;
			[azr drawColourR:&r g:&g b:&b a:&a];
			[azr setDrawColourToRed:0 g:0 b:0 a:0];
			[azr clear];
			[azr setDrawColourToRed:r g:g b:b a:a];

			[azr blitFrom:temp src:NSZeroRect dst:NSZeroRect];
			[azr unlockFocus];
			if (prevTarget)
				{
				_restoreTargetState(&s, azr);
				[azr lockFocusOn:prevTarget];
				}
			[azr releaseTexture:temp];
			}
			
		if (texNew < 0 || ![self _setGlyphCache:cacheId texture:texNew])
			{
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
				"Error: FontCache ran out of packing space and could not "
				"add another cache level.\n");
			[azr releaseTexture:texNew];
			ok = NO;
			}
		}
    return ok;
	}

/*****************************************************************************\
|* Store a texture to the glyph cache
\*****************************************************************************/
-(BOOL) _setGlyphCache:(NSInteger)cacheId texture:(NSInteger)texture
	{
	BOOL ok 		= YES;
	NSNumber *texId = [NSNumber numberWithInteger:texture];

	/*************************************************************************\
    |* Caches must be sequentially added
    \*************************************************************************/
	if (cacheId == _textures.count)
		[_textures addObject:texId];

	else if ((cacheId >= 0) && (cacheId < _textures.count))
		_textures[cacheId] = texId;
	else
		ok = NO;

    return ok;
	}

/*****************************************************************************\
|* Find a path for the font, or return nil
\*****************************************************************************/
- (nullable NSString *) _fetchPathFor:(NSString *)name
	{
	static NSDictionary<NSNumber *,NSString *> * map = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		map = @{ @(AZFONT_REGULAR) 					: @"Regular",
				 @(AZFONT_ITALIC)					: @"Italic",
				 @(AZFONT_BOLD)	 					: @"Bold",
				 @(AZFONT_BLACK)					: @"Black",
				 @(AZFONT_EXTRABOLD)				: @"ExtraBold",
				 @(AZFONT_LIGHT)					: @"Light",
				 @(AZFONT_MEDIUM)					: @"Medium",
				 @(AZFONT_THIN)						: @"Thin",
				 @(AZFONT_BOLD|AZFONT_ITALIC)	 	: @"BoldItalic",
				 @(AZFONT_BLACK|AZFONT_ITALIC)		: @"BlackItalic",
				 @(AZFONT_EXTRABOLD|AZFONT_ITALIC)	: @"ExtraBoldItalic",
				 @(AZFONT_LIGHT|AZFONT_ITALIC)		: @"LightItalic",
				 @(AZFONT_MEDIUM|AZFONT_ITALIC)		: @"MediumItalic",
				 @(AZFONT_THIN|AZFONT_ITALIC)		: @"ThinItalic"
				 };
		});


	/*************************************************************************\
	|* See if we want to modify the filename based on the style
	\*************************************************************************/
	int nonFileBased	= AZFONT_UNDERLINE|AZFONT_STRIKETHROUGH;
	int style 			= _ttfStyle & (~nonFileBased);
	NSString *candidate = map[@(style)];
	if (candidate != nil)
		{
		NSString *path  = [NSString stringWithFormat:@"%@-%@", name, candidate];
		NSString *at   	= [self _searchForPath:path];
		if (at)
			{
			_ttfStyle &= nonFileBased;
			return at;
			}
		}
	return [self _searchForPath:name];
	}

- (nullable NSString *) _searchForPath:(NSString *)name
	{
	/*************************************************************************\
	|* If it's an absolute path, use it
	\*************************************************************************/
	if ([name hasPrefix:@"/"])
		return name;

	/*************************************************************************\
	|* If it's an Azoth-provided font, use it
	\*************************************************************************/
	NSString *rsrc = [[NSBundle bundleForClass:[self class]] resourcePath];
	NSString *path = [NSString stringWithFormat:@"%@/Fonts/%@.ttf", rsrc, name];

	NSFileManager *fm = NSFileManager.defaultManager;
	if ([fm fileExistsAtPath:path])
		return path;

	/*************************************************************************\
	|* If it's a user-app-provided font, use it
	\*************************************************************************/
	if (AZApp.delegate)
		{
		NSObject *delegate = (NSObject *)AZApp.delegate;
		rsrc = [[NSBundle bundleForClass:[delegate class]] resourcePath];
		NSString *path = [NSString stringWithFormat:@"%@/Fonts/%@.ttf", rsrc, name];
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
