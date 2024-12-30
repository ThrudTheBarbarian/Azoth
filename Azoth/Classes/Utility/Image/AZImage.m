//
//  AZImage.m
//  Azoth
//
//  Created by Simon Gornall on 12/28/24.
//

#import <SDL3/SDL.h>
#import <SDL3_image/SDL_image.h>

#import "AZApp.h"
#import "AZImage.h"
#import "AZImageCache.h"
#import "AZPainter.h"
#import "AZRenderer.h"

#define CACHE_WIDTH			1024
#define CACHE_HEIGHT		1024

/*****************************************************************************\
|* "Private" properties for the class
\*****************************************************************************/
@interface AZImage()

// The location within the texture that defines this image
@property(assign, nonatomic) NSRect									srcRect;

// The texture box we were initially allocted
@property(assign, nonatomic) NSRect									texRect;

// The location within the texture that defines this image
@property(strong, nonatomic, nullable) AZImageCache *				imageCache;

// The drawing handler, for images that have one
@property(strong, nonatomic, nullable) AZImageDrawingHandler 		handler;

// The texture that the renderer was previously focussed on
@property(assign, nonatomic) NSInteger								oldFocus;
@end

/*****************************************************************************\
|* File-private vars
\*****************************************************************************/
static NSMutableDictionary<NSString*,NSMutableArray<AZImageCache*>*> * _cache;

@implementation AZImage

/*****************************************************************************\
|* Initialisation: initialise an instance
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_imageCache = nil;
		_texture 	= -3;
		_srcRect	= NSZeroRect;
		_handler	= nil;
		
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken,
			^{
			_cache = [NSMutableDictionary new];
			});
		}
	return self;
	}

/*****************************************************************************\
|* Dealloc: clean up
\*****************************************************************************/
- (void) dealloc
	{
	[_imageCache release:_texRect];
	}

/*****************************************************************************\
|* Initialisation: Load an image from the current bundle's Resources/ directory
\*****************************************************************************/
+ (AZImage *) imageNamed:(NSString *)name
	{
	NSString *rsrc 		= [[NSBundle mainBundle] resourcePath];
	NSString *fullpath 	= [NSString stringWithFormat:@"%@/%@", rsrc, name];

	return [AZImage imageWithContentsOfFile:fullpath];
	}


/*****************************************************************************\
|* Initialisation: Get an image from the icon atlas
\*****************************************************************************/
+ (AZImage *) imageWithSystemSymbolName:(NSString *)name
	{
	AZApp *app 	= AZApp.sharedInstance;
	NSRect r 	= [app srcRectFor:name in:kIconsMap];
	if (IS_ZERORECT(r))
		return nil;

	AZImage *img 	= [AZImage new];
	img.texture		= [app textureFor:kIconsMap];
	img.srcRect		= r;
	return img;
	}


/*****************************************************************************\
|* Initialisation: Load an image from a file path
\*****************************************************************************/
+ (AZImage *) imageWithContentsOfFile:(NSString *)fullpath
	{
	const char *path	= fullpath.fileSystemRepresentation;

	SDL_Surface *img = IMG_Load(path);
	if (img)
		{
		AZImage *image = [AZImage new];
		if ([image _loadSurface:img])
			return image;
		else
			SDL_Log("Cannot convert surface to texture for %s", path);
		}
	else
		SDL_Log("Cannot load image at %s", path);

	return nil;
	}

/*****************************************************************************\
|* Initialisation: Create an image with a GPU texture of a given size
\*****************************************************************************/
+ (AZImage *) imageWithSize:(NSSize) size
	{
	AZRenderer *azr		= AZRenderer.renderer;
	NSInteger texture	= [azr createTextureOfSize:size];
	if (texture < 0)
		return nil;

	AZImage *img 	= [AZImage new];
	img.texture		= texture;
	img.srcRect		= NSMakeRect(0,0,size.width, size.height);
	return img;
	}

/*****************************************************************************\
|* Initialisation: Create an image that draws on demand
\*****************************************************************************/
+ (AZImage *) imageWithSize:(NSSize) size
			 drawingHandler:(AZImageDrawingHandler) drawingHandler
			clearBeforeDraw:(BOOL)clear
	{
	AZImage *img = [AZImage imageWithSize:size];
	if (img)
		{
		img.handler = drawingHandler;
		img.clearBeforeDraw	= clear;
		}
	return img;
	}

/*****************************************************************************\
|* Return image dimensions
\*****************************************************************************/
- (int) width
	{
	return (int) _srcRect.size.width;
	}

- (int) height
	{
	return (int) _srcRect.size.height;
	}
	
