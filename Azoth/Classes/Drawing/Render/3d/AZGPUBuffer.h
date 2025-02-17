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
|* Populate a GPU buffer with data from the CPU
\*****************************************************************************/
- (BOOL) upload:(NSData *)data;

/*****************************************************************************\
|* Download the buffer to an NSData
\*****************************************************************************/
- (NSData *) download;

/*****************************************************************************\
|* Clear the buffer to a byte value
\*****************************************************************************/
- (BOOL) clear;
- (BOOL) clearTo:(uint8_t)value;

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

// The name of the buffer
@property(assign, nonatomic) NSString *							name;
@end

NS_ASSUME_NONNULL_END
