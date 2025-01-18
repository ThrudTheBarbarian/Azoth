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
#import "AZMatrix.h"
#import "AZPipelineTarget.h"
#import "AZRenderer3d.h"
#import "AZRenderCommand.h"
#import "AZRenderPipeline.h"
#import "AZRenderProperties.h"
#import "AZSampler.h"
#import "AZShader.h"
#import "AZTexture.h"
#import "AZTypes.h"
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

typedef struct
	{
	int pixelW;						// Pixels wide
	int pixelH;						// Pixels high
	NSRect view;					// Where to render to
	NSRect pixelView;				// Where to render to, in pixels
	NSRect clip;					// The clipping rect within viewport
	NSRect pixelClip;				// The clipping rect, in pixels
	BOOL doClip;					// Whether clipping is enabled
	NSPoint scale;					// Scaling factor
	NSPoint logicalScale;			// Logical scaling factor (!)
	NSPoint logicalOffset;			// Logical offset in x,y
	NSPoint currentScale;			// Just logicalScale * scale
	} AZViewState;

static const int _rectIndexOrder[] = { 0, 1, 2, 0, 2, 3 };

typedef struct GPU_ShaderUniformData
	{
    Float4x4 mvp;					// 16 floats
    SDL_FColor color;				// 4 floats
    float texture_size[2];			// 2 floats
	} GPU_ShaderUniformData;

typedef struct AZRenderData
	{
	AZShaders shaders;

	AZTexture *backbuffer;

    struct
		{
        SDL_GPUSwapchainComposition composition;
        SDL_GPUPresentMode presentMode;
		} swapchain;

    struct
		{
        SDL_GPUTransferBuffer *transferBuf;
        SDL_GPUBuffer *buffer;
        Uint32 bufferSize;
		} vertices;

    struct
		{
        SDL_GPURenderPass *renderPass;
        SDL_Texture *renderTarget;
        SDL_GPUCommandBuffer *commandBuffer;
        SDL_GPUColorTargetInfo colourAttachment;
        SDL_GPUViewport viewport;
        SDL_Rect scissor;
        SDL_FColor drawColour;
        bool scissorEnabled;
        bool scissorWasEnabled;
        GPU_ShaderUniformData shaderData;
		} state;

    AZSampler *samplers[2][2];
	} AZRenderData;

#define SAMPLER(address,scale) _renderData.samplers[scale][address-1]

/*****************************************************************************\
|* Predefined blend modes
\*****************************************************************************/
#define AZ_COMPOSE_BLENDMODE(srcColorFactor, dstColorFactor, colorOperation, \
                              srcAlphaFactor, dstAlphaFactor, alphaOperation) \
    (SDL_BlendMode)(((Uint32)(colorOperation) << 0) |                         \
                    ((Uint32)(srcColorFactor) << 4) |                         \
                    ((Uint32)(dstColorFactor) << 8) |                         \
                    ((Uint32)(alphaOperation) << 16) |                        \
                    ((Uint32)(srcAlphaFactor) << 20) |                        \
                    ((Uint32)(dstAlphaFactor) << 24))

#define AZ_BLENDMODE_NONE_FULL												\
    AZ_COMPOSE_BLENDMODE(SDL_BLENDFACTOR_ONE, 								\
						 SDL_BLENDFACTOR_ZERO,								\
						 SDL_BLENDOPERATION_ADD, 							\
                         SDL_BLENDFACTOR_ONE, 								\
						 SDL_BLENDFACTOR_ZERO, 								\
                         SDL_BLENDOPERATION_ADD)

#define AZ_BLENDMODE_BLEND_FULL                                                                                  \
    AZ_COMPOSE_BLENDMODE(SDL_BLENDFACTOR_SRC_ALPHA, 						\
						 SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA, 				\
						 SDL_BLENDOPERATION_ADD, 							\
						 SDL_BLENDFACTOR_ONE, 								\
						 SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA, 				\
						 SDL_BLENDOPERATION_ADD)

#define AZ_BLENDMODE_BLEND_PREMULTIPLIED_FULL                                                              \
    AZ_COMPOSE_BLENDMODE(SDL_BLENDFACTOR_ONE, 								\
						  SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA, 				\
						  SDL_BLENDOPERATION_ADD, 							\
                          SDL_BLENDFACTOR_ONE, 								\
                          SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA, 				\
                          SDL_BLENDOPERATION_ADD)

#define AZ_BLENDMODE_ADD_FULL                                          		\
    AZ_COMPOSE_BLENDMODE(SDL_BLENDFACTOR_SRC_ALPHA, 						\
						 SDL_BLENDFACTOR_ONE, 								\
						 SDL_BLENDOPERATION_ADD, 							\
                         SDL_BLENDFACTOR_ZERO, 								\
                         SDL_BLENDFACTOR_ONE, 								\
                         SDL_BLENDOPERATION_ADD)

#define AZ_BLENDMODE_ADD_PREMULTIPLIED_FULL                               	\
    AZ_COMPOSE_BLENDMODE(SDL_BLENDFACTOR_ONE,  								\
						 SDL_BLENDFACTOR_ONE, 								\
						 SDL_BLENDOPERATION_ADD, 							\
                         SDL_BLENDFACTOR_ZERO, 								\
                         SDL_BLENDFACTOR_ONE, 								\
                         SDL_BLENDOPERATION_ADD)

#define AZ_BLENDMODE_MOD_FULL                                            	\
    AZ_COMPOSE_BLENDMODE(SDL_BLENDFACTOR_ZERO, 								\
						 SDL_BLENDFACTOR_SRC_COLOR, 						\
						 SDL_BLENDOPERATION_ADD, 							\
                         SDL_BLENDFACTOR_ZERO, 								\
                         SDL_BLENDFACTOR_ONE, 								\
                         SDL_BLENDOPERATION_ADD)

#define AZ_BLENDMODE_MUL_FULL                                            	\
    AZ_COMPOSE_BLENDMODE(SDL_BLENDFACTOR_DST_COLOR, 						\
						 SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA, 				\
						 SDL_BLENDOPERATION_ADD, 							\
                         SDL_BLENDFACTOR_ZERO, 								\
                         SDL_BLENDFACTOR_ONE, 								\
                         SDL_BLENDOPERATION_ADD)


/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZRenderer3d()

// The texture map for handing out textures
@property(strong, nonatomic)
NSMutableDictionary<NSNumber *, AZTexture *> * 				textures;

// The SDL window we associate this renderer with
@property(assign, nonatomic) SDL_Window *					sdl;

// The AZWindow we associate this renderer with
@property(strong, nonatomic) AZWindow *						window;

// The GPU device
@property(assign, nonatomic) SDL_GPUDevice *				gpu;

// The sprite compute pipeline
@property(strong, nonatomic) AZComputePipeline *			computePipe;

// The sampler
@property(strong, nonatomic) AZSampler *					sampler;

// The target we're rendering onto, or nil for screen
@property(strong, nonatomic, nullable) AZTexture *			target;

// The current view state
@property(assign, nonatomic) AZViewState *					view;

// The main view state
@property(assign, nonatomic) AZViewState					mainView;

// The size of the eventual output window, in pixels
@property(assign, nonatomic) NSSize							pixelSize;

// Scaling for difference between pixels and logical size
@property(assign, nonatomic) NSPoint						dpiScale;

// SDR white point
@property(assign, nonatomic) float							sdrWhitePoint;

// HDR headroom above SDR
@property(assign, nonatomic) float							hdrHeadroom;

// Desired colour scaling
@property(assign, nonatomic) float							desiredColourScale;

// Colour scaling
@property(assign, nonatomic) float							colourScale;

// Is a viewport command already enqueued
@property(assign, nonatomic) BOOL							viewportQueued;

// Last viewport that was already enqueued
@property(assign, nonatomic) NSRect							lastQueuedViewport;

// Is a clipRect command already enqueued
@property(assign, nonatomic) BOOL							clipRectQueued;

// Is the last clip active or not
@property(assign, nonatomic) BOOL							lastQueuedDoClip;

// The last queued clip-rect
@property(assign, nonatomic) NSRect							lastQueuedClip;

// Is a colour command already enqueued
@property(assign, nonatomic) BOOL							colourQueued;

// Last queued colour
@property(assign, nonatomic) SDL_FColor						lastQueuedColour;

// The lock surrounding the command pool
@property(strong, nonatomic) NSLock *						poolLock;

// The pool of render commands that we draw from
@property(strong, nonatomic)
NSMutableArray<AZRenderCommand *> *							commandPool;

