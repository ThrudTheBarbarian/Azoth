//
//  AZTexture.m
//  Azoth
//
//  Created by Simon Gornall on 1/14/25.
//

#import <SDL3/SDL.h>

#import "AZ3dUtils.h"
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
				  format:(SDL_PixelFormat)format
				   usage:(SDL_GPUTextureUsageFlags)flags
	{
	if (self = [super init])
		{
		_size   	= size;
		_flags  	= flags;
		_index 		= index;
		_scaleMode	= SDL_SCALEMODE_NEAREST;

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
		|* Check we support this format
		\*********************************************************************/
		SDL_GPUTextureFormat fmt 	= [AZTexture textureFormatFor:format];
		if (fmt == SDL_GPU_TEXTUREFORMAT_INVALID)
			{
			SDL_Log("Pixel format 0x%x is not supported", format);
			self = nil;
			}

		/*********************************************************************\
		|* Create the GPU texture resource
		\*********************************************************************/
		if (self)
			{
			SDL_GPUTextureCreateInfo info;

			info.type 					= SDL_GPU_TEXTURETYPE_2D;
			info.format					= fmt;
			info.width					= size.width;
			info.height 				= size.height;
			info.layer_count_or_depth	= 1;
			info.num_levels				= 1;
			info.usage					= flags;
			info.sample_count			= SDL_GPU_SAMPLECOUNT_1;

			self.texture = SDL_CreateGPUTexture(_gpu, &info);
			if (self.texture == NULL)
				{
				SDL_Log("Cannot create texture of size %dx%d",
							(int)size.width, (int)size.height);
				self = nil;
				}

			/*****************************************************************\
			|* Fill out the rest of the textureData properties
			\*****************************************************************/
			self.format = fmt;
			BOOL hasAlpha = (format == SDL_PIXELFORMAT_RGBA32)
						  ||(format == SDL_PIXELFORMAT_BGRA32);

			self.shader = (hasAlpha)
						? AZFragShaderTextureRGBA
						: AZFragShaderTextureRGB;
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
				     format:(SDL_PixelFormat)format
					  usage:(SDL_GPUTextureUsageFlags)flags
	{
	return [[AZTexture alloc] initFor:renderer
							withIndex:index
								 size:size
							   format:format
								usage:flags];
	}


/*****************************************************************************\
|* Map from a texture format to a pixel format
\*****************************************************************************/
+ (SDL_PixelFormat) pixelFormatFor:(SDL_GPUTextureFormat)format
	{
    switch (format)
		{
		case SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM:
			return SDL_PIXELFORMAT_RGBA32;
		case SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM:
			return SDL_PIXELFORMAT_BGRA32;
		case SDL_GPU_TEXTUREFORMAT_B5G6R5_UNORM:
			return SDL_PIXELFORMAT_BGR565;
		case SDL_GPU_TEXTUREFORMAT_B5G5R5A1_UNORM:
			return SDL_PIXELFORMAT_BGRA5551;
		case SDL_GPU_TEXTUREFORMAT_B4G4R4A4_UNORM:
			return SDL_PIXELFORMAT_BGRA4444;
		case SDL_GPU_TEXTUREFORMAT_R10G10B10A2_UNORM:
			return SDL_PIXELFORMAT_ABGR2101010;
		case SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UNORM:
			return SDL_PIXELFORMAT_RGBA64;
		case SDL_GPU_TEXTUREFORMAT_R8G8B8A8_SNORM:
			return SDL_PIXELFORMAT_RGBA32;
		case SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT:
			return SDL_PIXELFORMAT_RGBA64_FLOAT;
		case SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT:
			return SDL_PIXELFORMAT_RGBA128_FLOAT;
		case SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UINT:
			return SDL_PIXELFORMAT_RGBA32;
		case SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UINT:
			return SDL_PIXELFORMAT_RGBA64;
		case SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB:
			return SDL_PIXELFORMAT_RGBA32;
		case SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB:
			return SDL_PIXELFORMAT_BGRA32;
		default:
			return SDL_PIXELFORMAT_UNKNOWN;
		}
	}

/*****************************************************************************\
|* Map from a pixel format to a texture format
\*****************************************************************************/
+ (SDL_GPUTextureFormat) textureFormatFor:(SDL_PixelFormat)format
	{
    switch (format)
		{
		case SDL_PIXELFORMAT_BGRA32:
		case SDL_PIXELFORMAT_BGRX32:
			return SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM;

		case SDL_PIXELFORMAT_RGBA32:
		case SDL_PIXELFORMAT_RGBX32:
			return SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;

		default:
			break;
		}
	return SDL_GPU_TEXTUREFORMAT_INVALID;
	}

/*****************************************************************************\
|* Clean up on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	SDL_ReleaseGPUTexture(_gpu, self.texture);
	}


@end
