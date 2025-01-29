//
//  AZSampler.h
//  Azoth
//
//  Created by Simon Gornall on 1/14/25.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AZRenderer;

@interface AZSampler : NSObject
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithMinFilter:(SDL_GPUFilter)min
						 magFilter:(SDL_GPUFilter)mag
						mipMapMode:(SDL_GPUSamplerMipmapMode)mipMapMode
					  addressModeU:(SDL_GPUSamplerAddressMode)addressU
					  addressModeV:(SDL_GPUSamplerAddressMode)addressV
					  addressModeW:(SDL_GPUSamplerAddressMode)addressW;

+ (instancetype) withMinFilter:(SDL_GPUFilter)min
			 	     magFilter:(SDL_GPUFilter)mag
			 	    mipMapMode:(SDL_GPUSamplerMipmapMode)mipMapMode
			       addressMode:(SDL_GPUSamplerAddressMode)addressMode;

+ (instancetype) withMinFilter:(SDL_GPUFilter)min
			 	     magFilter:(SDL_GPUFilter)mag
			 	    mipMapMode:(SDL_GPUSamplerMipmapMode)mipMapMode
			      addressModeU:(SDL_GPUSamplerAddressMode)addressU
			      addressModeV:(SDL_GPUSamplerAddressMode)addressV
			      addressModeW:(SDL_GPUSamplerAddressMode)addressW;


/*****************************************************************************\
|* build a sampler
\*****************************************************************************/
- (BOOL) buildWithRenderer:(id<AZRenderer>)renderer;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The minification filter to apply to lookups
@property(assign, nonatomic) SDL_GPUFilter  					minFilter;

// The magnification filter to apply to lookups
@property(assign, nonatomic) SDL_GPUFilter  					magFilter;

// The mipmap filter to apply to lookups
@property(assign, nonatomic) SDL_GPUSamplerMipmapMode  			mipMapMode;

// The addressing mode for U coordinates outside [0, 1)
@property(assign, nonatomic) SDL_GPUSamplerAddressMode  		addressU;

// The addressing mode for V coordinates outside [0, 1)
@property(assign, nonatomic) SDL_GPUSamplerAddressMode  		addressV;

// The addressing mode for W coordinates outside [0, 1)
@property(assign, nonatomic) SDL_GPUSamplerAddressMode  		addressW;

// The bias to be added to mipmap LOD calculation
@property(assign, nonatomic) float	  							lodBias;

// Clamps the minimum of the computed LOD value
@property(assign, nonatomic) float	  							minLod;

// Clamps the maximum of the computed LOD value
@property(assign, nonatomic) float	  							maxLod;

// The anisotropy value clamp used by the sampler.
// If enableAnisotropy is false, this is ignored
@property(assign, nonatomic) float	  							maxAnisotropy;

// true to enable anisotropic filtering
@property(assign, nonatomic) BOOL	  							enableAnisotropy;

// The comparison operator to apply to fetched data
// before filtering
@property(assign, nonatomic) SDL_GPUCompareOp	  				compareOp;

// true to enable comparison against a reference
// value during lookups
@property(assign, nonatomic) BOOL	  							enableCompare;

// A properties ID for extensions. Should be 0
// if no extensions are needed
@property(assign, nonatomic) SDL_PropertiesID	  				props;

// The actual sampler
@property(assign, nonatomic) SDL_GPUSampler *					sampler;


@end

NS_ASSUME_NONNULL_END
