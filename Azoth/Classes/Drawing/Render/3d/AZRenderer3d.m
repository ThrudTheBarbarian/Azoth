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
#import "AZRenderCommand.h"
#import "AZRenderPipeline.h"
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
	} ViewState;

static const int _rectIndexOrder[] = { 0, 1, 2, 0, 2, 3 };


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

// The sprite render pipeline
@property(strong, nonatomic) AZRenderPipeline *				spritePipe;

// The sprite compute pipeline
@property(strong, nonatomic) AZComputePipeline *			computePipe;

// The sampler
@property(strong, nonatomic) AZSampler *					sampler;

// The target we're rendering onto, or nil for screen
@property(strong, nonatomic, nullable) AZTexture *			target;

// The current view state
@property(assign, nonatomic) ViewState						view;

// The main view state
@property(assign, nonatomic) ViewState						mainView;

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
@property(assign, nonatomic) SDL_BlendMode					blend;

// The amount of space used for vertices so far
@property(assign, nonatomic) NSInteger						vertexDataInUse;

// The amount of space allocated for vertices so far
@property(assign, nonatomic) NSInteger						vertexDataSize;

// The actual vertex data
@property(assign, nonatomic) void *							vertexData;

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

		/*********************************************************************\
		|* Default draw colour is white
		\*********************************************************************/
		_colour = AZColour.white;

		/*********************************************************************\
		|* Default render target is the screen
		\*********************************************************************/
		_target = nil;

		/*********************************************************************\
		|* We use line-drawing by default for rendering lines
		\*********************************************************************/
		_lineMethod = AZ_RENDERLINEMETHOD_LINES;

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
	if (![_spritePipe buildWithDevice:self])
		{
		SDL_Log("Failed to create remder pipeline");
		return NO;
		}


	/*************************************************************************\
    |* Create the compute pipeline
    \*************************************************************************/
	_computePipe = [AZComputePipeline pipelineNamed:@"sprite.comp"
								   storageBuffersRO:1
								   storageBuffersRW:1
										    threads:AZMakeThreadSize(64,1,1)];

	if (![_computePipe buildWithDevice:self])
		{
		SDL_Log("Failed to create compute pipeline");
		return NO;
		}

	/*************************************************************************\
    |* Create the sampler
    \*************************************************************************/
	_sampler =
	[AZSampler withMinFilter:SDL_GPU_FILTER_NEAREST
				   magFilter:SDL_GPU_FILTER_NEAREST
				  mipMapMode:SDL_GPU_SAMPLERMIPMAPMODE_NEAREST
				addressModeU:SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE
				addressModeV:SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE
				addressModeW:SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE];
	if (![_sampler buildWithDevice:self])
		{
		SDL_Log("Failed to create sampler");
		return NO;
		}

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
	_mainView.pixelW 		= w;
	_mainView.pixelH 		= h;
	_mainView.scale 		= (NSPoint){1.f, 1.f};
	_mainView.logicalScale 	= _mainView.scale;
	_mainView.currentScale 	= _mainView.scale;
	_view 					= _mainView;

	[self _updatePixelViewport:&_mainView];
	[self _updatePixelClipRect:&_mainView];

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


/*****************************************************************************\
|* Render a filled rectangle
\*****************************************************************************/
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
    const float sx = _view.currentScale.x;
    const float sy = _view.currentScale.y;
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
- (int) setBlendMode:(SDL_BlendMode)blendMode
	{
	_blend = blendMode;
	return YES;
	}


- (void) setClip:(NSRect)clipRect
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
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


- (BOOL)setViewport:(NSRect)rect
	{
	if (NSEqualRects(rect, NSZeroRect))
		{
        if ((NSWidth(rect) < 0) || (NSHeight(rect) < 0))
            return SDL_SetError("viewport rect has a negative size");
		_view.view = rect;
		}
	else
		_view.view = NSMakeRect(0,0,-1,-1);

	[self _updatePixelViewport:&_view];


    return [self _queueCmdSetViewport];
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

    if (_view.view.size.width >= 0)
        w = _view.view.size.width;
    else
        w = _view.pixelW / _view.currentScale.x;

    if (_view.view.size.height >= 0)
        h = _view.view.size.height;
    else
        h = _view.pixelH / _view.currentScale.y;

	return NSMakeRect(0.f, 0.f, w, h);
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


/*****************************************************************************\
|* Work out the pixel-based viewport from the viewport
\*****************************************************************************/
- (void) _updatePixelViewport:(ViewState *)vs
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
- (void) _updatePixelClipRect:(ViewState *)vs
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
        blend 	= _blend;
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
            cmd.blend 		= blend;
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
	NSRect view	= _view.pixelView;

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

    NSRect clipRect = _view.pixelClip;
	BOOL same		= _view.doClip == _lastQueuedDoClip &&
					   NSEqualRects(clipRect, _lastQueuedClip);

    if ((!_clipRectQueued) || (!same))
		{
		AZRenderCommand *cmd = [self _allocateCommand];
        if (cmd)
			{
            cmd.command 		= AZRenderCmdSetCliprect;
			cmd.enabled 		= _view.doClip;
			cmd.rect			= clipRect;
			_lastQueuedClip		= clipRect;
			_lastQueuedDoClip	= _view.doClip;
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
