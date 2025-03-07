//
//  AZVertexBuffer.m
//  sdl3_gpu
//
//  Created by ThrudTheBarbarian on 1/13/25.
//

#import "AZVertexBuffer.h"

@implementation AZVertexBuffer

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithSlot:(uint32_t)slot
					    pitch:(uint32_t)pitch
					inputRate:(uint32_t)inputRate
			 instanceStepRate:(uint32_t)instanceStepRate
	{
	if (self = [super init])
		{
		_slot 				= slot;
		_pitch				= pitch;
		_inputRate 			= inputRate;
		_instanceStepRate	= instanceStepRate;
		}
	return self;
	}

+ (AZVertexBuffer *) bufferWithSlot:(uint32_t)slot
							  pitch:(uint32_t)pitch
						  inputRate:(uint32_t)inputRate
				   instanceStepRate:(uint32_t)instanceStepRate
	{
	return [[AZVertexBuffer alloc] initWithSlot:slot
										  pitch:pitch
									  inputRate:inputRate
							   instanceStepRate:instanceStepRate];
	}


/*****************************************************************************\
|* Return a description of this vertex buffer
\*****************************************************************************/
- (SDL_GPUVertexBufferDescription) bufferDescription
	{
	SDL_GPUVertexBufferDescription dsc;

	dsc.input_rate 			= _inputRate;
	dsc.instance_step_rate 	= _instanceStepRate;
	dsc.pitch 				= _pitch;
	dsc.slot 				= _slot;

	return dsc;
	}


@end
