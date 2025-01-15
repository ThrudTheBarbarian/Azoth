//
//  AZSampler.m
//  Azoth
//
//  Created by Simon Gornall on 1/14/25.
//

#import "AZRenderer.h"
#import "AZSampler.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZSampler()

// The GPU device we were created with
@property(assign, nonatomic) SDL_GPUDevice *						gpu;
@end

@implementation AZSampler
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithMinFilter:(SDL_GPUFilter)min
						 magFilter:(SDL_GPUFilter)mag
						mipMapMode:(SDL_GPUSamplerMipmapMode)mipMapMode
					  addressModeU:(SDL_GPUSamplerAddressMode)addressU
					  addressModeV:(SDL_GPUSamplerAddressMode)addressV
					  addressModeW:(SDL_GPUSamplerAddressMode)addressW
	{
	if (self = [super init])
		{
		_minFilter 		= min;
		_magFilter 		= mag;
		_mipMapMode		= mipMapMode;
		_addressU		= addressU;
		_addressV		= addressV;
		_addressW		= addressW;
		}
	return self;
	}

+ (instancetype) withMinFilter:(SDL_GPUFilter)min
			 	     magFilter:(SDL_GPUFilter)mag
			 	    mipMapMode:(SDL_GPUSamplerMipmapMode)mipMapMode
			      addressModeU:(SDL_GPUSamplerAddressMode)addressU
			      addressModeV:(SDL_GPUSamplerAddressMode)addressV
			      addressModeW:(SDL_GPUSamplerAddressMode)addressW
	{
	return [[AZSampler alloc] initWithMinFilter:min
									  magFilter:mag
									 mipMapMode:mipMapMode
								   addressModeU:addressU
								   addressModeV:addressV
								   addressModeW:addressW];
	}


/*****************************************************************************\
|* Tidy up on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	if (_gpu && _sampler)
		SDL_ReleaseGPUSampler(_gpu, _sampler);
	}

/*****************************************************************************\
|* build a sampler
\*****************************************************************************/
- (BOOL) buildWithDevice:(id<AZRenderer>)renderer
	{

	/*************************************************************************\
	|* Get the GPU device from the renderer
	\*************************************************************************/
	_gpu = renderer.gpu;
	if (_gpu == NULL)
		{
		SDL_Log("GPU device is not registered when trying to create sampler");
		return NO;
		}

	/*************************************************************************\
	|* If we already have one, release it
	\*************************************************************************/
	if (_sampler)
		SDL_ReleaseGPUSampler(_gpu, _sampler);

	/*************************************************************************\
	|* Create the sampler using the description info
	\*************************************************************************/
	SDL_GPUSamplerCreateInfo info;

	info.min_filter			= _minFilter;
	info.mag_filter			= _magFilter;
	info.mipmap_mode		= _mipMapMode;
	info.address_mode_u		= _addressU;
	info.address_mode_v		= _addressV;
	info.address_mode_w		= _addressW;
	info.mip_lod_bias		= _lodBias;
	info.max_anisotropy		= _maxAnisotropy;
	info.compare_op			= _compareOp;
	info.min_lod			= _minLod;
	info.max_lod			= _maxLod;
	info.enable_anisotropy	= _enableAnisotropy;
	info.enable_compare		= _enableCompare;
	info.props				= _props;

	_sampler = SDL_CreateGPUSampler(_gpu, &info);

	return (_sampler != NULL);
	}

@end
