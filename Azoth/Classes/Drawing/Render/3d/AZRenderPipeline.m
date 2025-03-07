//
//  AZRenderPipeline.m
//  sdl3_gpu
//
//  Created by ThrudTheBarbarian on 1/13/25.
//

#import <SDL3/SDL.h>

#import "AZColourTarget.h"
#import "AZPipelineTarget.h"
#import "AZRenderer3d.h"
#import "AZRenderPipeline.h"
#import "AZShader.h"
#import "AZVertexAttribute.h"
#import "AZVertexBuffer.h"
#import "AZVertexInputState.h"

#define BLEND(x) AZConvertBlendOperation(x)

struct AZPipelineCacheKeyStruct
	{
    Uint64 blendMode 			: 28;
    Uint64 fragShader 			: 4;
    Uint64 vertShader 			: 4;
    Uint64 attachmentFormat 	: 6;
    Uint64 primitiveType 		: 3;
	};

typedef union AZPipelineCacheKey
	{
    struct AZPipelineCacheKeyStruct asStruct;
    Uint64 asUint64;
	} AZPipelineCacheKey;


/*****************************************************************************\
|* File-static data
\*****************************************************************************/
static NSMutableDictionary<NSNumber *, AZRenderPipeline *> * _pipelineCache;


/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZRenderPipeline()

// The GPU device we were created with
@property(assign, nonatomic) SDL_GPUDevice *						gpu;

// The key we're indexed with in the pipeline cache
@property(assign, nonatomic) AZPipelineCacheKey 					key;
@end

@implementation AZRenderPipeline


/*****************************************************************************\
|* Initialise
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		// Set defaults to:
    	//   sample_count	: SDL_GPU_SAMPLECOUNT_1
    	//   sample_mask	: 0
    	//   enable_mask	: NO
		SDL_zero(_multisample);

		// Set defaults to:
		//   fill_mode					: SDL_GPU_FILLMODE_FILL
		//   cull_mode					: SDL_GPU_CULLMODE_NONE
		//   front_face					: SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE
		//   depth_bias_constant_factor	: 0
		//   depth_bias_clamp			: 0
		//   depth_bias_slope_factor	: 0
		//   enable_depth_bias			: NO
		//   enable_depth_clip			; NO
		SDL_zero(_rasteriser);
		}

	return self;
	}

/*****************************************************************************\
|* Create a cache-key from a set of params
\*****************************************************************************/
+ (NSNumber *) makeCacheKey:(AZPipelineParameters *)params
	{
    AZPipelineCacheKey key;
    SDL_zero(key);
    key.asStruct.blendMode 			= params->blendMode;
    key.asStruct.fragShader 		= params->fragShader;
    key.asStruct.vertShader 		= params->vertShader;
    key.asStruct.attachmentFormat 	= params->attachmentFormat;
    key.asStruct.primitiveType 		= params->primitiveType;

	return [NSNumber numberWithUnsignedInteger:key.asUint64];
	}

/*****************************************************************************\
|* Fetch (from cache) or create a render pipeline
\*****************************************************************************/
+ (nullable AZRenderPipeline *) withRenderer:(id<AZRenderer>)azr
									 shaders:(AZShaders *)shaders
									  params:(AZPipelineParameters *)p
	{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		_pipelineCache = NSMutableDictionary.new;
		});

	NSNumber *key 			= [self makeCacheKey:p];
	AZRenderPipeline *pipe	= _pipelineCache[key];
	if (pipe == nil)
		{
		pipe = [self makeWithRenderer:azr shaders:shaders params:p];
		if (pipe != nil)
			_pipelineCache[key] = pipe;
		}
	return pipe;
	}

/*****************************************************************************\
|* Make a render pipeline
\*****************************************************************************/
+ (nullable AZRenderPipeline *) makeWithRenderer:(id<AZRenderer>)azr
										 shaders:(AZShaders *)shaders
										  params:(AZPipelineParameters *)params
	{
	AZRenderPipeline *pipe 		= AZRenderPipeline.new;
	AZPipelineTarget *pt		= AZPipelineTarget.new;
	pt.hasDepthStencilTarget	= NO;

	AZColourTarget *ct 			= AZColourTarget.new;
	ct.format 					= params->attachmentFormat;
	[ct updataBlendStateWith:azr andBlendMode:params->blendMode];
	[pt addColourTarget:ct];

	pipe.vertex 			= AZVertexShader(shaders, params->vertShader);
	pipe.fragment			= AZFragmentShader(shaders, params->fragShader);
	pipe.primitiveType		= params->primitiveType;
	pipe.pipelineTarget		= pt;

	AZVertexInputState *vis = AZVertexInputState.new;
	pipe.vertexInputState	= vis;
	AZVertexAttribute *va 	= nil;
	AZVertexBuffer *vb		= nil;

	/*************************************************************************\
	|* Figure out what attributes we need
	\*************************************************************************/
	bool haveAttrColour		= NO;
    bool haveAttrUV 		= NO;

    switch (params->vertShader)
		{
		case AZVertShaderTriTexture:
			haveAttrUV = YES;
			SDL_FALLTHROUGH;
		case AZVertShaderTriColour:
			haveAttrColour = YES;
			SDL_FALLTHROUGH;
		default:
			break;
		}

	int numAttribs 	= 0;
	int pitch		= 0;

	/*************************************************************************\
	|* Do the attributes : Position
	\*************************************************************************/
	va = [AZVertexAttribute atLocation:numAttribs
							bufferSlot:0
								format:SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2
								offset:pitch];
	pitch += 2*sizeof(float);
	numAttribs ++;
	[vis addAttribute:va];

	/*************************************************************************\
	|* Do the attributes : Colour ?
	\*************************************************************************/
	if (haveAttrColour)
		{
		va = [AZVertexAttribute atLocation:numAttribs
								bufferSlot:0
									format:SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4
									offset:pitch];
		pitch += 4*sizeof(float);
		numAttribs ++;
		[vis addAttribute:va];
		}

	/*************************************************************************\
	|* Do the attributes : UV ?
	\*************************************************************************/
	if (haveAttrUV)
		{
		va = [AZVertexAttribute atLocation:numAttribs
								bufferSlot:0
									format:SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2
									offset:pitch];
		pitch += 2*sizeof(float);
		numAttribs ++;
		[vis addAttribute:va];
		}

	/*************************************************************************\
	|* Do the buffer
	\*************************************************************************/
	vb = [AZVertexBuffer bufferWithSlot:0
								  pitch:pitch
							  inputRate:SDL_GPU_VERTEXINPUTRATE_VERTEX
					   instanceStepRate:0];
	[vis addBuffer:vb];

	/*************************************************************************\
	|* Build the pipeline
	\*************************************************************************/
	if (![pipe buildWithRenderer:azr])
		{
		SDL_Log("Cannot build render pipeline");
		return nil;
		}

	/*************************************************************************\
	|* And return it
	\*************************************************************************/
	return pipe;
	}

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
- (BOOL) buildWithRenderer:(id<AZRenderer>)renderer
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

	info.vertex_shader 			= _vertex.shader;
	info.fragment_shader		= _fragment.shader;
	info.vertex_input_state		= _vertexInputState.state;
	info.primitive_type			= _primitiveType;
	info.target_info			= _pipelineTarget.info;
	info.multisample_state		= _multisample;
	info.rasterizer_state		= _rasteriser;

	_pipeline = SDL_CreateGPUGraphicsPipeline(_gpu, &info);

	return (_pipeline != NULL);
	}

@end
