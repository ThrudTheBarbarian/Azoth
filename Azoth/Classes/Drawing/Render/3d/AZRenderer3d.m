//
//  AZRenderer3d.m
//  Azoth
//
//  Created by Simon Gornall on 1/13/25.
//

#import <SDL3/SDL.h>

#import "AZ3dUtils.h"
#import "AZColour.h"
#import "AZColourTarget.h"
#import "AZComputePipeline.h"
#import "AZPipelineTarget.h"
#import "AZRenderer3d.h"
#import "AZRenderPipeline.h"
#import "AZShader.h"
#import "AZTexture.h"
#import "AZVertexAttribute.h"
#import "AZVertexBuffer.h"
#import "AZVertexInputState.h"
#import "AZWindow.h"

/*****************************************************************************\
|* Typedefs, enums etc.
\*****************************************************************************/

typedef struct SpriteVertex
	{
	float x, y, z, w;
	float u, v, padding_a, padding_b;
	float r, g, b, a;
	} SpriteVertex;


/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZRenderer3d()

// The texture map for handing out textures
@property(strong, nonatomic)
NSMutableDictionary<NSNumber *, AZTexture *> * 						textures;

// The SDL window we associate this renderer with
@property(assign, nonatomic) SDL_Window *							sdl;

// The AZWindow we associate this renderer with
@property(strong, nonatomic) AZWindow *								window;

// The GPU device
@property(assign, nonatomic) SDL_GPUDevice *						gpu;

// The sprite render pipeline
@property(strong, nonatomic) AZRenderPipeline *						spritePipe;

// The sprite compute pipeline
@property(strong, nonatomic) AZComputePipeline *					computePipe;

@end


/*****************************************************************************\
|* File-private entities
\*****************************************************************************/
static NSInteger 		_textureId;
static SDL_SpinLock 	_textureLock;

@implementation AZRenderer3d
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		/*********************************************************************\
		|* Prepare to store the textures
		\*********************************************************************/
		_textures 	= [NSMutableDictionary new];

		/*********************************************************************\
		|* Default clear colour is in fact ... clear
		\*********************************************************************/
		_clearColour = AZColour.clear;
		}
	return self;
	}

/*****************************************************************************\
|* Return the 3D renderer
\*****************************************************************************/
+ (AZRenderer3d *) renderer
	{
	static AZRenderer3d *azr = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		azr 			= [AZRenderer3d new];
		_textureId 		= 1;
		_textureLock 	= 0;
		});
	return azr;
	}


/*****************************************************************************\
|* Delete everything on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	for (NSNumber *textureId in _textures.allKeys.copy)
		[self releaseTexture:textureId.integerValue];

	SDL_ReleaseGPUComputePipeline(_gpu,_computePipe.pipeline);
	SDL_ReleaseGPUGraphicsPipeline(_gpu,_spritePipe.pipeline);
	}

/*****************************************************************************\
|* Create a window with a given size, title, flags that is compatible with
|* this type of renderer
\*****************************************************************************/
- (BOOL) createWindowWithTitle:(NSString *)title
						 frame:(NSRect)frame
						 style:(NSInteger)styleFlags
	{
	/*************************************************************************\
    |* Open the window
    \*************************************************************************/
	BOOL ok = [self _openWindow:title frame:frame style:styleFlags];

	/*************************************************************************\
    |* Open the GPU
    \*************************************************************************/
	if (ok)
		ok &= [self _initialiseGPU];

	return ok;
	}

/*****************************************************************************\
|* Get a texture-id
\*****************************************************************************/
- (NSNumber *) nextTextureId;
	{
	SDL_LockSpinlock(&_textureLock);
	_textureId ++;
	NSNumber * retVal = [NSNumber numberWithInteger:_textureId];
	SDL_UnlockSpinlock(&_textureLock);
	return retVal;
	}


/*****************************************************************************\
|* Return the swapchain texture format
\*****************************************************************************/
- (SDL_GPUTextureFormat) swapchainFormat
	{
	return SDL_GetGPUSwapchainTextureFormat(_gpu, _sdl);
	}

