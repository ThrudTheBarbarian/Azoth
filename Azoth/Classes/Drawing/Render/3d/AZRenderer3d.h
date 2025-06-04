//
//  AZRenderer3d.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <SDL3/SDL.h>

#import <Foundation/Foundation.h>
#import <Azoth/AZRenderer.h>
#import <Azoth/AZTypes.h>

typedef enum
	{
    AZRenderLineMethodPoints = 1,
    AZRenderLineMethodLines,
    AZRenderLineMethodGeometry,
	} AZRenderLineMethod;

NS_ASSUME_NONNULL_BEGIN

@class AZColour;
@class AZComputePipeline;
@class AZGPUBuffer;
@class AZImage;
@class AZTexture;

@interface AZRenderer3d : NSObject <AZRenderer>

/*****************************************************************************\
|* Return the 3D renderer
\*****************************************************************************/
+ (AZRenderer3d *) renderer;


/*****************************************************************************\
|* Blend operation/factor extraction
\*****************************************************************************/
- (SDL_BlendFactor) blendModeSrcColourFactor:(SDL_BlendMode)blendMode;
- (SDL_BlendFactor) blendModeDstColourFactor:(SDL_BlendMode)blendMode;
- (SDL_BlendOperation) blendModeColourOperation:(SDL_BlendMode)blendMode;
- (SDL_BlendFactor) blendModeSrcAlphaFactor:(SDL_BlendMode)blendMode;
- (SDL_BlendFactor) blendModeDstAlphaFactor:(SDL_BlendMode)blendMode;
- (SDL_BlendOperation) blendModeAlphaOperation:(SDL_BlendMode)blendMode;

/*****************************************************************************\
|* Run a compute pipeline
\*****************************************************************************/
- (BOOL) dispatchComputePipeline:(AZComputePipeline *)pipeline
				 withUniformData:(void *)data
						ofLength:(uint32_t)length;


/*****************************************************************************\
|* Upload data to a buffer
\*****************************************************************************/
- (BOOL) upload:(NSData *)data to:(AZGPUBuffer *)buffer;

/*****************************************************************************\
|* Download data from a buffer
\*****************************************************************************/
- (NSData *) download:(AZGPUBuffer *)buffer;

/*****************************************************************************\
|* Clear a buffer to a value
\*****************************************************************************/
- (BOOL) clearBuffer:(AZGPUBuffer *)buffer to:(uint8_t)value;

/*****************************************************************************\
|* We can turn Images into textures
\*****************************************************************************/
- (nullable AZTexture *) textureForId:(NSInteger)refId;

/*****************************************************************************\
|* blit a texture using provided geometry. The first two call the last (which
|* is the actual method) but are more convenient. Note that a texture of 0
|* can be applied which will not texture the quad, you'll just get colour
|* blending
\*****************************************************************************/
- (BOOL) blit:(NSInteger)textureId
		 with:(int)numVertices
	 vertices:(SDL_Vertex *)vertices;

- (BOOL) blit:(NSInteger)textureId
		 with:(int)numVertices
	 vertices:(SDL_Vertex *)vertices
	      and:(int)numIndices
	  indices:(nullable const int *)indices;

- (BOOL) blit:(NSInteger)textureId
		 with:(int)numVertices
		   xy:(const float *)xy
	   stride:(int)xyStride
	  colours:(SDL_FColor *)colours
	   stride:(int)colourStride
		   uv:(const float *)uv
	   stride:(int)uvStride
		  and:(int)numIndices
	  indices:(nullable const int *)indices
	   ofSize:(int)sizeIndices;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Returns the swapchain texture format for this
// GPU and window combination
@property(assign, nonatomic,readonly)
SDL_GPUTextureFormat 										swapchainFormat;

// The colour used to clear textures with
@property(strong, nonatomic) AZColour *						clearColour;

// The current draw colour
@property(strong, nonatomic) AZColour *						colour;

// Different ways to render lines
@property(assign, nonatomic) AZRenderLineMethod				lineMethod;

// The colourspace used for screen display
@property(assign, nonatomic) SDL_Colorspace					outputColourspace;

// The way we address textures in renderGeometry
@property(assign, nonatomic) AZTextureAddressMode			addressMode;
@end

NS_ASSUME_NONNULL_END
