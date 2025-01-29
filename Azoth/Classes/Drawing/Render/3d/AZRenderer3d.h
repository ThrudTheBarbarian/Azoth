//
//  AZRenderer3d.h
//  Azoth
//
//  Created by Simon Gornall on 1/13/25.
//

#import <SDL3/SDL.h>

#import <Foundation/Foundation.h>
#import <Azoth/AZRenderer.h>
#import <Azoth/AZTypes.h>

typedef enum
	{
    AZRenderLineMethodPoints = 1,
    AZRenderLineMethodLines,
    AZRenderLineMethodGeometry,
	} AZRenderLineMethod;

NS_ASSUME_NONNULL_BEGIN

@class AZColour;
@class AZComputePipeline;

@interface AZRenderer3d : NSObject <AZRenderer>

/*****************************************************************************\
|* Return the 3D renderer
\*****************************************************************************/
+ (AZRenderer3d *) renderer;


/*****************************************************************************\
|* Blend operation/factor extraction
\*****************************************************************************/
- (SDL_BlendFactor) blendModeSrcColourFactor:(SDL_BlendMode)blendMode;
- (SDL_BlendFactor) blendModeDstColourFactor:(SDL_BlendMode)blendMode;
- (SDL_BlendOperation) blendModeColourOperation:(SDL_BlendMode)blendMode;
- (SDL_BlendFactor) blendModeSrcAlphaFactor:(SDL_BlendMode)blendMode;
- (SDL_BlendFactor) blendModeDstAlphaFactor:(SDL_BlendMode)blendMode;
- (SDL_BlendOperation) blendModeAlphaOperation:(SDL_BlendMode)blendMode;

/*****************************************************************************\
|* Run a compute pipeline
\*****************************************************************************/
- (BOOL) dispatchComputePipeline:(AZComputePipeline *)pipeline
				 withUniformData:(void *)data
						ofLength:(uint32_t)length;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Returns the swapchain texture format for this
// GPU and window combination
@property(assign, nonatomic,readonly)
SDL_GPUTextureFormat 										swapchainFormat;

// The colour used to clear textures with
@property(strong, nonatomic) AZColour *						clearColour;

// The current draw colour
@property(strong, nonatomic) AZColour *						colour;

// Different ways to render lines
@property(assign, nonatomic) AZRenderLineMethod				lineMethod;

// The colourspace used for screen display
@property(assign, nonatomic) SDL_Colorspace					outputColourspace;
@end

NS_ASSUME_NONNULL_END