/*****************************************************************************\
|* Initialise the GPU
\*****************************************************************************/
- (BOOL) _initialiseGPU
	{
	/*************************************************************************\
    |* Open the GPU device
    \*************************************************************************/
	int flags	= SDL_GPU_SHADERFORMAT_SPIRV
				| SDL_GPU_SHADERFORMAT_DXIL
				| SDL_GPU_SHADERFORMAT_MSL;
	_gpu 		= SDL_CreateGPUDevice(flags, YES, NULL);

	if (_gpu == NULL)
		{
		SDL_Log("Cannot create GPU device");
		return NO;
		}

	/*************************************************************************\
    |* Claim the window for the GPU
    \*************************************************************************/
	if (!SDL_ClaimWindowForGPUDevice(_gpu, _sdl))
		{
		SDL_Log("Cannot claim window for GPU");
		return NO;
		}

	/*************************************************************************\
    |* Set the present-mode for the GPU
    \*************************************************************************/
	SDL_GPUPresentMode mode = SDL_GPU_PRESENTMODE_VSYNC;
	if (SDL_WindowSupportsGPUPresentMode(_gpu,
										 _sdl,
										 SDL_GPU_PRESENTMODE_IMMEDIATE))
		mode = SDL_GPU_PRESENTMODE_IMMEDIATE;

	else if (SDL_WindowSupportsGPUPresentMode(_gpu,
											  _sdl,
											  SDL_GPU_PRESENTMODE_MAILBOX))
		mode = SDL_GPU_PRESENTMODE_MAILBOX;

	SDL_SetGPUSwapchainParameters(_gpu,
								  _sdl,
								  SDL_GPU_SWAPCHAINCOMPOSITION_SDR,
								  mode);

	/*************************************************************************\
    |* Create the sprite-rendering pipeline
    \*************************************************************************/
	_spritePipe = [AZRenderPipeline new];

	_spritePipe.primitiveType = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;

	_spritePipe.vertex = [AZShader shaderWithRenderer:self
												 name:@"sprite.vert"
											 samplers:0
									   uniformBuffers:1
									   storageBuffers:0
									  storageTextures:0];

	_spritePipe.fragment = [AZShader shaderWithRenderer:self
												   name:@"sprite.frag"
											   samplers:1
										 uniformBuffers:0
										 storageBuffers:0
										storageTextures:0];

	AZPipelineTarget *pt = AZPipelineTarget.new;

	[pt addColourTarget:[AZColourTarget targetWithFormat:self.swapchainFormat]];
	_spritePipe.pipelineTarget = pt;

	AZVertexInputState *is = AZVertexInputState.new;
	[is addBuffer:[AZVertexBuffer bufferWithSlot:0
										  pitch:sizeof(SpriteVertex)
									  inputRate:SDL_GPU_VERTEXINPUTRATE_VERTEX
							   instanceStepRate:0]];

	[is addAttribute:[AZVertexAttribute
						atLocation:0
						bufferSlot:0
							format:SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4
							offset:0]];

	[is addAttribute:[AZVertexAttribute
						atLocation:1
						bufferSlot:0
							format:SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2
							offset:16]];

	[is addAttribute:[AZVertexAttribute
						atLocation:2
						bufferSlot:0
							format:SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4
							offset:32]];

	_spritePipe.vertexInputState = is;
	[_spritePipe buildWithDevice:_gpu];


	/*************************************************************************\
    |* Create the compute pipeline
    \*************************************************************************/
	_computePipe = [AZComputePipeline pipelineFor:self
											 name:@"sprite.comp"
								 storageBuffersRO:1
								 storageBuffersRW:1
										  threads:AZMakeThreadSize(64,1,1)];

	return YES;
	}

/*****************************************************************************\
|* Open the window
\*****************************************************************************/
- (BOOL) _openWindow:(NSString *)title frame:(NSRect)f style:(NSInteger)flags
	{
	/*************************************************************************\
    |* Create the window
    \*************************************************************************/
	int w 	= (int) f.size.width;
	int h	= (int) f.size.height;
	_sdl = SDL_CreateWindow(title.UTF8String, w, h, flags);
	if (_sdl == NULL)
		return NO;

	/*************************************************************************\
    |* Link it to the AZWindow instance
    \*************************************************************************/
	_window = [[AZWindow alloc] initWithWindow:_sdl];

	/*************************************************************************\
    |* Position it on screen
    \*************************************************************************/
	int x = f.origin.x;
	int y = f.origin.y;
	return SDL_SetWindowPosition(_sdl, x, y);
	}


