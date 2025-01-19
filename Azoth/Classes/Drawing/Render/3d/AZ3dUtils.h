//
//  AZ3dUtils.h
//  Azoth
//
//  Created by Simon Gornall on 1/14/25.
//

#ifndef AZ3dUtils_h
#define AZ3dUtils_h

#import <Azoth/AZTypes.h>
#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

@class AZShader;
	
/*****************************************************************************\
|* Shader utilities
\*****************************************************************************/

typedef enum
	{
    AZVertShaderInvalid = -1,
    AZVertShaderLinePoint,
    AZVertShaderTriColour,
    AZVertShaderTriTexture,

    AZNumVertShaders,
	} AZVertexShaderID;

typedef enum
	{
    AZFragShaderInvalid = -1,
    AZFragShaderColour,
    AZFragShaderTextureRGB,
    AZFragShaderTextureRGBA,

    AZNumFragShaders,
	} AZFragmentShaderID;

struct AZShaders
	{
    AZShader *vertShaders[AZNumVertShaders];
    AZShader *fragShaders[AZNumFragShaders];
	};

typedef struct AZShaders AZShaders;

// Fetch a vertex shader with sanity tests
AZShader * AZVertexShader(AZShaders *shaders, AZVertexShaderID which);

// Fetch a fragment shader with sanity tests
AZShader * AZFragmentShader(AZShaders *shaders, AZFragmentShaderID which);


/*****************************************************************************\
|* Determine if we support a blend factor or not
\*****************************************************************************/
static SDL_INLINE SDL_GPUBlendFactor AZConvertBlendFactor(SDL_BlendFactor factor)
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

static SDL_INLINE SDL_GPUBlendOp AZConvertBlendOperation(SDL_BlendOperation op)
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



/*****************************************************************************\
|* Here we define references to some external symbols that aren't usually
|* exposed outside of the SDL framework itself
\*****************************************************************************/

// Set the swapchain parameters
extern BOOL SDL_SetGPUSwapchainParameters
	(
    SDL_GPUDevice *device,
    SDL_Window *window,
    SDL_GPUSwapchainComposition swapchain_composition,
    SDL_GPUPresentMode present_mode
    );

// How many frames are allowed to be in-flight
extern BOOL SDL_SetGPUAllowedFramesInFlight
	(
    SDL_GPUDevice *device,
    Uint32 allowed_frames_in_flight
    );


/*****************************************************************************\
|* These are (seemingly) private code within the SDL framework. The code is
|* directly pulled, and renamed AZ... for SDL_...
\*****************************************************************************/
SDL_Colorspace AZGetDefaultColorspaceForFormat(SDL_PixelFormat format);
float AZGetSurfaceSDRWhitePoint(SDL_Colorspace cs);
float AZGetSurfaceHDRHeadroom(SDL_Colorspace cs);

#endif /* AZ3dUtils_h */
