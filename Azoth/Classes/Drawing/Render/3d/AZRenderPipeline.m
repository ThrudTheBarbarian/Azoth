//
//  AZRenderPipeline.m
//  sdl3_gpu
//
//  Created by Simon Gornall on 1/13/25.
//

#import "AZPipelineTarget.h"
#import "AZRenderPipeline.h"
#import "AZShader.h"
#import "AZVertexInputState.h"

@implementation AZRenderPipeline

/*****************************************************************************\
|* Build the render pipeline
\*****************************************************************************/
- (BOOL) buildWithDevice:(SDL_GPUDevice *)gpu
	{
	SDL_GPUGraphicsPipelineCreateInfo info;
	memset(&info, 0, sizeof(info));

	info.vertex_shader 		= _vertex.shader;
	info.fragment_shader	= _fragment.shader;
	info.vertex_input_state	= _vertexInputState.state;
	info.primitive_type		= _primitiveType;
	info.target_info		= _pipelineTarget.info;

	_pipeline = SDL_CreateGPUGraphicsPipeline(gpu, &info);

	return (_pipeline != NULL);
	}

@end
