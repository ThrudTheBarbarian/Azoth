//
//  AZComputePipeline.h
//  Azoth
//
//  Created by Simon Gornall on 1/14/25.
//

#import <SDL3/SDL.h>

#import <Azoth/AZTypes.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AZRenderer;

@interface AZComputePipeline : NSObject

/*****************************************************************************\
|* Initialisation - create an instance
\*****************************************************************************/
- (instancetype) initWithName:(NSString *)name;

/*****************************************************************************\
|* Initialisation - convenience
\*****************************************************************************/
+ (instancetype) pipelineNamed:(NSString *)name
			  storageBuffersRO:(int)numROStorageBuffers
			  storageBuffersRW:(int)numRWStorageBuffers
					   threads:(AZThreadSize)threads;


/*****************************************************************************\
|* Build the compute pipeline
\*****************************************************************************/
- (BOOL) buildWithDevice:(id<AZRenderer>)renderer;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The number of read-only storage buffers
@property(assign, nonatomic) int						roStorageBuffers;

// The number of read-write storage buffers
@property(assign, nonatomic) int						rwStorageBuffers;

// Thread counts in X,Y,Z
@property(assign, nonatomic) AZThreadSize				threads;

// The actual pipeline
@property(assign, nonatomic) SDL_GPUComputePipeline *	pipeline;
@end

NS_ASSUME_NONNULL_END