// The list of render commands that we have enqueued
@property(strong, nonatomic)
NSMutableArray<AZRenderCommand *> *							commandQ;

// Different ways to blend
@property(assign, nonatomic) SDL_BlendMode					blendModeValue;

// The amount of space used for vertices so far
@property(assign, nonatomic) NSInteger						vertexDataInUse;

// The amount of space allocated for vertices so far
@property(assign, nonatomic) NSInteger						vertexDataSize;

// The actual vertex data
@property(assign, nonatomic) void *							vertexData;

// The logical presentation mode
@property(assign, nonatomic)
SDL_RendererLogicalPresentation								logicalPresentMode;

// The logical size
@property(assign, nonatomic) NSSize							logicalSize;

// The logical source rectangle
@property(assign, nonatomic) NSRect							logicalSrcRect;

// The logical destination rectangle
@property(assign, nonatomic) NSRect							logicalDstRect;

// Incremented once per flush of the render queue
@property(assign, nonatomic) NSInteger						cmdGeneration;

// Keep track of the rendering state etc.
@property(assign, nonatomic) AZRenderData					renderData;

// Properties we set on this renderer
@property(strong, nonatomic) NSMutableDictionary *			properties;
@end


/*****************************************************************************\
|* File-private entities
\*****************************************************************************/
static NSInteger 		_textureId;
static SDL_SpinLock 	_textureLock;

@implementation AZRenderer3d
/*****************************************************************************\
|* Initialisation. We don't do all the initialisation here, because some
|* things depend on the window and GPU device. Look in _initialiseGPU for
|* more, later, initialisation.
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		/*********************************************************************\
		|* Set the properties dictionary up
		\*********************************************************************/
		_properties 	= [NSMutableDictionary new];
		_properties[AZRendererValid] = @(YES);

		/*********************************************************************\
		|* Prepare to store the textures
		\*********************************************************************/
		_textures 	= [NSMutableDictionary new];

		/*********************************************************************\
		|* Default clear colour is in fact ... clear
		\*********************************************************************/
		_clearColour = AZColour.clear;

		/*********************************************************************\
		|* Default draw colour is white
		\*********************************************************************/
		_colour = AZColour.white;

		/*********************************************************************\
		|* Default render target is the screen, no logical presentation
		\*********************************************************************/
		_target 			= nil;
		_logicalPresentMode	= SDL_LOGICAL_PRESENTATION_DISABLED;

		/*********************************************************************\
		|* We use line-drawing by default for rendering lines
		\*********************************************************************/
		_lineMethod 		= AZRenderLineMethodLines;

		/*********************************************************************\
		|* Colour scaling
		\*********************************************************************/
		_colourScale 		= 1.f;
		_desiredColourScale = 1.f;

		/*********************************************************************\
		|* SDR/HDR settings
		\*********************************************************************/
		_sdrWhitePoint 		= 1.f;
		_hdrHeadroom 		= 1.f;
		_outputColourspace 	= SDL_COLORSPACE_SRGB;

		/*********************************************************************\
		|* Create the command pool and queue
		\*********************************************************************/
		_commandQ 			= [NSMutableArray new];
		_commandPool 		= [NSMutableArray new];
		_poolLock 			= [NSLock new];

		/*********************************************************************\
		|* Initialise the vertex pool
		\*********************************************************************/
		_vertexData			= NULL;
		_vertexDataSize		= 0;
		_vertexDataInUse	= 0;

		/*********************************************************************\
		|* Default value for forcing a vsync-based presentation mode
		\*********************************************************************/
		_useVsyncForPresent	= NO;
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

	if (_computePipe.pipeline)
		SDL_ReleaseGPUComputePipeline(_gpu,_computePipe.pipeline);
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

	/*************************************************************************\
    |* Initialise
    \*************************************************************************/
	const char *hint = SDL_GetHint(SDL_HINT_RENDER_VSYNC);
	if (hint && *hint)
		_properties[AZRendererVSync] = @(YES);

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
|* Initialise the GPU and its related things. Called once a window has been
|* created
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
    |* Create the compute pipeline
    \*************************************************************************/
//	_computePipe = [AZComputePipeline pipelineNamed:@"sprite.comp"
//								   storageBuffersRO:1
//								   storageBuffersRW:1
//										    threads:AZMakeThreadSize(64,1,1)];
//
//	if (![_computePipe buildWithDevice:self])
//		{
//		SDL_Log("Failed to create compute pipeline");
//		return NO;
//		}

	/*************************************************************************\
    |* Load the shaders and samplers
    \*************************************************************************/
	[self _loadShaders];
	[self _createSamplers];

	/*************************************************************************\
    |* ... and initialise the vertex buffer
    \*************************************************************************/
	if (![self _initialiseVertexBuffer:1<<16])
		{
		SDL_Log("Cannot initialise the vertex/transfer buffers");
		return NO;
		}

	/*************************************************************************\
    |* ... and set up the swapchain info
    \*************************************************************************/
	_renderData.swapchain.composition = SDL_GPU_SWAPCHAINCOMPOSITION_SDR;
	_renderData.swapchain.presentMode = SDL_GPU_PRESENTMODE_VSYNC;

	/*************************************************************************\
    |* ... and choose how to handle -present
    \*************************************************************************/
	[self _choosePresentationMode:&(_renderData.swapchain.presentMode)];

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
	if (!SDL_SetWindowPosition(_sdl, x, y))
		return NO;

	/*************************************************************************\
    |* Initialise the main view
    \*************************************************************************/
	_mainView.view.size.width	= -1;
	_mainView.view.size.height	= -1;
	_mainView.scale 			= (NSPoint){1.f, 1.f};
	_mainView.logicalScale 		= _mainView.scale;
	_mainView.currentScale 		= _mainView.scale;
	_dpiScale					= _mainView.scale;
	_view						= &_mainView;

	[self _updatePixelViewport:&_mainView];
	[self _updatePixelClipRect:&_mainView];
	[self _updateMainViewDimensions];

	_properties[AZRendererWindow] 		= _window;
	_properties[AZRendererColourspace]	= @(_outputColourspace);
	_properties[AZRendererRenderer] 	= self;


	_cmdGeneration	= 1;
	_lineMethod		= [self _renderLineMethod];

	[self _updateHdrProperties];

	SDL_ClearError();
	return YES;
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

