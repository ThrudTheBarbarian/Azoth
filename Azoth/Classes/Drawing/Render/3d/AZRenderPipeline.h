//
//  AZRenderPipeline.h
//  sdl3_gpu
//
//  Created by Simon Gornall on 1/13/25.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

NS_ASSUME_NONNULL_BEGIN

@class AZPipelineTarget;
@class AZShader;
@class AZVertexInputState;

@interface AZRenderPipeline : NSObject

/*****************************************************************************\
|* Build the render pipeline
\*****************************************************************************/
- (BOOL) buildWithDevice:(SDL_GPUDevice *)gpu;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The vertex input state
@property(strong, nonatomic) AZVertexInputState *			vertexInputState;

// The pipeline targets (colour/stencil)
@property(strong, nonatomic) AZPipelineTarget *				pipelineTarget;

// The fragment shader, if there is one
@property(strong, nonatomic, nullable) AZShader *			fragment;

// The vertex shader, if there is one
@property(strong, nonatomic, nullable) AZShader *			vertex;

// The primitive type used in the pipeline.
@property(assign, nonatomic) SDL_GPUPrimitiveType			primitiveType;

// The actual pipeline that SDL uses
@property(assign, nonatomic, readonly)
SDL_GPUGraphicsPipeline *									pipeline;
@end

NS_ASSUME_NONNULL_END
