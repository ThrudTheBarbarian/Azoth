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

// The Renderer we were created with
@property(strong, nonatomic) AZRenderer3d *							azr;

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
	_azr 		= (AZRenderer3d *)azr;
	_size		= size;
	_flags		= flags;
	_props		= props;

	SDL_GPUBufferCreateInfo info = {
		.usage = _flags,
		.size  = _size,
		.props = _props
		};

	_buffer = SDL_CreateGPUBuffer(_azr.gpu, &info);
	}

/*****************************************************************************\
|* Cleanup on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	SDL_ReleaseGPUBuffer(_azr.gpu, _buffer);
	}


/*****************************************************************************\
|* Populate a GPU buffer with data from the CPU
\*****************************************************************************/
- (BOOL) upload:(NSData *)data
	{
	return [_azr upload:data to:self];
	}

/*****************************************************************************\
|* Download the buffer to an NSData
\*****************************************************************************/
- (NSData *) download
	{
	return [_azr download:self];
	}

/*****************************************************************************\
|* Clear the buffer to a byte value
\*****************************************************************************/
- (BOOL) clear
	{
	return [self clearTo:0];
	}

- (BOOL) clearTo:(uint8_t)value
	{
	return [_azr clearBuffer:self to:value];
	}


/*****************************************************************************\
|* Set/Get the buffer name
\*****************************************************************************/
- (void) setName:(NSString *)name
	{
	_name = name;
	SDL_SetGPUBufferName(_azr.gpu, self.buffer, name.UTF8String);
	}

@end
