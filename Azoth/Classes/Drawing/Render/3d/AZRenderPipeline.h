//
//  AZRenderPipeline.h
//  sdl3_gpu
//
//  Created by Simon Gornall on 1/13/25.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>
#import <Azoth/AZ3dUtils.h>

NS_ASSUME_NONNULL_BEGIN

@class AZPipelineTarget;
@class AZShader;
@class AZVertexInputState;

@protocol AZRenderer;

typedef struct AZPipelineParameters
	{
    SDL_BlendMode 			blendMode;
    AZFragmentShaderID 		fragShader;
    AZVertexShaderID 		vertShader;
    SDL_GPUTextureFormat 	attachmentFormat;
    SDL_GPUPrimitiveType 	primitiveType;
	} AZPipelineParameters;


@interface AZRenderPipeline : NSObject

/*****************************************************************************\
|* Create a render pipeline
\*****************************************************************************/
+ (nullable AZRenderPipeline *) withRenderer:(id<AZRenderer>)renderer
									 shaders:(AZShaders *)shaders
									  params:(AZPipelineParameters *)params;

/*****************************************************************************\
|* Build the render pipeline
\*****************************************************************************/
- (BOOL) buildWithDevice:(id<AZRenderer>)renderer;

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

// The format of the texture data
@property(assign, nonatomic) SDL_GPUTextureFormat			attachmentFormat;

// The multisampling state
@property(assign, nonatomic) SDL_GPUMultisampleState		multisample;

// The rasteriser state
@property(assign, nonatomic) SDL_GPURasterizerState			rasteriser;

// The actual pipeline that SDL uses
@property(assign, nonatomic, readonly)
SDL_GPUGraphicsPipeline *									pipeline;
@end

NS_ASSUME_NONNULL_END
