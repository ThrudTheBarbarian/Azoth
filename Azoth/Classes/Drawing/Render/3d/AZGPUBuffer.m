//
//  AZGPUBuffer.m
//  Azoth
//
//  Created by Simon Gornall on 1/29/25.
//

#import "AZGPUBuffer.h"
#import "AZRenderer.h"
#import "AZRenderer3d.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZGPUBuffer()

// The GPU device we were created with
@property(assign, nonatomic) SDL_GPUDevice *						gpu;

@end

@implementation AZGPUBuffer

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initFor:(id<AZRenderer>)renderer
				    size:(UInt32)size
	{
	if (self = [super init])
		{
		[self _commonGpuBufferInitFor:renderer
								 size:size
								usage:SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ |
									  SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE
								props:0];

		if (!_buffer)
			self = nil;
		}
	return self;
	}

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initFor:(id<AZRenderer>)renderer
				    size:(UInt32)size
				   usage:(SDL_GPUBufferUsageFlags)flags
				   props:(SDL_PropertiesID)props
	{
	/*************************************************************************\
	|* Initialisation
	\*************************************************************************/
	if (self = [super init])
		{
		[self _commonGpuBufferInitFor:renderer
								 size:size
								usage:flags
								props:props];
		if (!_buffer)
			self = nil;
		}
	return self;
	}

/*****************************************************************************\
|* Common initialisation
\*****************************************************************************/
- (void) _commonGpuBufferInitFor:(id<AZRenderer>)azr
							size:(UInt32)size
						   usage:(SDL_GPUBufferUsageFlags)flags
						   props:(SDL_PropertiesID)props
	{
	_gpu 		= azr.gpu;
	_size		= size;
	_flags		= flags;
	_props		= props;

	SDL_GPUBufferCreateInfo info = {
		.usage = _flags,
		.size  = _size,
		.props = _props
		};

	_buffer = SDL_CreateGPUBuffer(_gpu, &info);
	}

/*****************************************************************************\
|* Cleanup on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	SDL_ReleaseGPUBuffer(_gpu, _buffer);
	}


/*****************************************************************************\
|* Populate a GPU buffer with data from the CPU
\*****************************************************************************/
- (BOOL) upload:(NSData *)data
	{
	AZRenderer3d *azr 	= (AZRenderer3d *)AZRenderer.renderer;
	return [azr upload:data to:self];
	}

/*****************************************************************************\
|* Set/Get the buffer name
\*****************************************************************************/
- (void) setName:(NSString *)name
	{
	_name = name;
	SDL_SetGPUBufferName(_gpu, self.buffer, name.UTF8String);
	}

@end