/*****************************************************************************\
|* Clear the rendering target
\*****************************************************************************/
- (BOOL)clear
	{
	/*************************************************************************\
	|* Fetch a command buffer
	\*************************************************************************/
	SDL_GPUCommandBuffer* cmds = SDL_AcquireGPUCommandBuffer(_gpu);

	/*************************************************************************\
	|* Either use the target texture, or the screen if no target currently set
	\*************************************************************************/
	SDL_GPUTexture *texture = nil;
	if (_target)
		texture = _target.texture;
	else
		{
		if (!SDL_WaitAndAcquireGPUSwapchainTexture(cmds, 	// Command buffer
												   _sdl,   	// window
												   &texture,// storage
												   NULL, 	// width, if need
												   NULL))	// height, if need
			{
			SDL_Log("WaitAndAcquireGPUSwapchainTexture failed: %s", SDL_GetError());
			return NO;
			}
		}

	/*************************************************************************\
	|* Make sure we have a texture and enqueue a command to clear it
	\*************************************************************************/
	if (texture)
		{
		SDL_GPUColorTargetInfo info = { 0 };
		info.texture 		= texture;
		info.clear_color 	= self.clearColour.sdlColour;
		info.load_op 		= SDL_GPU_LOADOP_CLEAR;
		info.store_op 		= SDL_GPU_STOREOP_STORE;

		SDL_GPURenderPass* pass = SDL_BeginGPURenderPass(cmds, &info, 1, NULL);
		SDL_EndGPURenderPass(pass);
		return YES;
		}

	NSString *msg = [NSString stringWithFormat:@"Cannot clear %@ %@",
					(_target == nil) ? @"screen" : @"texture",
					 (_target == nil) ? @"" : _target.index];

	SDL_Log("%s", msg.UTF8String);
	return NO;
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


/*****************************************************************************\
|* Create a texture from an existing surface. We assume RGBA8888 format for the
|* surface. This needs to:
|*
|*  - Allocate a texture-id for the new texture
|*  - create a transfer buffer and map it so the CPU can see it
|*  - fill the transfer buffer with the texture data
|*  - create a GPU texture of the same size
|*  - start a copy pass and upload the data to the texture
|*  - finish the copy pass and return the texture-id to the caller
|*
\*****************************************************************************/
- (NSInteger)createTextureWithSurface:(nonnull struct SDL_Surface *)surface
	{
	/*************************************************************************\
	|* Get a new unique texture id
	\*************************************************************************/
	NSNumber *tId = self.nextTextureId;

	/*************************************************************************\
	|* Create a transfer buffer of the correct size
	\*************************************************************************/
	NSSize size = NSMakeSize(surface->w, surface->h);
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
	|* Copy the data from the RGBA8888 surface to the texture
	\*************************************************************************/
	memcpy(cpuPtr, surface->pixels, surface->w * surface->h * 4);


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


/*****************************************************************************\
|* Return the current focus, or -1 if it's the screen
\*****************************************************************************/
- (NSInteger)currentFocus
	{
	if (_target)
		return _target.index.integerValue;
	return -1;
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


/*****************************************************************************\
|* Lock focus on a given texture
\*****************************************************************************/
- (BOOL)lockFocusOn:(NSInteger)refId
	{
	AZTexture *target = _textures[@(refId)];
	if (target)
		{
		_target = target;
		return YES;
		}
	return NO;
	}


/*****************************************************************************\
|* It's time. Update the screen
\*****************************************************************************/
- (void) present
	{
    BOOL presented = YES;

    AZTexture *target = _target;
    if (target)
       	_target = nil;

	[self _renderLogicalPresentation];

	[self _flushRenderCommands];

    if (!renderer->RenderPresent(renderer)) {
        presented = false;
    }

    if (target)
		_target = target;
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


/*****************************************************************************\
|* Render a filled rectangle
\*****************************************************************************/
// SDL_RenderFillRect
- (BOOL) renderFilledRect:(NSRect)r
	{
	// if r is zeroRect, fill the entire current rendering target
	if (NSEqualRects(r, NSZeroRect))
		r = [self viewportSize];

	return [self renderFilledRects:&r count:1];
	}

/*****************************************************************************\
|* Render many filled rectangles
\*****************************************************************************/
- (BOOL) renderFilledRects:(NSRect *)rects count:(int)count
	{
	/*************************************************************************\
	|* Sanity checks
	\*************************************************************************/
    if (!rects)
        return SDL_InvalidParamError("renderFilledRects:count: nil rect ptr");

    if (count < 1)
        return true;

	BOOL isStack;
    NSRect *frects = AZSmallAlloc(NSRect, count, &isStack);
    if (!frects)
        return SDL_OutOfMemory();

	/*************************************************************************\
	|* Scale the rects
	\*************************************************************************/
    const float sx = _view->currentScale.x;
    const float sy = _view->currentScale.y;
    for (NSInteger i = 0; i < count; ++i)
		{
        frects[i].origin.x 		= rects[i].origin.x * sx;
        frects[i].origin.y 		= rects[i].origin.y * sy;
		frects[i].size.width 	= rects[i].size.width * sx;
		frects[i].size.height 	= rects[i].size.height * sy;
		}

	/*************************************************************************\
	|* Enqueue a command to fill the rects
	\*************************************************************************/
	BOOL result = [self _queueCmdFilledRects:frects count:count];

    AZSmallFree(frects, isStack);

    return result;
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


/*****************************************************************************\
|* Swap focus to a new one
\*****************************************************************************/
- (void)restoreFocus:(NSInteger)oldFocus
	{
	if (oldFocus < 0)
		[self unlockFocus];
	else
		[self lockFocusOn:oldFocus];
	}


- (NSRect)safeAreaForRendering
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return NSZeroRect;
	}


/*****************************************************************************\
|* Set the blend mode
\*****************************************************************************/
// SDL_SetRenderDrawBlendMode
- (BOOL) setBlendMode:(SDL_BlendMode)blendMode
	{
    if (blendMode == SDL_BLENDMODE_INVALID)
        return SDL_InvalidParamError("blendMode");

    if (![self _isSupportedBlendMode:blendMode])
        return SDL_Unsupported();

	_blendModeValue = blendMode;
	return YES;
	}


- (void) setClip:(NSRect)clipRect
	{
	// FIXME: no need for the indirection
	[self setClipRect:clipRect];
	}


/*****************************************************************************\
|* Set the draw colour
\*****************************************************************************/
- (int)setDrawColour:(nonnull AZColour *)colour
	{
	_colour = colour;
	return YES;
	}


- (int)setDrawColourToRed:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	_colour = [AZColour colourWithByteR:r g:g b:b a:a];
	return YES;
	}


- (void)setPresentationSize:(NSSize)size mode:(NSInteger)mode
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	}



- (int)setTexture:(NSInteger)refId blendMode:(SDL_BlendMode)blendMode
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


- (int)setTexture:(NSInteger)texId modR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
	}


// SDL_SetRenderViewport
- (BOOL)setViewport:(NSRect)rect
	{
	if (!NSEqualRects(rect, NSZeroRect))
		{
        if ((NSWidth(rect) < 0) || (NSHeight(rect) < 0))
            return SDL_SetError("viewport rect has a negative size");
		_view->view = rect;
		}
	else
		_view->view = NSMakeRect(0,0,-1,-1);

	[self _updatePixelViewport:_view];
    return [self _queueCmdSetViewport];
	}

// SDL_SetRenderClipRect
- (BOOL) setClipRect:(NSRect)rect
	{
	BOOL isZero = NSEqualRects(rect, NSZeroRect);
    if ((!isZero) && (NSWidth(rect) >= 0) && (NSHeight(rect) >= 0))
		{
        _view->doClip 	= YES;
		_view->clip		= rect;
		}
	else
		{
        _view->doClip 	= NO;
		_view->clip		= NSZeroRect;
		}
	[self _updatePixelClipRect:_view];
	return [self _queueCmdSetClipRect];
	}

// SDL_SetRenderScale
- (BOOL) setScaleX:(float)sx y:(float)sy
	{
    bool result = true;

    if ((_view->scale.x == sx) && (_view->scale.y == sy))
        return YES;

    _view->scale.x = sx;
    _view->scale.y = sy;
    _view->currentScale.x = sx * _view->logicalScale.x;
    _view->currentScale.y = sy * _view->logicalScale.y;

	[self _updatePixelViewport:_view];
	[self _updatePixelClipRect:_view];

    // The scale affects the existing viewport and clip rectangle
	result &= [self _queueCmdSetViewport];
	result &= [self _queueCmdSetClipRect];

    return result;
	}

/*****************************************************************************\
|* Render any letterboxes around the logical view
\*****************************************************************************/
// SDL_RenderLogicalBorders
- (void) _renderLogicalBorders
	{
    NSRect dst = _logicalDstRect;

    if (dst.origin.x > 0.f || dst.origin.y > 0.f)
		{
        SDL_BlendMode savedBlend 	= _blendModeValue;
		AZColour *savedColour 		= _colour.copy;

		[self setBlendMode:SDL_BLENDMODE_NONE];
		_colour = AZColour.black;

        if (dst.origin.x > 0.f)
			{
			NSRect r = NSMakeRect(0.f, 0.f, NSMinX(dst), _view->pixelH);
			[self renderFilledRect:r];

            r.origin.x 		= NSMaxX(dst);
            r.size.width	= _view->pixelW - r.origin.x;
			[self renderFilledRect:r];
			}

        if (dst.origin.y > 0.f)
			{
			NSRect r = NSMakeRect(0.f, 0.f, _view->pixelW, dst.origin.y);
			[self renderFilledRect:r];

			r.origin.y 		= NSMaxY(dst);
			r.size.height	= _view->pixelH - r.origin.y;
			[self renderFilledRect:r];
			}

		[self setBlendMode:savedBlend];
		_colour = savedColour;
		}
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


- (int)texture:(NSInteger)refId blendMode:(nonnull SDL_BlendMode *)blendMode
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


/*****************************************************************************\
|* UnLock focus, target the screen
\*****************************************************************************/
- (void)unlockFocus
	{
	_target = nil;
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


/*****************************************************************************\
|* Return the viewport rect (ie the rect that covers the current target)
|* (corresponds to GetRenderViewportSize)
\*****************************************************************************/
- (NSRect) viewportSize
	{
	float w,h;

    if (_view->view.size.width >= 0)
        w = _view->view.size.width;
    else
        w = _view->pixelW / _view->currentScale.x;

    if (_view->view.size.height >= 0)
        h = _view->view.size.height;
    else
        h = _view->pixelH / _view->currentScale.y;

	return NSMakeRect(0.f, 0.f, w, h);
	}


/*****************************************************************************\
|* set the logical presentation size and mode
\*****************************************************************************/
- (BOOL) setLogicalPresentationWidth:(int)w
							  height:(int)h
							    mode:(SDL_RendererLogicalPresentation)mode
	{
    _logicalPresentMode	= mode;
	_logicalSize.width 	= w;
	_logicalSize.height = h;

	[self _updateLogicalPresentation];
    return YES;
	}


// MARK: Blending

/*****************************************************************************\
|* Do we support this blend mode or not
\*****************************************************************************/
- (BOOL) _isSupportedBlendMode:(SDL_BlendMode)blendMode
	{
    switch (blendMode)
		{
		// These are required to be supported by all renderers
		case SDL_BLENDMODE_NONE:
		case SDL_BLENDMODE_BLEND:
		case SDL_BLENDMODE_BLEND_PREMULTIPLIED:
		case SDL_BLENDMODE_ADD:
		case SDL_BLENDMODE_ADD_PREMULTIPLIED:
		case SDL_BLENDMODE_MOD:
		case SDL_BLENDMODE_MUL:
        return YES;

		default:
			break;
		}

	SDL_BlendFactor srcColorFactor 	= [self blendModeSrcColourFactor:blendMode];
	SDL_BlendFactor srcAlphaFactor 	= [self blendModeSrcAlphaFactor:blendMode];
	SDL_BlendOperation colourOp 	= [self blendModeColourOperation:blendMode];
	SDL_BlendFactor dstColourFactor = [self blendModeDstColourFactor:blendMode];
	SDL_BlendFactor dstAlphaFactor 	= [self blendModeDstAlphaFactor:blendMode];
	SDL_BlendOperation alphaOp 		= [self blendModeAlphaOperation:blendMode];

    if (AZConvertBlendFactor(srcColorFactor) == SDL_GPU_BLENDFACTOR_INVALID  ||
        AZConvertBlendFactor(srcAlphaFactor) == SDL_GPU_BLENDFACTOR_INVALID  ||
        AZConvertBlendOperation(colourOp) == SDL_GPU_BLENDOP_INVALID 		 ||
        AZConvertBlendFactor(dstColourFactor) == SDL_GPU_BLENDFACTOR_INVALID ||
        AZConvertBlendFactor(dstAlphaFactor) == SDL_GPU_BLENDFACTOR_INVALID  ||
        AZConvertBlendOperation(alphaOp) == SDL_GPU_BLENDOP_INVALID)
        return NO;

	return YES;
	}

/*****************************************************************************\
|* Construct the long form of the blend mode
\*****************************************************************************/
- (SDL_BlendMode) _getLongBlendMode:(SDL_BlendMode)blendMode
	{
    if (blendMode == SDL_BLENDMODE_NONE)
        return AZ_BLENDMODE_NONE_FULL;

    if (blendMode == SDL_BLENDMODE_BLEND)
        return AZ_BLENDMODE_BLEND_FULL;

    if (blendMode == SDL_BLENDMODE_BLEND_PREMULTIPLIED)
        return AZ_BLENDMODE_BLEND_PREMULTIPLIED_FULL;

    if (blendMode == SDL_BLENDMODE_ADD)
        return AZ_BLENDMODE_ADD_FULL;

    if (blendMode == SDL_BLENDMODE_ADD_PREMULTIPLIED)
        return AZ_BLENDMODE_ADD_PREMULTIPLIED_FULL;

    if (blendMode == SDL_BLENDMODE_MOD)
        return AZ_BLENDMODE_MOD_FULL;

    if (blendMode == SDL_BLENDMODE_MUL)
        return AZ_BLENDMODE_MUL_FULL;

    return blendMode;
	}

/*****************************************************************************\
|* Extract various parts of the blend mode
\*****************************************************************************/

- (SDL_BlendFactor) blendModeSrcColourFactor:(SDL_BlendMode)blendMode
	{
    blendMode = [self _getLongBlendMode:blendMode];
    return (SDL_BlendFactor)(((Uint32)blendMode >> 4) & 0xF);
	}

- (SDL_BlendFactor) blendModeDstColourFactor:(SDL_BlendMode)blendMode
	{
    blendMode = [self _getLongBlendMode:blendMode];
    return (SDL_BlendFactor)(((Uint32)blendMode >> 8) & 0xF);
	}

- (SDL_BlendOperation) blendModeColourOperation:(SDL_BlendMode)blendMode
	{
    blendMode = [self _getLongBlendMode:blendMode];
    return (SDL_BlendOperation)(((Uint32)blendMode >> 0) & 0xF);
	}

- (SDL_BlendFactor) blendModeSrcAlphaFactor:(SDL_BlendMode)blendMode
	{
    blendMode = [self _getLongBlendMode:blendMode];
    return (SDL_BlendFactor)(((Uint32)blendMode >> 20) & 0xF);
	}

- (SDL_BlendFactor) blendModeDstAlphaFactor:(SDL_BlendMode)blendMode
	{
    blendMode = [self _getLongBlendMode:blendMode];
    return (SDL_BlendFactor)(((Uint32)blendMode >> 24) & 0xF);
	}

- (SDL_BlendOperation) blendModeAlphaOperation:(SDL_BlendMode)blendMode
	{
    blendMode = [self _getLongBlendMode:blendMode];
    return (SDL_BlendOperation)(((Uint32)blendMode >> 16) & 0xF);
	}


// MARK: Private methods

/*****************************************************************************\
|* Create the samplers
\*****************************************************************************/
- (void) _choosePresentationMode:(out SDL_GPUPresentMode*)presentMode
	{
    SDL_GPUPresentMode mode;

    if (!_useVsyncForPresent)
		{
        mode = SDL_GPU_PRESENTMODE_MAILBOX;

		if (!SDL_WindowSupportsGPUPresentMode(_gpu, _window.window, mode))
			{
            mode = SDL_GPU_PRESENTMODE_IMMEDIATE;
            if (!SDL_WindowSupportsGPUPresentMode(_gpu, _window.window, mode))
                mode = SDL_GPU_PRESENTMODE_VSYNC;

			}
		}
    else
        mode = SDL_GPU_PRESENTMODE_VSYNC;

    *presentMode = mode;
	}

/*****************************************************************************\
|* Create the samplers
\*****************************************************************************/
- (BOOL) _initialiseVertexBuffer:(Uint32)size
	{
    SDL_GPUBufferCreateInfo bci;
    SDL_zero(bci);
    bci.size = size;
    bci.usage = SDL_GPU_BUFFERUSAGE_VERTEX;

    _renderData.vertices.buffer = SDL_CreateGPUBuffer(_gpu, &bci);

    if (!_renderData.vertices.buffer)
        return NO;

    SDL_GPUTransferBufferCreateInfo tbci;
    SDL_zero(tbci);
    tbci.size = size;
    tbci.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;

    _renderData.vertices.transferBuf = SDL_CreateGPUTransferBuffer(_gpu, &tbci);

    if (!_renderData.vertices.transferBuf)
        return NO;

    return YES;
	}


/*****************************************************************************\
|* Create the samplers
\*****************************************************************************/
- (void) _createSamplers
	{
	struct
		{
		AZTextureAddressMode textureAddressMode;
		SDL_ScaleMode scaleMode;

		SDL_GPUSamplerAddressMode samplerMode;
		SDL_GPUFilter filter;
		SDL_GPUSamplerMipmapMode mipmapMode;
		Uint32 anisotropy;
		}
    cfg[] = {
		{AZTextureAddressClamp,
		 SDL_SCALEMODE_NEAREST,
		 SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
		 SDL_GPU_FILTER_NEAREST,
		 SDL_GPU_SAMPLERMIPMAPMODE_NEAREST,
		 0 },

		{AZTextureAddressClamp,
		 SDL_SCALEMODE_LINEAR,
		 SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
		 SDL_GPU_FILTER_LINEAR,
		 SDL_GPU_SAMPLERMIPMAPMODE_LINEAR,
		 0 },

		{AZTextureAddressClamp,
		 SDL_SCALEMODE_NEAREST,
		 SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
		 SDL_GPU_FILTER_NEAREST,
		 SDL_GPU_SAMPLERMIPMAPMODE_NEAREST,
		 0 },

		{AZTextureAddressClamp,
		 SDL_SCALEMODE_LINEAR,
		 SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
		 SDL_GPU_FILTER_LINEAR,
		 SDL_GPU_SAMPLERMIPMAPMODE_LINEAR,
		 0 }
		};

    for (Uint32 i = 0; i < SDL_arraysize(cfg); ++i)
		{
		AZSampler *sampler = [AZSampler withMinFilter:cfg[i].filter
											magFilter:cfg[i].filter
										   mipMapMode:cfg[i].mipmapMode
										  addressMode:cfg[i].samplerMode];
		sampler.maxAnisotropy = cfg[i].anisotropy;
		sampler.enableAnisotropy = (sampler.maxAnisotropy > 0);
		[sampler buildWithDevice:self];
		SAMPLER(cfg[i].textureAddressMode,cfg[i].scaleMode) = sampler;
		}
	}

/*****************************************************************************\
|* Load up the shaders
\*****************************************************************************/
- (void) _loadShaders
	{
	NSDictionary<NSNumber *, NSArray *> *fragMap =
		@{
		@(AZFragShaderColour) 		: @[@0, @"colour.frag"],
		@(AZFragShaderTextureRGB)	: @[@1, @"texture_rgb.frag"],
		@(AZFragShaderTextureRGBA)	: @[@1, @"texture_rgba.frag"]
		};

	NSDictionary<NSNumber *, NSString *> *vertMap =
		@{
		@(AZVertShaderLinePoint) 	: @"linepoint.vert",
		@(AZVertShaderTriColour)	: @"tri_color.vert",
		@(AZVertShaderTriTexture)	: @"tri_texture.vert"
		};

	/*************************************************************************\
	|* Load up the fragment shaders
	\*************************************************************************/
	for (NSNumber *identifier in fragMap)
		{
		NSArray *info	 = fragMap[identifier];
		int samplers	 = ((NSNumber *)info[0]).intValue;
		NSString *name 	 = info[1];
		AZShader *shader = [AZShader shaderWithRenderer:self
												   name:name
											   samplers:samplers];
		if (shader)
			_renderData.shaders.fragShaders[identifier.intValue] = shader;
		else
			{
			NSString *msg = [NSString stringWithFormat:
							@"Couldn't load fragment shader '%@'", name];
			SDL_Log("%s", msg.UTF8String);
			}
		}


	/*************************************************************************\
	|* Load up the vertex shaders
	\*************************************************************************/
	for (NSNumber *identifier in vertMap)
		{
		NSString *name = vertMap[identifier];
		AZShader *shader = [AZShader shaderWithRenderer:self
												   name:name
											   samplers:0
										 uniformBuffers:1];
		if (shader)
			_renderData.shaders.vertShaders[identifier.intValue] = shader;
		else
			{
			NSString *msg = [NSString stringWithFormat:
							@"Couldn't load vertex shader '%@'", name];
			SDL_Log("%s", msg.UTF8String);
			}
		}

	}

/*****************************************************************************\
|* Decide on the line-rendering method
\*****************************************************************************/
- (AZRenderLineMethod) _renderLineMethod
	{
    const char *hint = SDL_GetHint(SDL_HINT_RENDER_LINE_METHOD);
    int method 		 = (hint) ? SDL_atoi(hint) : 0;

    switch (method)
		{
		case 1:
			return AZRenderLineMethodPoints;
		case 2:
			return AZRenderLineMethodLines;
		case 3:
			return AZRenderLineMethodGeometry;
		default:
			return AZRenderLineMethodPoints;
		}
	}

/*****************************************************************************\
|* Cope with rendering using an extended dynamic range
\*****************************************************************************/
- (void) _updateHdrProperties
	{
	SDL_PropertiesID windowProps = SDL_GetWindowProperties(_window.window);
    if (!windowProps)
        return;

    if (_outputColourspace == SDL_COLORSPACE_SRGB_LINEAR)
		{
        _sdrWhitePoint 	= SDL_GetFloatProperty(windowProps,
								SDL_PROP_WINDOW_SDR_WHITE_LEVEL_FLOAT, 1.0f);
        _hdrHeadroom 	= SDL_GetFloatProperty(windowProps,
								SDL_PROP_WINDOW_HDR_HEADROOM_FLOAT, 1.0f);
		}
	else
		{
        _sdrWhitePoint = 1.0f;
        _hdrHeadroom = 1.0f;
		}

	_properties[AZRendererHdrEnabled] 	= @(_hdrHeadroom > 1.0f);
	_properties[AZRendererWhitePoint] 	= @(_sdrWhitePoint);
	_properties[AZRendererHdrHeadroom] 	= @(_hdrHeadroom);

	[self _updateColourScale];
	}

/*****************************************************************************\
|* Update the colour scaling based on the colourspace
\*****************************************************************************/
- (void) _updateColourScale
	{
    float sdrWhitePoint = (_target)
						? _target.sdrWhitePoint
						: _sdrWhitePoint;

    _colourScale 		= _desiredColourScale * sdrWhitePoint;
	}

/*****************************************************************************\
|* Update the logical presentation
\*****************************************************************************/
- (void) _updateLogicalPresentation
	{
    if (_logicalPresentMode == SDL_LOGICAL_PRESENTATION_DISABLED)
		{
        _mainView.logicalOffset.x = _mainView.logicalOffset.y = 0.0f;
        _mainView.logicalScale.x  = _mainView.logicalScale.y  = 1.0f;

        // skip the multiplications against 1.0f.
        _mainView.currentScale.x  = _mainView.scale.x;
        _mainView.currentScale.y  = _mainView.scale.y;

		[self _updateMainViewDimensions];
		[self _updatePixelClipRect:&_mainView];

		// All done!
		return;
		}

	NSSize size 			= [self _getOutputSize];
	NSSize lSize			= _logicalSize;
    const float wantAspect 	= lSize.width / lSize.height;
	const float realAspect 	= size.width / size.height;
	BOOL close				= SDL_fabsf(wantAspect - realAspect) < 0.0001f;

	_logicalSrcRect			= NSZeroRect;
	_logicalSrcRect.size	= lSize;

    if (_logicalPresentMode == SDL_LOGICAL_PRESENTATION_INTEGER_SCALE)
		{
		// This an integer division!
        float scale 	= (wantAspect > realAspect)
						? (float)((int)size.width / (int)lSize.width)
						: (float)((int)size.height / (int)lSize.height);
		scale 			= (scale < 1.f) ? 1.f : scale;

        const float W 	= SDL_floorf(lSize.width * scale);
        const float X 	= (size.width - W) / 2.f;
        const float H 	= SDL_floorf(lSize.height * scale);
        const float Y 	= (size.height - H) / 2.f;

		_logicalDstRect = NSMakeRect(X,Y,W,H);
		}

	else if (_logicalPresentMode == SDL_LOGICAL_PRESENTATION_STRETCH || close)
		{
		_logicalDstRect = NSMakeRect(0.f, 0.f, size.width, size.height);
		}
	else if (wantAspect > realAspect)
		{
        if (_logicalPresentMode == SDL_LOGICAL_PRESENTATION_LETTERBOX)
			{
            // We want a wider aspect ratio than is available - letterbox it
            const float scale 	= size.width / lSize.width;
			const float W 		= size.width;
			const float X 		= 0.f;
			const float H 		= SDL_floorf(lSize.height * scale);
			const float Y 		= (size.height - H) / 2.f;
			_logicalDstRect 	= NSMakeRect(X,Y,W,H);
        }
		else
			{
			// _logicalPresentMode == SDL_LOGICAL_PRESENTATION_OVERSCAN
			// We want a wider aspect ratio than is available - zoom so logical
			// height matches the real height and  width will grow offscreen
            const float scale 	= size.height / lSize.height;
			const float Y 		= 0.f;
			const float H 		= size.height;
			const float W 		= SDL_floorf(lSize.width * scale);
			const float X 		= (size.width - W) / 2.f;
			_logicalDstRect 	= NSMakeRect(X,Y,W,H);
			}
		}
	else
		{
        if (_logicalPresentMode == SDL_LOGICAL_PRESENTATION_LETTERBOX)
			{
            // We want a narrower aspect ratio than is available - use side-bars
            const float scale 	= size.height / lSize.height;
			const float Y 		= 0.f;
			const float H 		= size.height;
			const float W 		= SDL_floorf(lSize.width * scale);
			const float X 		= (size.width - W) / 2.f;
			_logicalDstRect 	= NSMakeRect(X,Y,W,H);
			}
		else
			{
 			// _logicalPresentMode == SDL_LOGICAL_PRESENTATION_OVERSCAN
			// We want a narrower aspect ratio than is available - zoom so
			// logical width matches the real width, height will grow offscreen
            const float scale 	= size.width / lSize.width;
			const float X 		= 0.f;
			const float W 		= size.width;
			const float H 		= SDL_floorf(lSize.height * scale);
			const float Y 		= (size.height - H) / 2.f;
			_logicalDstRect 	= NSMakeRect(X,Y,W,H);
			}
		}

    _mainView.logicalScale.x  = (lSize.width != 0.0f)
							  ? _logicalDstRect.size.width / lSize.width
							  : 0.0f;
	_mainView.logicalScale.y  = (lSize.height != 0.0f)
							  ? _logicalDstRect.size.height / lSize.height
							  : 0.0f;
    _mainView.currentScale.x  = _mainView.scale.x * _mainView.logicalScale.x;
    _mainView.currentScale.y  = _mainView.scale.y * _mainView.logicalScale.y;
    _mainView.logicalOffset.x = _logicalDstRect.origin.x;
    _mainView.logicalOffset.y = _logicalDstRect.origin.y;

	[self _updateMainViewDimensions];

    _mainView.pixelW = (int) _logicalDstRect.size.width;
    _mainView.pixelH = (int) _logicalDstRect.size.height;

	[self _updatePixelViewport:&_mainView];
	[self _updatePixelClipRect:&_mainView];
	}


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


/*****************************************************************************\
|* Work out the pixel-based viewport from the viewport
\*****************************************************************************/
- (void) _updatePixelViewport:(AZViewState *)vs
	{
    vs->pixelView.origin.x = vs->view.origin.x * vs->currentScale.x
						   + vs->logicalOffset.x;
	vs->pixelView.origin.x = SDL_floorf(vs->pixelView.origin.x);

    vs->pixelView.origin.y = vs->view.origin.y * vs->currentScale.y
						   + vs->logicalOffset.y;
	vs->pixelView.origin.x = SDL_floorf(vs->pixelView.origin.x);

    if (vs->view.size.width >= 0)
        {
        vs->pixelView.size.width = vs->view.size.width * vs->currentScale.x;
		vs->pixelView.size.width = SDL_ceilf(vs->pixelView.size.width);
		}
	else
		vs->pixelView.size.width = vs->pixelW;

    if (vs->view.size.height >= 0)
        {
        vs->pixelView.size.height = vs->view.size.height * vs->currentScale.y;
		vs->pixelView.size.height = SDL_ceilf(vs->pixelView.size.height);
		}
	else
		vs->pixelView.size.height = vs->pixelH;
	}

/*****************************************************************************\
|* Work out the pixel-based clipping rectangle from the viewport
\*****************************************************************************/
- (void) _updatePixelClipRect:(AZViewState *)vs
	{
    const float sx = vs->currentScale.x;
    const float sy = vs->currentScale.y;

    vs->pixelClip.origin.x 	  = vs->clip.origin.x * sx + vs->logicalOffset.x;
	vs->pixelClip.origin.x 	  = SDL_floorf(vs->pixelClip.origin.x);

    vs->pixelClip.origin.y 	  = vs->clip.origin.y * sy + vs->logicalOffset.y;
	vs->pixelClip.origin.y 	  = SDL_floorf(vs->pixelClip.origin.y);

    vs->pixelClip.size.width  = SDL_ceilf(vs->clip.size.width * sx);
    vs->pixelClip.size.height = SDL_ceilf(vs->clip.size.height * sy);
	}

/*****************************************************************************\
|* Get the output size, as in the size of the window on-screen, not the size
|* of a render-texture.
\*****************************************************************************/
- (NSSize) _getOutputSize
	{
	int w,h;
	SDL_GetWindowSizeInPixels(_sdl, &w, &h);
	return NSMakeSize(w,h);
	}

/*****************************************************************************\
|* Work out the main view dimensions and calculate DPI
\*****************************************************************************/
- (void) _updateMainViewDimensions
	{
	int winW = 0;
	int winH = 0;

	if (_sdl)
		SDL_GetWindowSize(_sdl, &winW, &winH);

	_pixelSize 			= [self _getOutputSize];
	_mainView.pixelW 	= _pixelSize.width;
	_mainView.pixelH	= _pixelSize.height;
    if (winW > 0 && winH > 0)
		{
		_dpiScale.x = _mainView.pixelW / winW;
        _dpiScale.y = _mainView.pixelH / winH;
		}
	else
		{
        _dpiScale.x = 1.0f;
        _dpiScale.y = 1.0f;
		}

	[self _updatePixelViewport:&_mainView];
	}


/*****************************************************************************\
|* Render out the logically-sized presentation, basically cope with letterbox
\*****************************************************************************/
- (void) _renderLogicalPresentation
	{
    const SDL_RendererLogicalPresentation mode = _logicalPresentMode;
    if (mode == SDL_LOGICAL_PRESENTATION_LETTERBOX)
		{
        // save off some state we're going to trample.
        SDL_assert(_view == &_mainView);
        AZViewState *view 	= &_mainView;
		const int logicalW 	= _logicalSize.width;
        const int logicalH 	= _logicalSize.height;
        const float sx 		= view->scale.x;
        const float sy 		= view->scale.y;
		const BOOL doClip	= view->doClip;

		NSRect origViewport	= view->view;
		NSRect origClip;
		if (doClip)
			origClip = view->clip;

        // trample some state.
		[self setLogicalPresentationWidth:logicalW
								   height:logicalH
									 mode:SDL_LOGICAL_PRESENTATION_DISABLED];

		[self setViewport:NSZeroRect];
        if (doClip)
			[self setClipRect:NSZeroRect];
		[self setScaleX:1.f y:1.f];

        // draw the borders.
        [self _renderLogicalBorders];


        // now set everything back.
        _logicalPresentMode 	= mode;
		[self setViewport:origViewport];

        if (doClip)
 			[self setClipRect:origClip];

		[self setScaleX:sx y:sy];

		[self setLogicalPresentationWidth:logicalW
								   height:logicalH
									 mode:mode];
		}
	}


// MARK: Colourspace

/*****************************************************************************\
|* Are we rendering to a linear colour-space
\*****************************************************************************/
-(BOOL) _renderingLinearSpace
	{
    SDL_Colorspace colourspace;

    if (_target)
        colourspace = _target.colourspace;
	else
        colourspace = _outputColourspace;

    if (colourspace == SDL_COLORSPACE_SRGB_LINEAR) {
        return YES;
    }
    return NO;
	}

/*****************************************************************************\
|* Convert to/from linear and sRGB
\*****************************************************************************/
- (void) _convertToLinear:(SDL_FColor *)colour
	{
    colour->r = AZsRGBtoLinear(colour->r);
    colour->g = AZsRGBtoLinear(colour->g);
    colour->b = AZsRGBtoLinear(colour->b);
	}

void SDL_ConvertFromLinear(SDL_FColor *color)
	{
    color->r = AZsRGBfromLinear(color->r);
    color->g = AZsRGBfromLinear(color->g);
    color->b = AZsRGBfromLinear(color->b);
	}

// These two come from SDL_pixels.c, but they're not exported to
// us common folks...
float AZsRGBtoLinear(float v)
	{
    if (v <= 0.04045f)
        v = (v / 12.92f);
	else
        v = SDL_powf((v + 0.055f) / 1.055f, 2.4f);
    return v;
	}

float AZsRGBfromLinear(float v)
	{
    if (v <= 0.0031308f)
        v = (v * 12.92f);
    else
        v = (SDL_powf(v, 1.0f / 2.4f) * 1.055f - 0.055f);
    return v;
	}

// MARK: Rendering

// FlushRenderCommands
/*****************************************************************************\
|* Entry point to rendering to the screen
\*****************************************************************************/
- (BOOL) _flushRenderCommands
	{
	if (_commandQ.count == 0)
		return YES; // Nothing to do!

	BOOL result = [self _runCommandQueue];

    // Reset the command-queue and pool
	[_poolLock lock];

	[_commandPool addObjectsFromArray:_commandQ];
	[_commandQ removeAllObjects];

	_vertexDataInUse 	= 0;
	_colourQueued		= NO;
	_clipRectQueued		= NO;
	_viewportQueued		= NO;
	_cmdGeneration ++;

	[_poolLock unlock];
	return result;
	}

- (BOOL) _runCommandQueue
	{
	void *vertices 	= _vertexData;
	size_t vertSize	= _vertexDataInUse;

    // _renderData ... GPU_RenderData *data = (GPU_RenderData *)renderer->internal;

    if (!UploadVertices(data, vertices, vertsize)) {
        return false;
    }

    data->state.color_attachment.load_op = SDL_GPU_LOADOP_LOAD;

    if (renderer->target) {
        GPU_TextureData *tdata = renderer->target->internal;
        data->state.color_attachment.texture = tdata->texture;
    } else {
        data->state.color_attachment.texture = data->backbuffer.texture;
    }

    if (!data->state.color_attachment.texture) {
        return SDL_SetError("Render target texture is NULL");
    }

    while (cmd) {
        switch (cmd->command) {
        case SDL_RENDERCMD_SETDRAWCOLOR:
        {
            data->state.draw_color = GetDrawCmdColor(renderer, cmd);
            break;
        }

        case SDL_RENDERCMD_SETVIEWPORT:
        {
            SDL_Rect *viewport = &cmd->data.viewport.rect;
            data->state.viewport.x = viewport->x;
            data->state.viewport.y = viewport->y;
            data->state.viewport.w = viewport->w;
            data->state.viewport.h = viewport->h;
            break;
        }

        case SDL_RENDERCMD_SETCLIPRECT:
        {
            const SDL_Rect *rect = &cmd->data.cliprect.rect;
            data->state.scissor.x = (int)data->state.viewport.x + rect->x;
            data->state.scissor.y = (int)data->state.viewport.y + rect->y;
            data->state.scissor.w = rect->w;
            data->state.scissor.h = rect->h;
            data->state.scissor_enabled = cmd->data.cliprect.enabled;
            break;
        }

        case SDL_RENDERCMD_CLEAR:
        {
            data->state.color_attachment.clear_color = GetDrawCmdColor(renderer, cmd);
            data->state.color_attachment.load_op = SDL_GPU_LOADOP_CLEAR;
            break;
        }

        case SDL_RENDERCMD_FILL_RECTS: // unused
            break;

        case SDL_RENDERCMD_COPY: // unused
            break;

        case SDL_RENDERCMD_COPY_EX: // unused
            break;

        case SDL_RENDERCMD_DRAW_LINES:
        {
            Uint32 count = (Uint32)cmd->data.draw.count;
            Uint32 offset = (Uint32)cmd->data.draw.first;

            if (count > 2) {
                // joined lines cannot be grouped
                Draw(data, cmd, count, offset, SDL_GPU_PRIMITIVETYPE_LINESTRIP);
            } else {
                // let's group non joined lines
                SDL_RenderCommand *finalcmd = cmd;
                SDL_RenderCommand *nextcmd = cmd->next;
                SDL_BlendMode thisblend = cmd->data.draw.blend;

                while (nextcmd) {
                    const SDL_RenderCommandType nextcmdtype = nextcmd->command;
                    if (nextcmdtype != SDL_RENDERCMD_DRAW_LINES) {
                        break; // can't go any further on this draw call, different render command up next.
                    } else if (nextcmd->data.draw.count != 2) {
                        break; // can't go any further on this draw call, those are joined lines
                    } else if (nextcmd->data.draw.blend != thisblend) {
                        break; // can't go any further on this draw call, different blendmode copy up next.
                    } else {
                        finalcmd = nextcmd; // we can combine copy operations here. Mark this one as the furthest okay command.
                        count += (Uint32)nextcmd->data.draw.count;
                    }
                    nextcmd = nextcmd->next;
                }

                Draw(data, cmd, count, offset, SDL_GPU_PRIMITIVETYPE_LINELIST);
                cmd = finalcmd; // skip any copy commands we just combined in here.
            }
            break;
        }

        case SDL_RENDERCMD_DRAW_POINTS:
        case SDL_RENDERCMD_GEOMETRY:
        {
            /* as long as we have the same copy command in a row, with the
               same texture, we can combine them all into a single draw call. */
            SDL_Texture *thistexture = cmd->data.draw.texture;
            SDL_BlendMode thisblend = cmd->data.draw.blend;
            const SDL_RenderCommandType thiscmdtype = cmd->command;
            SDL_RenderCommand *finalcmd = cmd;
            SDL_RenderCommand *nextcmd = cmd->next;
            Uint32 count = (Uint32)cmd->data.draw.count;
            Uint32 offset = (Uint32)cmd->data.draw.first;

            while (nextcmd) {
                const SDL_RenderCommandType nextcmdtype = nextcmd->command;
                if (nextcmdtype != thiscmdtype) {
                    break; // can't go any further on this draw call, different render command up next.
                } else if (nextcmd->data.draw.texture != thistexture || nextcmd->data.draw.blend != thisblend) {
                    // FIXME should we check address mode too?
                    break; // can't go any further on this draw call, different texture/blendmode copy up next.
                } else {
                    finalcmd = nextcmd; // we can combine copy operations here. Mark this one as the furthest okay command.
                    count += (Uint32)nextcmd->data.draw.count;
                }
                nextcmd = nextcmd->next;
            }

            SDL_GPUPrimitiveType prim = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST; // SDL_RENDERCMD_GEOMETRY
            if (thiscmdtype == SDL_RENDERCMD_DRAW_POINTS) {
                prim = SDL_GPU_PRIMITIVETYPE_POINTLIST;
            }

            Draw(data, cmd, count, offset, prim);

            cmd = finalcmd; // skip any copy commands we just combined in here.
            break;
        }

        case SDL_RENDERCMD_NO_OP:
            break;
        }

        cmd = cmd->next;
    }

    if (data->state.color_attachment.load_op == SDL_GPU_LOADOP_CLEAR) {
        RestartRenderPass(data);
    }

    if (data->state.render_pass) {
        SDL_EndGPURenderPass(data->state.render_pass);
        data->state.render_pass = NULL;
    }

    return true;
}


/*****************************************************************************\
|* Set the swapchain parameters
\*****************************************************************************/
- (BOOL) setSwapchainParameters:(SDL_GPUSwapchainComposition)composition
					presentMode:(SDL_GPUPresentMode) presentMode
	{
    if (_window.window == NULL)
		{
        SDL_InvalidParamError("setSwapchainParameters window");
        return NO;
		}

    return device->SetSwapchainParameters(
        device->driverData,
        window,
        swapchain_composition,
        present_mode);
}

// MARK: Queueing of commands

/*****************************************************************************\
|* Fetch a command from the pool, or create a new one
\*****************************************************************************/
- (AZRenderCommand *) _allocateCommand
	{
	[_poolLock lock];

	AZRenderCommand *cmd = nil;
	if (_commandPool.count > 0)
		{
		cmd = _commandPool.lastObject;
		[_commandPool removeLastObject];
		}
	else
		cmd = AZRenderCommand.new;

	if (cmd)
		[_commandQ addObject:cmd];

	[_poolLock unlock];
	return cmd;
	}

/*****************************************************************************\
|* Prepare a command for a draw operation
\*****************************************************************************/
- (AZRenderCommand *) _prepQueueCommandDrawOfType:(AZRenderCommandType)type
										  texture:(nullable AZTexture *)texture
	{
    AZRenderCommand *cmd 	= nil;
    BOOL result 			= YES;
    SDL_FColor  colour;
    SDL_BlendMode blend;

    if (texture)
		{
        colour 	= texture.colour;
        blend 	= texture.blendMode;
		}
	else
		{
		colour 	= _colour.sdlColour;
        blend 	= _blendModeValue;
		}

	/*************************************************************************\
	|* Set the colour to use, if we're not rendering geometry
	\*************************************************************************/
    if (type != AZRenderCmdGeometry)
		result = [self _queueCmdSetDrawColour:colour];

	/*************************************************************************\
	|* Set the viewport and clip rect directly before draws, so the backends
	|* don't have to worry about that state not being valid at draw time
	\*************************************************************************/
    if (result && !_viewportQueued)
		result = [self _queueCmdSetViewport];

    if (result && !_clipRectQueued)
		result = [self _queueCmdSetClipRect];

	/*************************************************************************\
	|* If we're still good to go, then set up the data structures
	\*************************************************************************/
    if (result)
		{
        cmd = [self _allocateCommand];
        if (cmd)
			{
            cmd.command 	= type;
            cmd.first 		= 0; // render backend will fill this in.
            cmd.count 		= 0; // render backend will fill this in.
            cmd.colourScale	= _colourScale;
            cmd.colour 		= colour;
            cmd.blendMode 	= blend;
            cmd.texture 	= texture;
            cmd.addressMode = AZTextureAddressClamp;
        }
    }
    return cmd;
	}

/*****************************************************************************\
|* Set the viewport as a queue'd command
\*****************************************************************************/
- (BOOL) _queueCmdSetViewport
	{
    BOOL result = YES;
	NSRect view	= _view->pixelView;

	BOOL newVP = (SDL_memcmp(&view, &_lastQueuedViewport, sizeof(NSRect)) != 0);
    if (!_viewportQueued || newVP)
		{
		AZRenderCommand *cmd = [self _allocateCommand];
        if (cmd)
			{
            cmd.command 		= AZRenderCmdSetViewport;
            cmd.first  			= 0;
            cmd.rect 			= view;

			_lastQueuedViewport = view;
			_viewportQueued		= YES;
			}
		else
            result = false;
		}
    return result;
	}

/*****************************************************************************\
|* Set the draw colour as a queue'd command
\*****************************************************************************/
- (BOOL) _queueCmdSetDrawColour:(SDL_FColor)colour
	{
    BOOL result = YES;
	BOOL same	= (colour.r == _lastQueuedColour.r) &&
				  (colour.g == _lastQueuedColour.g) &&
				  (colour.b == _lastQueuedColour.b) &&
				  (colour.a == _lastQueuedColour.a);


	if ((!_colourQueued) || (!same))
		{
		AZRenderCommand *cmd = [self _allocateCommand];
        if (cmd)
			{
            cmd.command 		= AZRenderCmdSetDrawColour;
            cmd.first 			= 0; // render backend will fill this in.
            cmd.colourScale 	= _colourScale;
            cmd.colour 			= colour;

			_lastQueuedColour 	= colour;
			_colourQueued 		= YES;
			}
		else
			result = NO;
		}
    return result;
	}

/*****************************************************************************\
|* Set the clip rect as a queue'd command
\*****************************************************************************/
- (BOOL) _queueCmdSetClipRect
	{
    BOOL result = YES;

    NSRect clipRect = _view->pixelClip;
	BOOL same		= _view->doClip == _lastQueuedDoClip &&
					   NSEqualRects(clipRect, _lastQueuedClip);

    if ((!_clipRectQueued) || (!same))
		{
		AZRenderCommand *cmd = [self _allocateCommand];
        if (cmd)
			{
            cmd.command 		= AZRenderCmdSetCliprect;
			cmd.enabled 		= _view->doClip;
			cmd.rect			= clipRect;
			_lastQueuedClip		= clipRect;
			_lastQueuedDoClip	= _view->doClip;
			_clipRectQueued		= YES;
			}
		else
            result = NO;
		}
    return result;
	
	}

/*****************************************************************************\
|* Fill rectangles as a queue'd command
\*****************************************************************************/
- (BOOL) _queueCmdFilledRects:(NSRect *)rects count:(int)count
	{
    AZRenderCommand *cmd = nil;
    BOOL result 		 = NO;

	cmd = [self _prepQueueCommandDrawOfType:AZRenderCmdGeometry texture:nil];
    if (cmd)
		{
		BOOL isstack1;
		BOOL isstack2;

		float *xy 		= AZSmallAlloc(float, 4 * 2 * count, &isstack1);
		int *indices 	= AZSmallAlloc(int, 6 * count, &isstack2);

		if (xy && indices)
			{
			float *ptrXY 			= xy;
			int *ptrIndices 		= indices;
			const int xyStride 		= 2 * sizeof(float);
			const int numVertices	= 4 * count;
			const int numIndices 	= 6 * count;
			const int sizeIndices 	= 4;
			int curIndex 			= 0;

			for (int i = 0; i < count; ++i)
				{
				float minx, miny, maxx, maxy;

				minx = NSMinX(rects[i]);
				miny = NSMinY(rects[i]);
				maxx = NSMaxX(rects[i]);
				maxy = NSMaxY(rects[i]);

				*ptrXY++ = minx;
				*ptrXY++ = miny;
				*ptrXY++ = maxx;
				*ptrXY++ = miny;
				*ptrXY++ = maxx;
				*ptrXY++ = maxy;
				*ptrXY++ = minx;
				*ptrXY++ = maxy;

				*ptrIndices++ = curIndex + _rectIndexOrder[0];
				*ptrIndices++ = curIndex + _rectIndexOrder[1];
				*ptrIndices++ = curIndex + _rectIndexOrder[2];
				*ptrIndices++ = curIndex + _rectIndexOrder[3];
				*ptrIndices++ = curIndex + _rectIndexOrder[4];
				*ptrIndices++ = curIndex + _rectIndexOrder[5];
				curIndex += 4;
				}

			SDL_FColor colour = _colour.sdlColour;
			result = [self _queueGeometryWith:cmd
									  texture:nil
										   xy:xy
									 xyStride:xyStride
									   colour:&colour
								 colourStride:0
										   uv:NULL
									 uvStride:0
								  numVertices:numVertices
									  indices:indices
								   numIndices:numIndices
								  sizeIndices:sizeIndices
									   scaleX:1.f
									   scaleY:1.f];


			if (!result)
				cmd.command = AZRenderCmdNoOp;
            }

		AZSmallFree(xy, isstack1);
		AZSmallFree(indices, isstack2);
		}

    return result;
	}

- (BOOL) _queueGeometryWith:(AZRenderCommand *)cmd
					texture:(nullable AZTexture *)texture
						 xy:(const float *)xy
				   xyStride:(int)xyStride
					 colour:(SDL_FColor*)colour
			   colourStride:(int)colourStride
						 uv:(nullable const float *)uv
				   uvStride:(int)uvStride
				numVertices:(int)numVertices
				    indices:(const void *)indices
				 numIndices:(int)numIndices
				sizeIndices:(int)sizeIndices
					 scaleX:(float)scaleX
					 scaleY:(float)scaleY
	{
    int count 	= indices ? numIndices : numVertices;
	size_t sz 	= 2 * sizeof(float) 					// xy
				+ 4 * sizeof(float) 					// colour
				+ (texture ? 2 : 0) * sizeof(float);	// uv

    const float colourScale = cmd.colourScale;
    bool convertColour 		= [self _renderingLinearSpace];

	NSInteger first			= 0;
	float *verts			= (float *) [self _allocateVerticesOfSize:count * sz
														withAlignment:0
															 atOffset:&first];
    if (!verts)
        return NO;

	cmd.first 	= first;
    cmd.count 	= count;
    sizeIndices = indices ? sizeIndices : 0;

    for (int i = 0; i < count; i++)
		{
        int j;
        SDL_FColor colourVal;

		switch (sizeIndices)
			{
			case 4:
				j = ((const Uint32 *)indices)[i];
				break;
			case 2:
				j = ((const Uint16 *)indices)[i];
				break;
			case 1:
				j = ((const Uint8 *)indices)[i];
				break;
			default:
				j=i;
				break;
			}

        float * xyPtr = (float *)((char *)xy + j * xyStride);

        *(verts++) 	= xyPtr[0] * scaleX;
        *(verts++) 	= xyPtr[1] * scaleY;

        colourVal 	= *(SDL_FColor *)((char *)colour + j * colourStride);
        if (convertColour)
			[self _convertToLinear:&colourVal];

        *(verts++) = colourVal.r * colourScale;
        *(verts++) = colourVal.g * colourScale;
        *(verts++) = colourVal.b * colourScale;
        *(verts++) = colourVal.a;

        if (texture)
			{
            float *uvPtr = (float *)((char *)uv + j * uvStride);
			*(verts++) = uvPtr[0] * texture.size.width;
            *(verts++) = uvPtr[1] * texture.size.height;
			}
		}
	return YES;
	}


/*****************************************************************************\
|* Allocate space for more vertex data
\*****************************************************************************/
- (nullable void *) _allocateVerticesOfSize:(NSInteger)numBytes
							  withAlignment:(NSInteger)alignment
								   atOffset:(NSInteger *)offset
	{
    const size_t needed = _vertexDataInUse + numBytes + alignment;
    const size_t whence = _vertexDataInUse;

    const size_t aligner = (alignment && ((whence & (alignment - 1)) != 0))
						 ? (alignment - (whence & (alignment - 1)))
						 : 0;
    const size_t aligned = whence + aligner;

    if (_vertexDataSize < needed)
		{
        NSInteger currentAllocation = _vertexData ? _vertexDataSize : 1024;
        NSInteger newSize = currentAllocation * 2;
        while (newSize < needed)
            newSize *= 2;


        void *ptr = SDL_realloc(_vertexData, newSize);

        if (!ptr)
            return NULL;

        _vertexData 		= ptr;
        _vertexDataSize 	= newSize;
		}

    if (offset)
        *offset = aligned;

    _vertexDataInUse += aligner + numBytes;

    return ((Uint8 *)_vertexData) + aligned;
	}








@end
