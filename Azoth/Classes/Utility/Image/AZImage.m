//
//  AZImage.m
//  Azoth
//
//  Created by Simon Gornall on 12/28/24.
//

#import <SDL3/SDL.h>
#import <SDL3_image/SDL_image.h>

#import "AZImage.h"
#import "AZImageCache.h"
#import "AZRenderer.h"

#define CACHE_WIDTH			1024
#define CACHE_HEIGHT		1024

/*****************************************************************************\
|* "Private" properties for the class
\*****************************************************************************/
@interface AZImage()

// The texture-id that the Renderer owns
@property(assign, nonatomic) NSInteger								texture;

// The location within the texture that defines this image
@property(assign, nonatomic) NSRect									srcRect;
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
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken,
			^{
			_cache = [NSMutableDictionary new];
			});
		}
	return self;
	}

/*****************************************************************************\
|* Initialisation: Load an image from the current bundle's Resources/ directory
\*****************************************************************************/
+ (AZImage *) imageNamed:(NSString *)name
	{
	NSString *rsrc 		= [[NSBundle mainBundle] resourcePath];
	NSString *fullpath 	= [NSString stringWithFormat:@"%@/%@", rsrc, name];
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

// MARK: Private methods

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
			AZImageCache *ic = nil;

			/*****************************************************************\
			|* If there are none there, make one and install it, otherwise use
			|* the last one we installed
			\*****************************************************************/
			if (domain == nil)
				{
				domain = [NSMutableArray new];
				_cache[name] = domain;
				ic = [AZImageCache cacheWithWidth:CACHE_WIDTH
										   height:CACHE_HEIGHT
										     size:sizes[i]];
				[domain addObject:ic];
				}
			else
				ic = [domain lastObject];

			/*****************************************************************\
			|* Check to see if this one has any remaining slots in its cache,
			|* if not, create a new one and append it
			\*****************************************************************/
			if (ic.remainingSlots == 0)
				{
				ic = [AZImageCache cacheWithWidth:CACHE_WIDTH
										   height:CACHE_HEIGHT
										     size:sizes[i]];
				[domain addObject:ic];
				}
	
			/*****************************************************************\
			|* Get the X,Y (w,h come from the texture) of where to upload it to
			\*****************************************************************/
			_srcRect.origin.x 		= ic.nextX;
			_srcRect.origin.y 		= ic.nextY;
			_srcRect.size.width 	= surface->w;
			_srcRect.size.height	= surface->h;

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

				[azr blitFrom:temp src:NSZeroRect dst:_srcRect];
				[azr releaseTexture:temp];

				[ic bumpToNextSlot];
				inAtlas = YES;
				[azr restoreFocus:currentFocus];
				success = YES;
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
