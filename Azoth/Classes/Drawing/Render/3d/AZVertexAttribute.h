//
//  AZVertexAttribute.h
//  sdl3_gpu
//
//  Created by Simon Gornall on 1/13/25.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZVertexAttribute : NSObject


/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithLocation:(uint32_t)location
					   bufferSlot:(uint32_t)bufferSlot
						   format:(uint32_t)format
						   offset:(uint32_t)offset;

+ (instancetype) atLocation:(uint32_t)location
				 bufferSlot:(uint32_t)bufferSlot
					 format:(uint32_t)format
					 offset:(uint32_t)offset;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The shader input location index
@property(assign, nonatomic) uint32_t 							location;

// The binding slot of the associated vertex buffer
@property(assign, nonatomic) uint32_t							bufferSlot;

// The size and type of the attribute data.
@property(assign, nonatomic) SDL_GPUVertexElementFormat			format;

// The byte offset of this attribute relative to the
// start of the vertex element
@property(assign, nonatomic) uint32_t							offset;
@end

NS_ASSUME_NONNULL_END