/*****************************************************************************\
|* We support the GPU device
\*****************************************************************************/
- (nullable struct SDL_GPUDevice *)gpu
	{
	return _gpu;
	}

- (int)blit9WayFrom:(NSInteger)textureId
				src:(NSRect)srcRect
			  scale:(float)scale
			   left:(float)left
			  right:(float)right
			    top:(float)top
			 bottom:(float)bottom
				dst:(NSRect)dstRect
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (int)blitFrom:(NSInteger)texture src:(NSRect)srcRect dst:(NSRect)dstRect
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (int)blitFrom:(NSInteger)textureId
			src:(NSRect)srcRect
			dst:(NSRect)dstRect
		  angle:(NSInteger)degrees
		 center:(NSPoint)p
		   flip:(AZFlipMode)flip
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (NSRect)boundsOfTexture:(NSInteger)refId
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return NSZeroRect;
	}


- (void)clear
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}


- (BOOL)clipEnabled
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return NO;
	}


- (NSRect)clipRect
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return NSZeroRect;
	}


- (BOOL)convertRx:(float)rx
			   ry:(float)ry
			   to:(nonnull float *)wx
			   wy:(nonnull float *)wy
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return NO;
	}


/*****************************************************************************\
|* Create a texture of a given size. We assume RGBA8888 format for the
|* texture. This needs to:
|*
|*  - Allocate a texture-id for the new texture
|*  - create a transfer buffer and map it so the CPU can see it
|*  - fill the transfer buffer with the current clear-colour
|*  - create a GPU texture of the same size
|*  - start a copy pass and upload the data to the texture
|*  - finish the copy pass and return the texture-id to the caller
|*
\*****************************************************************************/
- (NSInteger)createTextureOfSize:(NSSize)size
	{
	/*************************************************************************\
	|* Get a new unique texture id
	\*************************************************************************/
	NSNumber *tId = self.nextTextureId;

	/*************************************************************************\
	|* Create a transfer buffer of the correct size
	\*************************************************************************/
	SDL_GPUTransferBuffer *upload = [self _uploadBufferOfSize:size];
	if (upload == NULL)
		{
		SDL_Log("Cannot obtain GPU upload buffer of size %dx%d",
				(int)size.width, (int)size.height);
		return -1;
		}

	/*************************************************************************\
	|* Map the buffer
	\*************************************************************************/
	uint32_t* cpuPtr = SDL_MapGPUTransferBuffer(_gpu, upload, NO);

	/*************************************************************************\
	|* Clear the buffer
	\*************************************************************************/
	uint32_t colour  	= _clearColour.value32;
	uint32_t *pixel  	= cpuPtr;
	NSInteger num  		= size.width * size.height;

	for (NSInteger i=0; i<num; i++)
		*pixel++ = colour;

	/*************************************************************************\
	|* Unmap the buffer
	\*************************************************************************/
	SDL_UnmapGPUTransferBuffer(_gpu, upload);

	/*************************************************************************\
	|* Create the GPU texture
	\*************************************************************************/
	SDL_GPUTextureUsageFlags flags = SDL_GPU_TEXTUREUSAGE_SAMPLER
								   | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET
								   | SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ
								   | SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE;

	AZTexture *tex = [AZTexture textureFor:self
								 withIndex:tId
									  size:size
									 usage:flags];
	/*************************************************************************\
	|* If we have a valid texture resource, then store it
	\*************************************************************************/
	if (tex)
		_textures[tId] = tex;
	else
		tId = @(-1);

	/*************************************************************************\
	|* Create a copy pass to upload the cleared data to the texture
	\*************************************************************************/
	if (tId.integerValue > 0)
		{
		SDL_GPUCommandBuffer* cmds 	= SDL_AcquireGPUCommandBuffer(_gpu);
		SDL_GPUCopyPass* pass 		= SDL_BeginGPUCopyPass(cmds);
		SDL_GPUTextureTransferInfo info =
			{
			.transfer_buffer = upload,
			.offset = 0,
			// Zeroes out the rest
			};
		SDL_GPUTextureRegion region =
			{
			.texture = tex.texture,
			.w  	 = (int)tex.size.width,
			.h  	 = (int)tex.size.height,
			.d    	 = 1
			};

		SDL_UploadToGPUTexture(pass, &info, &region, NO);

		/*********************************************************************\
		|* Tell the GPU that's all we're copying, and to go ahead and start
		\*********************************************************************/
		SDL_EndGPUCopyPass(pass);
		SDL_SubmitGPUCommandBuffer(cmds);
		}

	/*************************************************************************\
	|* Housekeeping
	\*************************************************************************/
	SDL_ReleaseGPUTransferBuffer(_gpu, upload);

	/*************************************************************************\
	|* Return the reference to the texture in the local map
	\*************************************************************************/
	return tId.integerValue;
	}


