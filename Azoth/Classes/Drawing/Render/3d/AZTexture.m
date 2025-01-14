//
//  AZTexture.m
//  Azoth
//
//  Created by Simon Gornall on 1/14/25.
//

#import <SDL3/SDL.h>

#import "AZRenderer.h"
#import "AZTexture.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZTexture()

// The GPU device we were created with
@property(assign, nonatomic) SDL_GPUDevice *						gpu;
@end

@implementation AZTexture

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initFor:(id<AZRenderer>)renderer
			   withIndex:(NSNumber *)index
				    size:(NSSize)size
				   usage:(SDL_GPUTextureUsageFlags)flags
	{
	if (self = [super init])
		{
		_size   = size;
		_flags  = flags;
		_index 	= index;

		/*********************************************************************\
		|* Get the GPU device from the renderer
		\*********************************************************************/
		_gpu = renderer.gpu;
		if (_gpu == NULL)
			{
			SDL_Log("GPU device is not registered");
			self = nil;
			}

		/*********************************************************************\
		|* Create the GPU texture resource
		\*********************************************************************/
		if (self)
			{
			SDL_GPUTextureCreateInfo info;

			info.type 					= SDL_GPU_TEXTURETYPE_2D;
			info.format					= SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
			info.width					= size.width;
			info.height 				= size.height;
			info.layer_count_or_depth	= 1;
			info.num_levels				= 1;
			info.usage					= flags;
			info.sample_count			= SDL_GPU_SAMPLECOUNT_1;

			_texture = SDL_CreateGPUTexture(_gpu, &info);
			if (_texture == NULL)
				{
				SDL_Log("Cannot create texture of size %dx%d",
							(int)size.width, (int)size.height);
				self = nil;
				}
			}
		}

	return self;
	}

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (instancetype) textureFor:(id<AZRenderer>)renderer
				  withIndex:(NSNumber *)index
					   size:(NSSize)size
					  usage:(SDL_GPUTextureUsageFlags)flags
	{
	return [[AZTexture alloc] initFor:renderer
							withIndex:index
								 size:size
								usage:flags];
	}

/*****************************************************************************\
|* Clean up on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	SDL_ReleaseGPUTexture(_gpu, _texture);
	}


@end
