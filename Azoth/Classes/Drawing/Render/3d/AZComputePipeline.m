//
//  AZComputePipeline.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/14/25.
//

#import "AZComputePipeline.h"
#import "AZGPUBuffer.h"
#import "AZRenderer.h"
#import "AZSampler.h"
#import "AZTexture.h"


#define SHADER_PATH(base,dir,name,ext) [NSString stringWithFormat:			\
										@"%@/Shaders/%@/%@.comp.%@",		\
										base, dir, name, ext]

#define kSampler			@"sampler"
#define kTexture			@"texture"
#define kMipLevel			@"mipLevel"
#define kLayer				@"layer"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZComputePipeline()

// The name of the compute shader
@property(strong, nonatomic) NSString *							name;

// The GPU device we were created with
@property(assign, nonatomic) SDL_GPUDevice *					gpu;

// The samplers to bind
@property(strong, nonatomic)
NSMutableArray<NSDictionary<NSString *,id> *> *					samplers;

// The output textures to bind
@property(strong, nonatomic)
NSMutableArray<NSDictionary<NSString*,id> *> *					outTex;

// The input textures to bind
@property(strong, nonatomic)
NSMutableArray<NSDictionary<NSString*,id> *> *					inTex;

// The output storage buffers to bind
@property(strong, nonatomic)
NSMutableArray<AZGPUBuffer *> *									outBuf;

// The input storage buffers to bind
@property(strong, nonatomic)
NSMutableArray<AZGPUBuffer *> *									inBuf;

@end

@implementation AZComputePipeline

/*****************************************************************************\
|* Initialisation - convenience
\*****************************************************************************/
+ (instancetype) pipelineNamed:(NSString *)name
					   storage:(AZComputeStorageInfo)storage
					   threads:(AZThreadSize)threads
	{
	AZComputePipeline *pipe = nil;

	pipe = [[AZComputePipeline alloc] initWithName:name];
	if (pipe)
		{
		pipe.storage 			= storage;
		pipe.threads			= threads;
		}
	return pipe;
	}

/*****************************************************************************\
|* Initialisation - create an instance
\*****************************************************************************/
- (instancetype) initWithName:(NSString *)name
	{
	if (self = [super init])
		{
		_name 			= name;
		_samplers 		= NSMutableArray.new;
		_outTex 		= NSMutableArray.new;
		_inTex 			= NSMutableArray.new;
		_outBuf			= NSMutableArray.new;
		_inBuf			= NSMutableArray.new;
		_samplerSlot	= 0;
		_uniformSlot	= 0;
		_bufferSlot		= 0;
		_threads		= (AZThreadSize){8,8,1};
		_jobs 			= (AZThreadSize){1,1,1};
		_storage		= (AZComputeStorageInfo){0,0,0,0};
		}
	return self;
	}

/*****************************************************************************\
|* Cleanup
\*****************************************************************************/
- (void) dealloc
	{
	[self reset];
	if (_pipeline)
		SDL_ReleaseGPUComputePipeline(_gpu, _pipeline);
	}

/*****************************************************************************\
|* Add a sampler
\*****************************************************************************/
- (void) addSampler:(AZSampler *)sampler forTexture:(nonnull AZTexture *)texture
	{
	[_samplers addObject:@{
					kSampler 	: sampler,
					kTexture	: texture
					}];
	}

/*****************************************************************************\
|* Add an output texture
\*****************************************************************************/
- (void) addOutputTexture:(AZTexture *)texture
	{
	[self addOutputTexture:texture withMipLevel:0 andLayer:0];
	}

/*****************************************************************************\
|* Add an output texture
\*****************************************************************************/
- (void) addOutputTexture:(AZTexture *)texture
			 withMipLevel:(int)mipLevel
 				 andLayer:(int)layer

	{
	int jobsX = texture.size.width 	/ _threads.x;
	int jobsY = texture.size.height	/ _threads.y;

	if (jobsX > _jobs.x)
		_jobs.x = jobsX;

	if (jobsY > _jobs.y)
		_jobs.y = jobsY;

	[_outTex addObject:@{
				kTexture 	: texture,
				kLayer		: @(layer),
				kMipLevel	: @(mipLevel)
				}];
	}

