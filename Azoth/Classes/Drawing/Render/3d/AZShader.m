//
//  AZShader.m
//  sdl3_gpu
//
//  Created by Simon Gornall on 1/13/25.
//

#import <SDL3/SDL.h>

#import "AZShader.h"

#define SHADER_PATH(base,dir,name,ext) [NSString stringWithFormat:			\
										@"%@/Shaders/Compiled/%@/%@.%@",	\
										base, dir, name, ext]


/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZShader()

// The actual shader
@property(assign, nonatomic) SDL_GPUShader *						shader;

// The GPU device we were created with
@property(assign, nonatomic) SDL_GPUDevice *						gpu;
@end


@implementation AZShader

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (instancetype) shaderWithRenderer:(id<AZRenderer>)renderer
							   name:(NSString *)name
						   samplers:(int)numSamplers
				     uniformBuffers:(int)numUniformBuffers
				     storageBuffers:(int)numStorageBuffers
				    storageTextures:(int)numStorageTextures
	{
	return [[AZShader alloc] initWithRenderer:renderer
										 name:name
									 samplers:numSamplers
							   uniformBuffers:numUniformBuffers
							   storageBuffers:numStorageBuffers
							  storageTextures:numStorageTextures];
	}

- (instancetype) initWithRenderer:(id<AZRenderer>)renderer
							 name:(NSString *)name
						 samplers:(int)numSamplers
				   uniformBuffers:(int)numUniformBuffers
				   storageBuffers:(int)numStorageBuffers
				  storageTextures:(int)numStorageTextures
	{
	if (self = [super init])
		{
		/*********************************************************************\
		|* Get the GPU device from the renderer
		\*********************************************************************/
		_gpu = renderer.gpu;
		if (_gpu == NULL)
			{
			SDL_Log("GPU device is not registered");
			self = nil;
			}

		/*********************************************************************\
		|* Determine which kind of shader we have, based on the filename
		\*********************************************************************/
		SDL_GPUShaderStage stage = SDL_GPU_SHADERSTAGE_VERTEX;
		if (self)
			{
			if ([name hasSuffix:@".vert"])
				stage = SDL_GPU_SHADERSTAGE_VERTEX;
			else if ([name hasSuffix:@".frag"])
				stage = SDL_GPU_SHADERSTAGE_FRAGMENT;
			else
				{
				SDL_Log("Shader %s not of type .vert or .frag",
						name.fileSystemRepresentation);
				self = nil;
				}
			}

		/*********************************************************************\
		|* Do a format match to get the correct shader format
		\*********************************************************************/
		NSString *fullPath				= nil;
		SDL_GPUShaderFormat format 		= SDL_GPU_SHADERFORMAT_INVALID;
		NSString *entryPoint			= nil;

		if (self)
			{
			NSString *rsrc 				= NSBundle.mainBundle.resourcePath;
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
				SDL_Log("%s", "Unrecognized backend shader format!");
				self = nil;
				}
			}

		/*********************************************************************\
		|* Load the shader code
		\*********************************************************************/
		if (self)
			{
			NSData * code = [NSData dataWithContentsOfFile:fullPath];
			if (code == nil)
				{
				SDL_Log("Cannot load shader at %s", fullPath.UTF8String);
				self = nil;
				}
			else
				{
				SDL_GPUShaderCreateInfo shaderInfo =
					{
					.code = code.bytes,
					.code_size = code.length,
					.entrypoint = entryPoint.UTF8String,
					.format = format,
					.stage = stage,
					.num_samplers = numSamplers,
					.num_uniform_buffers = numUniformBuffers,
					.num_storage_buffers = numStorageBuffers,
					.num_storage_textures = numStorageTextures
					};

				_shader = SDL_CreateGPUShader(_gpu, &shaderInfo);
				if (_shader == NULL)
					{
					SDL_Log("Cannot create shader from %s",
							fullPath.fileSystemRepresentation);
					self = nil;
					}
				}
			}
		}
	return self;
	}


/*****************************************************************************\
|* Decrement the SDL retain-count for this shader
\*****************************************************************************/
- (void) releaseShader
	{
	SDL_ReleaseGPUShader(_gpu, _shader);
	}

@end
