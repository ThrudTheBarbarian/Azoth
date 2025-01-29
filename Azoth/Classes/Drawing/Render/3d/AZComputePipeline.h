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

@class AZGPUBuffer;
@class AZSampler;
@class AZTexture;

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
- (BOOL) buildWithRenderer:(id<AZRenderer>)renderer;

/*****************************************************************************\
|* Add a sampler, used when running the pipeline. Added in order
\*****************************************************************************/
- (void) addSampler:(AZSampler *)sampler forTexture:(AZTexture *)texture;

/*****************************************************************************\
|* Add an output buffer, used when running the pipeline. Added in order
\*****************************************************************************/
- (void) addOutputBuffer:(AZGPUBuffer *)buffer;

/*****************************************************************************\
|* Add an output texture, used when running the pipeline. Added in order
\*****************************************************************************/
- (void) addOutputTexture:(AZTexture *)texture;

/*****************************************************************************\
|* Add an output texture with all the options
\*****************************************************************************/
- (void) addOutputTexture:(AZTexture *)texture
			 withMipLevel:(int)mipLevel
 				 andLayer:(int)layer;

/*****************************************************************************\
|* Remove any previously-supplied bindings (samplers, output-textures,...)
\*****************************************************************************/
- (void) reset;



// MARK: Return bindings-data to the renderer

/*****************************************************************************\
|* Return the read-write texture binding info structures to the renderer
\*****************************************************************************/
- (nullable SDL_GPUStorageTextureReadWriteBinding *) textureReadWriteBindings;

/*****************************************************************************\
|* Return the count of read-write texture binding info structures
\*****************************************************************************/
- (uint32_t) numTextureReadWriteBindings;

/*****************************************************************************\
|* Return the read-write storage binding info structures to the renderer
\*****************************************************************************/
- (nullable SDL_GPUStorageBufferReadWriteBinding *) bufferReadWriteBindings;

/*****************************************************************************\
|* Return the count of read-write buffer binding info structures
\*****************************************************************************/
- (uint32_t) numBufferReadWriteBindings;

/*****************************************************************************\
|* Return the sampler binding info structures to the renderer
\*****************************************************************************/
- (nullable SDL_GPUTextureSamplerBinding *) samplerBindings;

/*****************************************************************************\
|* Return the count of read-write buffer binding info structures
\*****************************************************************************/
- (uint32_t) numSamplerBindings;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The number of read-only storage buffers
@property(assign, nonatomic) int							roStorageBuffers;

// The number of read-write storage buffers
@property(assign, nonatomic) int							rwStorageBuffers;

// Thread counts in X,Y,Z
@property(assign, nonatomic) AZThreadSize					threads;

// The actual pipeline
@property(assign, nonatomic) SDL_GPUComputePipeline *		pipeline;

// Whether to cycle buffers on creation of the
// pipeline. See https://tinyurl.com/nhwh7j6d
@property(assign, nonatomic) BOOL 							cycle;

// index of the uniform-data slot to bind
// uniforms to
@property(assign, nonatomic) uint32_t 						uniformSlot;

// index of the sampler-data slot to bind
// samplers to
@property(assign, nonatomic) uint32_t 						samplerSlot;

// Number of "work-units" in X. This will be
// automatically calculate as
// max-outputtexture-width/threads
// but is here for manual override
@property(assign, nonatomic) AZThreadSize					jobs;

@end

NS_ASSUME_NONNULL_END