/*****************************************************************************\
|* Add an input texture
\*****************************************************************************/
- (void) addInputTexture:(AZTexture *)texture
	{
	[self addInputTexture:texture withMipLevel:0 andLayer:0];
	}

/*****************************************************************************\
|* Add an input texture
\*****************************************************************************/
- (void) addInputTexture:(AZTexture *)texture
			withMipLevel:(int)mipLevel
				andLayer:(int)layer

	{
	int jobsX = texture.size.width 	/ _threads.x;
	int jobsY = texture.size.height	/ _threads.y;

	if (jobsX > _jobs.x)
		_jobs.x = jobsX;

	if (jobsY > _jobs.y)
		_jobs.y = jobsY;

	[_inTex addObject:@{
				kTexture 	: texture,
				kLayer		: @(layer),
				kMipLevel	: @(mipLevel)
				}];
	}

/*****************************************************************************\
|* Add an output buffer
\*****************************************************************************/
- (void) addOutputBuffer:(AZGPUBuffer *)buffer
	{
	[_outBuf addObject:buffer];
	}


/*****************************************************************************\
|* Add an input buffer
\*****************************************************************************/
- (void) addInputBuffer:(AZGPUBuffer *)buffer
	{
	[_inBuf addObject:buffer];
	}

/*****************************************************************************\
|* Remove any previously-supplied bindings (samplers, output-textures,...)
\*****************************************************************************/
- (void) reset
	{
	[_inTex removeAllObjects];
	[_outTex removeAllObjects];
	[_samplers removeAllObjects];
	[_outBuf removeAllObjects];
	[_inBuf removeAllObjects];
	}

/*****************************************************************************\
|* Build the compute pipeline
\*****************************************************************************/
- (BOOL) build
	{
	id<AZRenderer> azr = AZRenderer.renderer;
	return [self buildWithRenderer:azr];
	}

/*****************************************************************************\
|* Build the compute pipeline with a given renderer
\*****************************************************************************/
- (BOOL) buildWithRenderer:(id<AZRenderer>)renderer
	{
	/*************************************************************************\
	|* Get the GPU device from the renderer
	\*************************************************************************/
	_gpu = renderer.gpu;
	if (_gpu == NULL)
		{
		SDL_Log("GPU device is not registered");
		return NO;
		}

	/*********************************************************************\
	|* Attempt to load from the framework bundle then the application, then
	|* finally from an absolute path
	\*********************************************************************/
	if (![self _load:_name from:[NSBundle bundleForClass:self.class]])
		[self _load:_name from:NSBundle.mainBundle];

	if (_pipeline == NULL)
		{
		SDL_Log("Cannot create compute pipeline for %s!", _name.UTF8String);
		return NO;
		}

	return YES;
	}


