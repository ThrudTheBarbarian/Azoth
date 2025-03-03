//
//  AZTexture.m
//  Azoth
//
//  Created by Simon Gornall on 1/14/25.
//

#import <SDL3/SDL.h>

#import "AZ3dUtils.h"
#import "AZRenderer.h"
#import "AZRenderProperties.h"
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
		_size   				= size;
		_flags  				= flags;
		_index 					= index;
		_use 					= 1;
		_view.pixelW 			= (int)size.width;
		_view.pixelH			= (int)size.height;
		_view.view.size.width	= -1;
		_view.view.size.height 	= -1;
		_view.scale.x			= 1.f;
		_view.scale.y			= 1.f;
		_view.logicalScale.x	= 1.f;
		_view.logicalScale.y	= 1.f;
		_view.currentScale.x	= 1.f;
		_view.currentScale.y	= 1.f;

		_colour.r				= 1.f;
		_colour.g				= 1.f;
		_colour.b				= 1.f;
		_colour.a				= 1.f;

		_blendMode				= SDL_ISPIXELFORMAT_ALPHA(format)
								? SDL_BLENDMODE_BLEND
								: SDL_BLENDMODE_NONE;
		_scaleMode				= SDL_SCALEMODE_LINEAR;

		_colourspace	 		= AZGetDefaultColorspaceForFormat(format);
		NSDictionary *info 	 	= renderer.properties;
		NSNumber *forcingCS		= info[AZRendererTextureColourspace];
		if (forcingCS)
			_colourspace 		= (SDL_Colorspace)forcingCS.integerValue;

		_sdrWhitePoint			= AZGetSurfaceSDRWhitePoint(_colourspace);
		NSNumber *forcingWP		= info[AZRendererTextureWhitepoint];
		if (forcingWP)
			_sdrWhitePoint		= forcingWP.floatValue;

		_hdrHeadroom			= AZGetSurfaceHDRHeadroom(_colourspace);
		NSNumber *forcingHR		= info[AZRendererTextureHeadroom];
		if (forcingHR)
			_hdrHeadroom		= forcingHR.floatValue;

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
		_format = fmt;

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


/*****************************************************************************\
|* Return a pointer to the local texture's view-state. This is the renderer's
|* view of the texture
\*****************************************************************************/
- (AZViewState *) view
	{
	return &_view;
	}

/*****************************************************************************\
|* Set the texture name 
\*****************************************************************************/
- (void) setName:(NSString *)name
	{
	_name = name;
	SDL_SetGPUTextureName(_gpu, self.texture, name.UTF8String);
	}

- (NSString *) description
	{
	return [NSString stringWithFormat:
			@"[AZTexture %p  name:%@ size:%@ flags:0x%02x index:%@]",
			self, _name, NSStringFromSize(_size), _flags, _index];
	}
@end
