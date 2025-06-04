//
//  AZComputePipeline.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <SDL3/SDL.h>

#import <Azoth/AZTypes.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZImage;
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
					   storage:(AZComputeStorageInfo)info
					   threads:(AZThreadSize)threads;



/*****************************************************************************\
|* Build the compute pipeline
\*****************************************************************************/
- (BOOL) build;

/*****************************************************************************\
|* Build the compute pipeline with a given renderer
\*****************************************************************************/
- (BOOL) buildWithRenderer:(id<AZRenderer>)renderer;




// MARK: Provide objects (textures, buffers, samplers) to the pipeline

/*****************************************************************************\
|* Add a sampler, used when running the pipeline. Added in order
\*****************************************************************************/
- (void) addSampler:(AZSampler *)sampler forTexture:(AZTexture *)texture;

/*****************************************************************************\
|* Add an output buffer, used when running the pipeline. Added in order
\*****************************************************************************/
- (void) addOutputBuffer:(AZGPUBuffer *)buffer;

/*****************************************************************************\
|* Add an input buffer, used when running the pipeline. Added in order
\*****************************************************************************/
- (void) addInputBuffer:(AZGPUBuffer *)buffer;

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
|* Add an input texture, used when running the pipeline. Added in order
\*****************************************************************************/
- (void) addInputTexture:(AZTexture *)texture;

/*****************************************************************************\
|* Add an output texture with all the options
\*****************************************************************************/
- (void) addInputTexture:(AZTexture *)texture
			withMipLevel:(int)mipLevel
				andLayer:(int)layer;



// MARK: Return bindings-data to the renderer


/*****************************************************************************\
|* Remove any previously-supplied bindings (samplers, output-textures,...)
\*****************************************************************************/
- (void) reset;

/*****************************************************************************\
|* Populate the output storage-texture bindings structs. This expects an
|* appropriately-sized texture, which size can be found by calling into
|* -numOutputTextureReadWriteBindings
\*****************************************************************************/
- (int) populateOutputTextureBindings:(SDL_GPUStorageTextureReadWriteBinding*)b;

/*****************************************************************************\
|* Return the count of read-write texture binding info structures
\*****************************************************************************/
- (uint32_t) numOutputTextureBindings;



/*****************************************************************************\
|* Populate the input texture bindings structs. This is less likely to be
|* used, because specifying a sampler will also specify the input texture to
|* get data from using that sampler
\*****************************************************************************/
- (int) populateInputTextureBindings:(SDL_GPUStorageTextureReadWriteBinding*)b;

/*****************************************************************************\
|* Return the count of read-write texture binding info structures
\*****************************************************************************/
- (uint32_t) numInputTextureBindings;



/*****************************************************************************\
|* Populate the output storage-texture bindings structs. This expects an
|* appropriately-sized buffer, which size can be found by calling into
|* -numOutputBufferReadWriteBindings
\*****************************************************************************/
- (int) populateOutputBufferBindings:(SDL_GPUStorageBufferReadWriteBinding *)b;

/*****************************************************************************\
|* Return the count of read-write buffer binding info structures
\*****************************************************************************/
- (uint32_t) numOutputBufferBindings;



/*****************************************************************************\
|* Populate the input buffer bindings structs. This expects an
|* appropriately-sized buffer, which size can be found by calling into
|* -numInputBufferReadWriteBindings
\*****************************************************************************/
- (int) populateInputBufferBindings:(SDL_GPUStorageBufferReadWriteBinding *)b;

/*****************************************************************************\
|* Return the count of input buffer binding info structures
\*****************************************************************************/
- (uint32_t) numInputBufferBindings;



/*****************************************************************************\
|* Populate the input sampler bindings structs. \*****************************************************************************/
- (int) populateSamplerBindings:(SDL_GPUTextureSamplerBinding *)bind;

/*****************************************************************************\
|* Return the count of read-write buffer binding info structures
\*****************************************************************************/
- (uint32_t) numSamplerBindings;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The number of read-only storage buffers
@property(assign, nonatomic) AZComputeStorageInfo			storage;

// Thread counts in X,Y,Z
@property(assign, nonatomic) AZThreadSize					threads;

// The actual pipeline
@property(assign, nonatomic) SDL_GPUComputePipeline *		pipeline;

// Whether to cycle buffers on creation of the
// pipeline. See https://tinyurl.com/nhwh7j6d
@property(assign, nonatomic) BOOL 							cycle;

// index of the 1st uniform-data slot to bind
// uniforms to
@property(assign, nonatomic) uint32_t 						uniformSlot;

// index of the 1st sampler-data slot to bind
// samplers to
@property(assign, nonatomic) uint32_t 						samplerSlot;

// index of the 1st output-buffer-data slot to bind
// output-buffers to
@property(assign, nonatomic) uint32_t 						bufferSlot;

// index of the 1st output-texture-data slot to bind
// output-textures to
@property(assign, nonatomic) uint32_t 						textureSlot;

// Number of "work-units" in X. This will be
// automatically calculate as
// max-outputtexture-width/threads
// but is here for manual override
@property(assign, nonatomic) AZThreadSize					jobs;

@end

NS_ASSUME_NONNULL_END
