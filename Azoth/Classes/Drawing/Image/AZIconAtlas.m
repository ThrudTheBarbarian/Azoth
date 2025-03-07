//
//  AZIconAtlas.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/28/24.
//

#import <SDL3/SDL.h>
#import <SDL3_image/SDL_image.h>

#import "AZIconAtlas.h"
#import "AZRenderer.h"

@implementation AZIconAtlas
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithTexture:(NSInteger)texture metadata:(NSDictionary *)map
	{
	if (self = [super init])
		{
		_texture 	= texture;
		_metadata	= map;
		}
	return self;
	}

+ (AZIconAtlas *) atlasWithTexture:(NSInteger)texture metadata:(NSDictionary *)map
	{
	return [[AZIconAtlas alloc] initWithTexture:texture metadata:map];
	}

+ (AZIconAtlas *) atlasWithName:(NSString *)name
	{
	AZIconAtlas *atlas = [AZIconAtlas new];
	if ([atlas load:name] != SDL_APP_CONTINUE)
		return nil;
	return atlas;
	}


/*****************************************************************************\
|* Load a map of icons/images with an accompanying plist to identify the name
|* and location/size of each image in the map. Atlas files are expected to be
|* in the resources directory
\*****************************************************************************/
- (NSInteger) load:(NSString *)name
	{
	NSInteger result	= SDL_APP_CONTINUE;
	id<AZRenderer> azr 	= AZRenderer.renderer;

	NSString *rsrc = [[NSBundle bundleForClass:[self class]] resourcePath];
	NSString *path = [NSString stringWithFormat:@"%@/Atlas/%@.png", rsrc, name];
	SDL_Surface *atlasSurface = IMG_Load(path.fileSystemRepresentation);
	if (!atlasSurface)
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					  "Failed to load icon atlas at %s!",
					  path.fileSystemRepresentation);
        result = SDL_APP_FAILURE;
		}
	else
		{
		_texture = [azr createTextureWithSurface:atlasSurface];
		if (_texture < 0)
			{
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
						  "Failed to create icon atlas (though it loaded)!");
			result =  SDL_APP_FAILURE;
			}

		SDL_DestroySurface(atlasSurface);
		path 		= [NSString stringWithFormat:@"%@/Atlas/%@.plist", rsrc, name];
		_metadata  	= [NSDictionary dictionaryWithContentsOfFile:path];
		if (!_metadata)
			{
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
						  "Failed to load UI atlas metadata at %s!",
						  path.fileSystemRepresentation);
			result =  SDL_APP_FAILURE;
			}
		}
	return result;
	}

@end