/*****************************************************************************\
|* Load a compute shader from a location. Note that the bundle can only be
|* nil if the full path is provided
\*****************************************************************************/
- (BOOL) _load:(NSString *)name from:(nullable NSBundle *)bundle
	{
	/*********************************************************************\
	|* Do a format match to get the correct shader format
	\*********************************************************************/
	NSString *fullPath				= nil;
	SDL_GPUShaderFormat format 		= SDL_GPU_SHADERFORMAT_INVALID;
	NSString *entryPoint			= nil;

	if (self && (![name hasPrefix:@"/"]))
		{
		NSString *rsrc 				= bundle.resourcePath;
		SDL_GPUShaderFormat known	= SDL_GetGPUShaderFormats(_gpu);

		if (known & SDL_GPU_SHADERFORMAT_SPIRV)
			{
			fullPath 	= SHADER_PATH(rsrc, @"vulcan", name, @"spv");
			format 		= SDL_GPU_SHADERFORMAT_SPIRV;
			entryPoint 	= @"main";
			}
		else if (known & SDL_GPU_SHADERFORMAT_MSL)
			{
			fullPath 	= SHADER_PATH(rsrc, @"metal", name, @"msl");
			format 		= SDL_GPU_SHADERFORMAT_MSL;
			entryPoint 	= @"main0";
			}
		else if (known & SDL_GPU_SHADERFORMAT_DXIL)
			{
			fullPath 	= SHADER_PATH(rsrc, @"directx", name, @"dxil");
			format 		= SDL_GPU_SHADERFORMAT_DXIL;
			entryPoint 	= @"main";
			}
		else
			{
			SDL_Log("%s", "Unrecognized backend compute shader format!");
			return NO;
			}
		}

	/*************************************************************************\
	|* Override the path if it's absolute
	\*************************************************************************/
	else if (self)
		{
		fullPath = name;

		if ([name.pathExtension isEqualToString:@"spirv"])
			{
			format 		= SDL_GPU_SHADERFORMAT_SPIRV;
			entryPoint 	= @"main";
			}
		else if ([name.pathExtension isEqualToString:@"msl"])
			{
			format	 	= SDL_GPU_SHADERFORMAT_MSL;
			entryPoint 	= @"main0";
			}
		else if ([name.pathExtension isEqualToString:@"dxil"])
			{
			format	 	= SDL_GPU_SHADERFORMAT_MSL;
			entryPoint 	= @"main";
			}
		else
			{
			SDL_Log("%s", "Unrecognized backend compute shader format!");
			return NO;
			}
		}

	/*************************************************************************\
	|* Load the shader code
	\*************************************************************************/
	if (self)
		{
		NSData * code = [NSData dataWithContentsOfFile:fullPath];
		if (code == nil)
			return NO;

		SDL_GPUComputePipelineCreateInfo info;

		info.num_readonly_storage_buffers 	= _storage.roBuffers;
		info.num_readwrite_storage_buffers	= _storage.rwBuffers;
		info.num_readonly_storage_textures 	= _storage.roTextures;
		info.num_readwrite_storage_textures	= _storage.rwTextures;
		info.num_samplers					= _storage.samplers;
		info.num_uniform_buffers			= 1;
		info.threadcount_x					= _threads.x;
		info.threadcount_y					= _threads.y;
		info.threadcount_z					= _threads.z;
		info.code							= code.bytes;
		info.code_size						= code.length;
		info.entrypoint						= entryPoint.UTF8String;
		info.format							= format;

		_pipeline = SDL_CreateGPUComputePipeline(_gpu, &info);
		}
	return (_pipeline != NULL);
	}


/*****************************************************************************\
|* Populate the output texture bindings structs. This expects a adequately
|* sized buffer, which size can be found by calling into the method
|* -numTextureReadWriteBindings
\*****************************************************************************/
- (int) populateOutputTextureBindings:(SDL_GPUStorageTextureReadWriteBinding *)bind
	{
	for (NSInteger i=0; i<_outTex.count; i++)
		{
		AZTexture *texture 			= (AZTexture *)_outTex[i][kTexture];
		SDL_GPUTextureUsageFlags f 	= texture.flags;

		BOOL w	= f & SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE;
		BOOL rw = f & SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE;
		if (!(w | rw))
			{
			SDL_Log("Trying to bind a texture to compute output with no w flag");
			return (int)i;
			}

		bind[i].texture 	= texture.texture;
		bind[i].mip_level	= ((NSNumber *) _outTex[i][kMipLevel]).intValue;
		bind[i].layer		= ((NSNumber *) _outTex[i][kLayer]).intValue;
		bind[i].cycle		= _cycle;
		}

	return (int)_outTex.count;
	}

