//
//  AZTexture.h
//  Azoth
//
//  Created by Simon Gornall on 1/14/25.
//
// Only support BGRA8888

#import <Azoth/AZ3dUtils.h>
#import <Azoth/AZTypes.h>
#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>
#import <SDL3/SDL_gpu.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AZRenderer;

@interface AZTexture : NSObject
	{
	AZViewState _view;
	}

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initFor:(id<AZRenderer>)renderer
			   withIndex:(NSNumber *)index
				    size:(NSSize)size
				  format:(SDL_PixelFormat)format
				   usage:(SDL_GPUTextureUsageFlags)flags;

+ (instancetype) textureFor:(id<AZRenderer>)renderer
				  withIndex:(NSNumber *)index
					   size:(NSSize)size
				     format:(SDL_PixelFormat)format
					  usage:(SDL_GPUTextureUsageFlags)flags;


/*****************************************************************************\
|* Map from a texture format to a pixel format
\*****************************************************************************/
+ (SDL_PixelFormat) pixelFormatFor:(SDL_GPUTextureFormat)format;

/*****************************************************************************\
|* Map from a pixel format to a texture format
\*****************************************************************************/
+ (SDL_GPUTextureFormat) textureFormatFor:(SDL_PixelFormat)format;

/*****************************************************************************\
|* Return a pointer to the local texture's view-state. This is the renderer's
|* view of the texture
\*****************************************************************************/
- (AZViewState *) view;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Size of the texture
@property(assign, nonatomic, readonly) NSSize					size;

// Flags for the texture
@property(assign, nonatomic, readonly) SDL_GPUTextureUsageFlags	flags;

// Index for this texture in pool
@property(strong, nonatomic, readonly) NSNumber *				index;

// The colour associated with this texture
// (the 'mod' colour)
@property(assign, nonatomic) SDL_FColor 						colour;

// The blend-mode for this texture
@property(assign, nonatomic) SDL_BlendMode 						blendMode;

// The colourspace for the texture
@property(assign, nonatomic) SDL_Colorspace						colourspace;

// The white point for this texture
@property(assign, nonatomic) float								sdrWhitePoint;

// The HDR headroom for this texture
@property(assign, nonatomic) float								hdrHeadroom;

// How to scale this texture
@property(assign, nonatomic) SDL_ScaleMode						scaleMode;


// The texture itself
@property(assign, nonatomic) SDL_GPUTexture *					texture;

// The texture format
@property(assign, nonatomic) SDL_GPUTextureFormat 				format;

// Which kind of fragment shader
@property(assign, nonatomic) AZFragmentShaderID 				shader;

// Last command generation that we used this texture
@property(assign, nonatomic) NSInteger		 					lastCommandGen;

// Last command generation that we used this texture
@property(strong, nonatomic) NSMutableDictionary *		 		properties;

// Number of retains this texture has, only released
// when the count goes to 0
@property(assign, nonatomic) NSInteger		 					use;
@end

NS_ASSUME_NONNULL_END