/*****************************************************************************\
|* Lock focus on the image, which internally creates the AZPainter that will
|* have this image as its context.
\*****************************************************************************/
- (AZPainter *) lockFocus:(BOOL)clearTexture
	{
	AZPainter *painter = [AZPainter painterForTexture:_texture];
	[painter lockFocus:clearTexture];
	return painter;
	}

/*****************************************************************************\
|* Unlock focus, which restores the old cliprect in the renderer as well
\*****************************************************************************/
- (void) unlockFocusWithPainter:(AZPainter *)painter
	{
	[painter unlockFocus];
	}

/*****************************************************************************\
|* Force a draw of an on-demand image. Optionally clear the texture first
\*****************************************************************************/
- (BOOL) draw
	{
	BOOL drawn = NO;
	if (_handler)
		{
		AZPainter *painter = [self lockFocus:self.clearBeforeDraw];
		drawn = _handler(_srcRect,painter);
		}
	return drawn;
	}

/*****************************************************************************\
|* Save the image to a path. Quality is a factor ranging from 0..9, with 0
|* being the lowest quality (highest artifacts) and 9 being the best quality.
|* Note that time to save may be affected by quality (especially LZ4)
\*****************************************************************************/
- (BOOL) saveAs:(NSString *)fullPath
	   inFormat:(AZImageFormat)format
	withQuality:(int)quality
	{
	BOOL ok 		 = NO;
	const char *path = fullPath.fileSystemRepresentation;

SDL_Log("Start to save texture %d", (int)_texture);
	AZRenderer *azr = AZRenderer.renderer;
	SDL_Surface *surface = [azr surfaceFor:_texture];
	if (surface)
		{
		switch (format)
			{
			case AZImageFormatJPEG:
				ok = IMG_SaveJPG(surface, path, quality*10);
				break;
			case AZImageFormatPNG:
				ok = IMG_SavePNG(surface, path);
				break;
			case AZImageFormatLZ4:
				ok = [self _saveLZ4:surface to:fullPath highQuality:YES];
				break;
			default:
				SDL_Log("Unknown format type %d to save surface as", format);
				break;
			}
		//SDL_Log("Done saving");
		SDL_DestroySurface(surface);
		}
	else
		SDL_Log("Couldn't get a surface for the save operation to %s", path);
	return ok;
	}

// MARK: Private methods

/*****************************************************************************\
|* load an LZ4 image
\*****************************************************************************/
- (SDL_Surface *) _loadLZ4:(NSString *)path
	{
	SDL_Surface *out = nil;
#if 0
	uint32_t magic;
  	uint16_t width;
  	uint16_t height;
  	uint32_t surfaceFormat;
	uint32_t compressedSize;

	SDL_IOStream* src = SDL_IOFromFile (path.fileSystemRepresentation, "rb");
	SDL_ReadIO(src, &magic, sizeof(magic));
	BOOL needsSwap = (magic == 'c4zl');		// swapped "lz4c"

	SDL_ReadIO(src, &width, sizeof(width));
	SDL_ReadIO (src, &height, sizeof(height));
	SDL_ReadIO (src, &surfaceFormat, sizeof(surfaceFormat));
	SDL_ReadIO (src, &compressedSize, sizeof(compressedSize));

	if (needsSwap)
		{
		width 			= SDL_Swap16(width);
		height			= SDL_Swap16(height);
		surfaceFormat	= SDL_Swap32(surfaceFormat);
		compressedSize	= SDL_Swap32(compressedSize);
		}

	out 					= SDL_CreateSurface(width, height, surfaceFormat);
	Uint32 uncompressedSize = out->pitch * height;

	uint8_t * data 			= malloc(compressedSize);
	SDL_ReadIO (src, data, compressedSize);

	uint8_t *buffer 		= (uint8_t*)(out->pixels);
	LZ4_decompress_safe (data, buffer, compressedSize, uncompressedSize);
	SAFELY_FREE(data);
    SDL_closeIO(src);
#endif
	return out;
	}