/*****************************************************************************\
|* Return the count of output read-write texture binding info structures
\*****************************************************************************/
- (uint32_t) numOutputTextureBindings
	{
	return (uint32_t) _outTex.count;
	}


/*****************************************************************************\
|* Populate the input texture bindings structs. This expects a adequately
|* sized buffer, which size can be found by calling into the method
|* -numTextureReadWriteBindings
\*****************************************************************************/
- (int) populateInputTextureBindings:(SDL_GPUStorageTextureReadWriteBinding *)bind
	{
	for (NSInteger i=0; i<_inTex.count; i++)
		{
		AZTexture *texture 			= (AZTexture *)_inTex[i][kTexture];
		SDL_GPUTextureUsageFlags f 	= texture.flags;

		BOOL r	= f & SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ;
		BOOL rw = f & SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE;
		if (!(r | rw))
			{
			SDL_Log("Trying to bind a texture to compute input with no r flag");
			return (int)i;
			}

		bind[i].texture 	= texture.texture;
		bind[i].mip_level	= ((NSNumber *) _inTex[i][kMipLevel]).intValue;
		bind[i].layer		= ((NSNumber *) _inTex[i][kLayer]).intValue;
		bind[i].cycle		= _cycle;
		}

	return (int)_inTex.count;
	}

/*****************************************************************************\
|* Return the count of input read-write texture binding info structures
\*****************************************************************************/
- (uint32_t) numInputTextureBindings
	{
	return (uint32_t) _inTex.count;
	}


/*****************************************************************************\
|* Populate the output-buffer bindings structs. This expects a adequately
|* sized buffer, which size can be found by calling into the method
|* -numOutputBufferReadWriteBindings
\*****************************************************************************/
- (int) populateOutputBufferBindings:(SDL_GPUStorageBufferReadWriteBinding *)bind
	{
	for (NSInteger i=0; i<_outBuf.count; i++)
		{
		bind[i].buffer 			= _outBuf[i].buffer;
		bind[i].cycle			= _cycle;
		}

	return (int)_outBuf.count;
	}

/*****************************************************************************\
|* Return the count of read-write buffer binding info structures
\*****************************************************************************/
- (uint32_t) numOutputBufferBindings
	{
	return (uint32_t) _outBuf.count;
	}


/*****************************************************************************\
|* Populate the input-buffer bindings structs. This expects a adequately
|* sized buffer, which size can be found by calling into the method
|* -numInpurBufferReadWriteBindings
\*****************************************************************************/
- (int) populateInputBufferBindings:(SDL_GPUStorageBufferReadWriteBinding *)bind
	{
	for (NSInteger i=0; i<_inBuf.count; i++)
		{
		bind[i].buffer 			= _inBuf[i].buffer;
		bind[i].cycle			= _cycle;
		}

	return (int)_inBuf.count;
	}

/*****************************************************************************\
|* Return the count of read-write buffer binding info structures
\*****************************************************************************/
- (uint32_t) numInputBufferBindings
	{
	return (uint32_t) _inBuf.count;
	}


/*****************************************************************************\
|* Populate the sampler bindings structs. This expects a adequately
|* sized buffer, which size can be found by calling into the method
|* -numSamplerBindings
\*****************************************************************************/
- (int) populateSamplerBindings:(SDL_GPUTextureSamplerBinding *)bind
	{
	for (NSInteger i=0; i<_samplers.count; i++)
		{
		AZTexture *texture	= (AZTexture *)_samplers[i][kTexture];
		AZSampler *sampler	= (AZSampler *)_samplers[i][kSampler];

		bind[i].texture 	= texture.texture;
		bind[i].sampler		= sampler.sampler;
		}

	return (int)_samplers.count;
	}


/*****************************************************************************\
|* Return the count of read-write buffer binding info structures
\*****************************************************************************/
- (uint32_t) numSamplerBindings
	{
	return (uint32_t)_samplers.count;
	}

@end
