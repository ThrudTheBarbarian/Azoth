//
//  AZComputePipeline.m
//  Azoth
//
//  Created by Simon Gornall on 1/14/25.
//

#import "AZComputePipeline.h"
#import "AZRenderer.h"


#define SHADER_PATH(base,dir,name,ext) [NSString stringWithFormat:			\
										@"%@/Shaders/%@/%@.comp.%@",		\
										base, dir, name, ext]

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZComputePipeline()

// The name of the compute shader
@property(strong, nonatomic) NSString *								name;

// The GPU device we were created with
@property(assign, nonatomic) SDL_GPUDevice *						gpu;
@end

@implementation AZComputePipeline

/*****************************************************************************\
|* Initialisation - convenience
\*****************************************************************************/
+ (instancetype) pipelineNamed:(NSString *)name
			  storageBuffersRO:(int)numROStorageBuffers
			  storageBuffersRW:(int)numRWStorageBuffers
					   threads:(AZThreadSize)threads
	{
	AZComputePipeline *pipe = nil;

	pipe = [[AZComputePipeline alloc] initWithName:name];
	if (pipe)
		{
		pipe.roStorageBuffers 	= numROStorageBuffers;
		pipe.rwStorageBuffers	= numRWStorageBuffers;
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
		_name = name;
		}
	return self;
	}

/*****************************************************************************\
|* Build the compute pipeline
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
	|* Attempt to load from the framework bundle then the application
	\*********************************************************************/
	if (![self _load:_name from:[NSBundle bundleForClass:self.class]])
		[self _load:_name from:NSBundle.mainBundle];

	if (_pipeline == NULL)
		{
		SDL_Log("%s", "Cannot create compute pipeline for %s!",
						_name.UTF8String);
		return NO;
		}

	return YES;
	}


/*****************************************************************************\
|* Load a compute shader from a location
\*****************************************************************************/
- (BOOL) _load:(NSString *)name from:(NSBundle *)bundle
	{
	/*************************************************************************\
	|* Do a format match to get the correct shader format
	\*************************************************************************/
	NSString *fullPath				= nil;
	SDL_GPUShaderFormat format 		= SDL_GPU_SHADERFORMAT_INVALID;
	NSString *entryPoint			= nil;
	
	if (self)
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
	|* Load the shader code
	\*************************************************************************/
	if (self)
		{
		NSData * code = [NSData dataWithContentsOfFile:fullPath];
		if (code == nil)
			return NO;

		SDL_GPUComputePipelineCreateInfo info;

		info.num_readonly_storage_buffers 	= _roStorageBuffers;
		info.num_readwrite_storage_buffers	= _rwStorageBuffers;
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

@end
