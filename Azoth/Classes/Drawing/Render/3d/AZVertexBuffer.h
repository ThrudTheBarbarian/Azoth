//
//  AZVertexBuffer.h
//  sdl3_gpu
//
//  Created by ThrudTheBarbarian on 1/13/25.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZVertexBuffer : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithSlot:(uint32_t)slot
					    pitch:(uint32_t)pitch
					inputRate:(uint32_t)inputRate
			 instanceStepRate:(uint32_t)instanceStepRate;

+ (AZVertexBuffer *) bufferWithSlot:(uint32_t)slot
							  pitch:(uint32_t)pitch
						  inputRate:(uint32_t)inputRate
				   instanceStepRate:(uint32_t)instanceStepRate;



/*****************************************************************************\
|* Return a description of this vertex buffer
\*****************************************************************************/
- (SDL_GPUVertexBufferDescription) bufferDescription;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The binding slot of the vertex buffer
@property(assign, nonatomic) uint32_t 						slot;

// The byte pitch between consecutive elements of
// the vertex buffer
@property(assign, nonatomic) uint32_t						pitch;

// Whether attribute addressing is a function of the
// vertex index or instance index.
@property(assign, nonatomic) SDL_GPUVertexInputRate			inputRate;

// The number of instances to draw using the same
// per-instance data before advancing in the instance
// buffer by one element. Ignored unless input_rate is
// SDL_GPU_VERTEXINPUTRATE_INSTANCE
@property(assign, nonatomic) uint32_t 						instanceStepRate;

@end

NS_ASSUME_NONNULL_END