/*****************************************************************************\
|* Save an LZ4 image
\*****************************************************************************/
- (BOOL) _saveLZ4:(SDL_Surface*)surface to:(NSString *)path highQuality:(BOOL)yn
	{
	BOOL success = NO;
#if 0
	SDL_IOStream* dst = SDL_IOFromFile (path.fileSystemRepresentation, "wb");
	if (dst)
		{
		uint32_t magic 				= 'lz4c';
		uint16_t width				= surface->w;
		uint16_t height				= surface->h;
		uint32_t surfaceFormat		= surface->format;
		uint32_t uncompressedSize	= height * surface->pitch;

		SDL_WriteIO(dst, &magic, sizeof(magic));
		SDL_WriteIO(dst, &width, sizeof(width));
		SDL_WriteIO(dst, &height, sizeof(height));
		SDL_WriteIO(dst, &surfaceFormat, sizeof(surfaceFormat));

		const uint8_t * buffer 	= (const uint8_t*)(surface->pixels);
		int maxSize 			= LZ4_compressBound (uncompressedSize);
		char* data 				= malloc (maxSize);
		uint32_t actualSize 	= 0;

		if (yn)
			actualSize = LZ4_compress_HC(buffer,			// Source data
										 data,				// Resulting data
										 uncompressedSize,	// Size of source
										 maxSize,			// Size of dst
										 LZ4HC_CLEVEL_MAX);	// High compression
		else
			actualSize = LZ4_compress_default(buffer,
											  data,
											  uncompressedSize,
											  maxSize);
		SDL_WriteIO(dst, &actualSize, sizeof(uint32_t));
		SDL_WriteIO(dst, data, actualSize);

		SAFELY_FREE(data);
		SDL_closeIO(dst);
		success = YES;
		}
#endif
	return success;
	}

/*****************************************************************************\
|* Convert the surface to a texture, putting it into an atlas if that's
|* appropriate
\*****************************************************************************/
- (BOOL) _loadSurface:(SDL_Surface *)surface
	{
	BOOL success	= NO;
	AZRenderer *azr	= AZRenderer.renderer;
	int sizes[] 	= {16, 32, 64, 128, 256};
	int numSizes	= sizeof(sizes)/sizeof(sizes[0]);
	BOOL inAtlas	= NO;

	/*************************************************************************\
	|* See if this surface will fit into any of the smaller image-atlas tiles
	|* in turn, from smallest to largest
	\*************************************************************************/
	for (int i=0; i<numSizes && (!inAtlas); i++)
		{
		if ((surface->w <= sizes[i]) && (surface->h <= sizes[i]))
			{
			/*****************************************************************\
			|* It will! So get a cache-object that can represent the texture
			|* we'll use to cache this image
			\*****************************************************************/
			NSString *name = [NSString stringWithFormat:@"%dx%d",
										sizes[i], sizes[i]];
			NSMutableArray<AZImageCache*> *domain = _cache[name];

			/*****************************************************************\
			|* If there are none there, make one and install it
			\*****************************************************************/
			if (domain == nil)
				{
				domain = [NSMutableArray new];
				_cache[name] = domain;
				AZImageCache *ic = [AZImageCache cacheWithWidth:CACHE_WIDTH
														 height:CACHE_HEIGHT
														  size:sizes[i]];
				[domain addObject:ic];
				}

			/*****************************************************************\
			|* Look for an open slot in the caches we have in the list
			\*****************************************************************/
 			AZImageCache *ic 	= nil;
			for (AZImageCache *cache in domain)
				{
				_srcRect = cache.acquire;
				_texRect = _srcRect;
				if (!IS_ZERORECT(_srcRect))
					{
					ic = cache;
					break;
					}
				}

			/*****************************************************************\
			|* If we still don't have an image, create a new image-cache entry
			|* in this domain, and use that
			\*****************************************************************/
			if (ic == nil)
				{
				ic = [AZImageCache cacheWithWidth:CACHE_WIDTH
										   height:CACHE_HEIGHT
										     size:sizes[i]];
				[domain addObject:ic];
				_srcRect = ic.acquire;
				_texRect = _srcRect;
				}

			/*****************************************************************\
			|* Remember which image-cache we used, for later
			\*****************************************************************/
			_imageCache = ic;

			/*****************************************************************\
			|* Ok, so create a texture of the same size as the surface
			\*****************************************************************/
			NSInteger temp = [azr createTextureWithSurface:surface];
			if (temp < 0)
				SDL_Log("Cannot convert surface to texture in AZImage");
			else
				{

				NSInteger currentFocus = azr.currentFocus;
				[azr lockFocusOn:ic.textureId];

				NSRect from = NSMakeRect(0,0,surface->w, surface->h);
				_srcRect.size = from.size;
				[azr blitFrom:temp src:from dst:_srcRect];
				[azr releaseTexture:temp];
				[azr restoreFocus:currentFocus];

				_texture 	= ic.textureId;
				inAtlas 	= YES;
				success 	= YES;
				}
			}
		}

	/*************************************************************************\
	|* If at this point we're not in an atlas, we just allocate a new texture
	|* for the entire image
	\*************************************************************************/
	if (!inAtlas)
		{
		_texture = [azr createTextureWithSurface:surface];
		if (_texture >= 0)
			{
			_srcRect.origin.x 		= 0;
			_srcRect.origin.y 		= 0;
			_srcRect.size.width 	= surface->w;
			_srcRect.size.height	= surface->h;
			success  = YES;
			}
		}

	return success;
	}

@end
