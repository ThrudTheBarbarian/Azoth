//
//  AZGPUBuffer.h
//  Azoth
//
//  Created by Simon Gornall on 1/29/25.
//

#import <Azoth/AZTypes.h>
#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AZRenderer;

@interface AZGPUBuffer : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initFor:(id<AZRenderer>)renderer
				    size:(UInt32)size
				   usage:(SDL_GPUBufferUsageFlags)flags
				   props:(SDL_PropertiesID)props;

- (instancetype) initFor:(id<AZRenderer>)renderer
				    size:(UInt32)size;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Size of the buffer
@property(assign, nonatomic, readonly) UInt32					size;

// Flags for the buffer
@property(assign, nonatomic, readonly) SDL_GPUBufferUsageFlags	flags;

// Properties for extensions, or 0
@property(assign, nonatomic) SDL_PropertiesID					props;

// The actual GPU buffer
@property(assign, nonatomic) SDL_GPUBuffer *					buffer;
@end

NS_ASSUME_NONNULL_END
