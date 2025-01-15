//
//  AZRenderPipeline.m
//  sdl3_gpu
//
//  Created by Simon Gornall on 1/13/25.
//

#import <SDL3/SDL.h>

#import "AZPipelineTarget.h"
#import "AZRenderPipeline.h"
#import "AZShader.h"
#import "AZVertexInputState.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZRenderPipeline()

// The GPU device we were created with
@property(assign, nonatomic) SDL_GPUDevice *						gpu;
@end

@implementation AZRenderPipeline

/*****************************************************************************\
|* Tidy up on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	if (_gpu && _pipeline)
		SDL_ReleaseGPUGraphicsPipeline(_gpu, _pipeline);
	}

/*****************************************************************************\
|* Build the render pipeline
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
	if (_pipeline)
		SDL_ReleaseGPUGraphicsPipeline(_gpu, _pipeline);

	/*************************************************************************\
	|* Create the pipeline using the description info
	\*************************************************************************/
	SDL_GPUGraphicsPipelineCreateInfo info;
	memset(&info, 0, sizeof(info));

	info.vertex_shader 		= _vertex.shader;
	info.fragment_shader	= _fragment.shader;
	info.vertex_input_state	= _vertexInputState.state;
	info.primitive_type		= _primitiveType;
	info.target_info		= _pipelineTarget.info;

	_pipeline = SDL_CreateGPUGraphicsPipeline(_gpu, &info);

	return (_pipeline != NULL);
	}

@end