- (NSInteger)createTextureOfSize:(NSSize)size
						  format:(int)format
					   withFlags:(int)flags
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (NSInteger)createTextureWithSurface:(nonnull struct SDL_Surface *)surface
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (NSInteger)currentFocus
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (void)drawColourR:(nonnull uint8_t *)r
				  g:(nonnull uint8_t *)g
				  b:(nonnull uint8_t *)b
				  a:(nonnull uint8_t *)a
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}


- (float)heightOfTexture:(NSInteger)refId
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (BOOL)lockFocusOn:(NSInteger)refId
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return NO;
	}


- (void)present
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}


- (int)presentationMode
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (NSSize)presentationSize
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return NSZeroSize;
	}


/*****************************************************************************\
|* Release a texture, removing it from the cache
\*****************************************************************************/
- (void) releaseTexture:(NSInteger)refId
	{
	AZTexture *texture = _textures[@(refId)];
	if (texture)
		[_textures removeObjectForKey:@(refId)];
	}


- (int)render:(int)num lines:(nonnull struct SDL_FPoint *)pts
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (int)renderFilledRect:(NSRect)r
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (int)renderLineFrom:(NSPoint)p1 to:(NSPoint)p2
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (int)renderLineFromX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;

	}


- (int)renderPointAt:(NSPoint)p
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (int)renderPointAtX:(int)x y:(int)y
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (int)renderRect:(NSRect)r
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (void)renderScaleX:(nonnull float *)xs y:(nonnull float *)ys
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}


- (nonnull SDL_Renderer *)renderer
	{
	NSLog(@"%@:%@ should not be called", self, NSStringFromSelector(_cmd));
	return NULL;
	}


- (nonnull NSString *)rendererName
	{
	return [NSString stringWithFormat:@"%s", SDL_GetGPUDeviceDriver(_gpu)];
	}


- (void)restoreFocus:(NSInteger)oldFocus
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}


- (NSRect)safeAreaForRendering
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return NSZeroRect;
	}


- (int)setBlendMode:(uint32_t)blendMode
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (void)setClip:(NSRect)clipRect
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}


- (int)setDrawColour:(nonnull AZColour *)colour
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (int)setDrawColourToRed:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (void)setPresentationSize:(NSSize)size mode:(NSInteger)mode
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}


- (void)setScaleX:(float)xs y:(float)ys
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}


- (int)setTexture:(NSInteger)refId blendMode:(uint32_t)blendMode
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (int)setTexture:(NSInteger)texId modR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (void)setViewport:(NSRect)viewport
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}


- (nullable struct SDL_Surface *)surfaceFor:(NSInteger)refId
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return NULL;
	}


- (void)syncToVsync:(BOOL)yn
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}


- (int)texture:(NSInteger)refId blendMode:(nonnull uint32_t *)blendMode
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (int)tileFrom:(NSInteger)textureId src:(NSRect)srcRect dst:(NSRect)dstRect
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (int)tileFrom:(NSInteger)textureId
			src:(NSRect)srcRect
		  scale:(float)scale
		    dst:(NSRect)dstRect
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (void)unlockFocus
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}


- (void)unsetClip
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}


- (NSRect)viewport
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return NSZeroRect;
	}


- (float)widthOfTexture:(NSInteger)refId
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}

// MARK: Private methods

/*****************************************************************************\
|* Create a transfer buffer of the correct size
\*****************************************************************************/
- (SDL_GPUTransferBuffer *) _uploadBufferOfSize:(NSSize)size
	{
	SDL_GPUTransferBufferCreateInfo info =
		{
		.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
		.size  = size.width * size.height * 4
		};

	return SDL_CreateGPUTransferBuffer(_gpu, &info);
	}




@end
