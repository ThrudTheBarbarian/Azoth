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
    AZ_RENDERLINEMETHOD_POINTS,
    AZ_RENDERLINEMETHOD_LINES,
    AZ_RENDERLINEMETHOD_GEOMETRY,
	} AZRenderLineMethod;

NS_ASSUME_NONNULL_BEGIN

@class AZColour;

/*****************************************************************************\
|* Determine if we support a blend factor or not
\*****************************************************************************/
static SDL_INLINE SDL_GPUBlendFactor GPU_ConvertBlendFactor(SDL_BlendFactor factor)
	{
    switch (factor)
		{
		case SDL_BLENDFACTOR_ZERO:
			return SDL_GPU_BLENDFACTOR_ZERO;
		case SDL_BLENDFACTOR_ONE:
			return SDL_GPU_BLENDFACTOR_ONE;
		case SDL_BLENDFACTOR_SRC_COLOR:
			return SDL_GPU_BLENDFACTOR_SRC_COLOR;
		case SDL_BLENDFACTOR_ONE_MINUS_SRC_COLOR:
			return SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_COLOR;
		case SDL_BLENDFACTOR_SRC_ALPHA:
			return SDL_GPU_BLENDFACTOR_SRC_ALPHA;
		case SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA:
			return SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
		case SDL_BLENDFACTOR_DST_COLOR:
			return SDL_GPU_BLENDFACTOR_DST_COLOR;
		case SDL_BLENDFACTOR_ONE_MINUS_DST_COLOR:
			return SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_COLOR;
		case SDL_BLENDFACTOR_DST_ALPHA:
			return SDL_GPU_BLENDFACTOR_DST_ALPHA;
		case SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA:
			return SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_ALPHA;
		default:
			return SDL_GPU_BLENDFACTOR_INVALID;
		}
	}

static SDL_INLINE SDL_GPUBlendOp GPU_ConvertBlendOperation(SDL_BlendOperation op)
	{
	switch (op)
		{
		case SDL_BLENDOPERATION_ADD:
			return SDL_GPU_BLENDOP_ADD;
		case SDL_BLENDOPERATION_SUBTRACT:
			return SDL_GPU_BLENDOP_SUBTRACT;
		case SDL_BLENDOPERATION_REV_SUBTRACT:
			return SDL_GPU_BLENDOP_REVERSE_SUBTRACT;
		case SDL_BLENDOPERATION_MINIMUM:
			return SDL_GPU_BLENDOP_MIN;
		case SDL_BLENDOPERATION_MAXIMUM:
			return SDL_GPU_BLENDOP_MAX;
		default:
			return SDL_GPU_BLENDOP_INVALID;
		}
	}


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
