//
//  AZRenderer3d.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/13/25.
//

#import <SDL3/SDL.h>
#import <SDL3_ttf/SDL_ttf.h>

//#define AZ_COMPLEX_LOG

#import "AZ3dUtils.h"
#import "AZColour.h"
#import "AZColourTarget.h"
#import "AZComputePipeline.h"
#import "AZGPUBuffer.h"
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



typedef struct GPU_ShaderUniformData
	{
    Float4x4 mvp;					// 16 floats
    SDL_FColor colour;				// 4 floats
    float textureSize[2];			// 2 floats
	} GPU_ShaderUniformData;

typedef struct
	{
	SDL_GPURenderPass *renderPass;
	AZTexture *renderTarget;
	SDL_GPUCommandBuffer *commandBuffer;
	SDL_GPUColorTargetInfo colourAttachment;
	SDL_GPUViewport viewport;
	SDL_Rect scissor;
	SDL_FColor drawColour;
	bool scissorEnabled;
	bool scissorWasEnabled;
	GPU_ShaderUniformData shaderData;
	} AZRenderState;

typedef struct
	{
	SDL_GPUTransferBuffer *transferBuf;
	SDL_GPUBuffer *buffer;
	Uint32 bufferSize;
	} AZVertices;

static const int _rectIndexOrder[] = { 0, 1, 2, 0, 2, 3 };

typedef struct AZRenderData
	{
    struct
		{
        SDL_GPUSwapchainComposition composition;
        SDL_GPUPresentMode presentMode;
		} swapchain;
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

//static AZThreadSize AZMakeThreadSize(int x, int y, int z)
//	{
//	AZThreadSize azts;
//	azts.x = x;
//	azts.y = y;
//	azts.z = z;
//	return azts;
//	};


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

// The backbuffer
@property(assign, nonatomic) AZTexture *					backbuffer;

// The set of shaders loaded
@property(assign, nonatomic) AZShaders 						shaders;

// The current render-state
@property(assign, nonatomic) AZRenderState					state;

// The vertices to send to the GPU
@property(assign, nonatomic) AZVertices						vertices;

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

// The lock surrounding the target texture
@property(strong, nonatomic) NSLock *						targetLock;

// The pool of render commands that we draw from
@property(strong, nonatomic)
NSMutableArray<AZRenderCommand *> *							commandPool;

// The list of render commands that we have enqueued
@property(strong, nonatomic)
NSMutableArray<AZRenderCommand *> *							commandQ;

// Different ways to blend
@property(assign, nonatomic) SDL_BlendMode					blendModeValue;

// The amount of space used for vertices so far
@property(assign, nonatomic) Uint32							vertexDataInUse;

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

// Allowed texture formats
@property(strong, nonatomic) NSMutableArray<NSNumber*> *	textureFormats;

// Whether to simulate vsync
@property(assign, nonatomic) BOOL							simulateVsync;

// Simulated vsync interval
@property(assign, nonatomic) Uint64							vsyncIntervalNanos;

// Last time we present'd
@property(assign, nonatomic) Uint64							vsyncLastPresent;

// The current swapchain texture, or nil
@property(assign, nonatomic, nullable) SDL_GPUTexture *		swapchain;
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
		_textures 		= NSMutableDictionary.new;

		/*********************************************************************\
		|* Set up which texture formats we support
		\*********************************************************************/
		_textureFormats	= NSMutableArray.new;
		[_textureFormats addObject:@(SDL_PIXELFORMAT_RGBA32)];
		[_textureFormats addObject:@(SDL_PIXELFORMAT_BGRA32)];
		[_textureFormats addObject:@(SDL_PIXELFORMAT_RGBX32)];
		[_textureFormats addObject:@(SDL_PIXELFORMAT_BGRX32)];

		/*********************************************************************\
		|* ... and how large those textures can be
		\*********************************************************************/
		_properties[AZRendererMaxTextureSize] = @(16384);

		/*********************************************************************\
		|* Default clear colour is in fact ... clear
		\*********************************************************************/
		_clearColour = AZColour.clear;

		/*********************************************************************\
		|* Default draw colour is white
		\*********************************************************************/
		_colour = AZColour.red;

		/*********************************************************************\
		|* Default render target is the screen, no logical presentation
		\*********************************************************************/
		_target 			= nil;
		_logicalPresentMode	= SDL_LOGICAL_PRESENTATION_DISABLED;
		_targetLock			= [NSLock new];

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
		|* Default texture-addressing mode is to clamp at the edges
		\*********************************************************************/
		_addressMode 		= AZTextureAddressClamp;
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
		[self _destroyTexture:textureId.integerValue];

	}

/*****************************************************************************\
|* The type of the renderer
\*****************************************************************************/
- (AZRendererType) rendererType
	{
	return AZRendererType3d;
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
	BOOL vsync = ((NSNumber*)_properties[AZRendererVSync]).boolValue;
	[self _choosePresentationMode:&(_renderData.swapchain.presentMode)
							vsync:vsync];

	/*************************************************************************\
    |* ... and the swapchain parameters
    \*************************************************************************/
	[self setSwapchainParameters:_renderData.swapchain.composition
					 presentMode:_renderData.swapchain.presentMode];

	/*************************************************************************\
    |* ... and how many frames are allowed to be in-flight
    \*************************************************************************/
	[self setAllowedFramesInFlight: 1];


	/*************************************************************************\
	|* Set up the renderer state
	\*************************************************************************/
	_state.drawColour 			= _colour.sdlColour;
	_state.viewport.max_depth 	= 1;
	_state.viewport.min_depth 	= 0;
	_state.commandBuffer 		= SDL_AcquireGPUCommandBuffer(_gpu);

	/*************************************************************************\
	|* Create the back-buffer
	\*************************************************************************/
    int w, h;
    SDL_GetWindowSizeInPixels(_window.window, &w, &h);

    SDL_GPUTextureFormat fmt;
	fmt = SDL_GetGPUSwapchainTextureFormat(_gpu, _window.window);

	SDL_PixelFormat pFmt = [AZTexture pixelFormatFor:fmt];
	if (pFmt != SDL_PIXELFORMAT_UNKNOWN)
		[self _createBackBufferOfSize:NSMakeSize(w,h) format:pFmt];
	else
		SDL_Log("Cannot convert swapchain format - got 0x%x", fmt);


	/*************************************************************************\
	|* Calculate a good delay to use for the vsync simulation, just in case
	\*************************************************************************/
	[self _calculateSimulatedVSyncInterval];

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
    |* Get the requested size
    \*************************************************************************/
	int x = f.origin.x;
	int y = f.origin.y;

	/*************************************************************************\
    |* Find the display list
    \*************************************************************************/
	int num = 0;
	SDL_DisplayID * displays 	= SDL_GetDisplays(&num);
	SDL_DisplayID choice 		= (num > 0) ? displays[0] : -1;
	if (displays)
		{
		NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
		int dpy = [ud stringForKey:AZ_DEFAULT_SCREEN].intValue;

		if ((dpy >= 0) && (dpy < num))
			choice = displays[dpy];
		}

	/*************************************************************************\
    |* Position it, if possible
    \*************************************************************************/
	if (choice >= 0)
		{
		SDL_Rect bounds;
		SDL_GetDisplayBounds(choice, &bounds);
		int W = bounds.w;
		int H = bounds.h;

		if (w > W)
			{
			w = W;
			x = 0;
			}
		else if (w + x > W)
			{
			x = (W-w)/2;
			}

		if (h > H)
			{
			h = H;
			y = 0;
			}
		else if (w + x > W)
			{
			y = (H-h)/2;
			}
		}
	SDL_free(displays);

	/*************************************************************************\
    |* Set the position
    \*************************************************************************/
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

/*****************************************************************************\
|* And we can turn Images into textures
\*****************************************************************************/
- (nullable AZTexture *) textureForId:(NSInteger)refId
	{
	return _textures[@(refId)];
	}

/*****************************************************************************\
|* Do a 9-way tiled blit to stretch a texture without stretching the borders
\*****************************************************************************/
- (int)blit9WayFrom:(NSInteger)textureId
				src:(NSRect)src
			  scale:(float)scale
			   left:(float)left
			  right:(float)right
			    top:(float)top
			 bottom:(float)bottom
				dst:(NSRect)dst
	{
	AZTexture *texture = _textures[@(textureId)];
	if (texture == nil)
		return NO;

	/*************************************************************************\
	|* Figure out what to do if NSZeroRect is passed for src/dst
	\*************************************************************************/
    if (NSEqualRects(src, NSZeroRect))
		src = NSMakeRect(0, 0, texture.size.width, texture.size.height);

	if (NSEqualRects(dst, NSZeroRect))
		dst = [self viewportSize];

	/*************************************************************************\
	|* Work out the destination offsets
	\*************************************************************************/
    float dstLeft, dstRight, dstTop, dstBottom;
    if (scale <= 0.f || scale == 1.f)
		{
        dstLeft 	= SDL_ceilf(left);
        dstRight 	= SDL_ceilf(right);
        dstTop 		= SDL_ceilf(top);
        dstBottom 	= SDL_ceilf(bottom);
		}
	else
		{
        dstLeft 	= SDL_ceilf(left * scale);
        dstRight 	= SDL_ceilf(right * scale);
        dstTop 		= SDL_ceilf(top * scale);
        dstBottom 	= SDL_ceilf(bottom * scale);
		}

	/*************************************************************************\
	|* Shortcuts to prevent multiple calls
	\*************************************************************************/
	float srcX 	= NSMinX(src);
	float srcY 	= NSMinY(src);
	float srcW	= NSWidth(src);
	float srcH  = NSHeight(src);

	float dstX 	= NSMinX(dst);
	float dstY 	= NSMinY(dst);
	float dstW	= NSWidth(dst);
	float dstH  = NSHeight(dst);

	/*************************************************************************\
	|* Do the center
	\*************************************************************************/
	NSRect currSrc = NSMakeRect(srcX + left,
								srcY + top,
								srcW - left -right,
								srcH - top - bottom);
	NSRect currDst = NSMakeRect(dstX + dstLeft,
								dstY + dstTop,
								dstW - dstLeft - dstRight,
								dstH - dstTop - dstBottom);
	if (![self _renderTexture:texture src:currSrc dst:currDst])
		return NO;

	/*************************************************************************\
	|* Top left corner
	\*************************************************************************/
	currSrc = NSMakeRect(srcX, srcY, left, top);
	currDst = NSMakeRect(dstX, dstY, dstLeft, dstTop);
	if (![self _renderTexture:texture src:currSrc dst:currDst])
		return NO;

 	/*************************************************************************\
	|* Top right corner
	\*************************************************************************/
	currSrc.origin.x = srcX + srcW - right;
	currSrc.size.width = right;
	currDst.origin.x = dstX +dstW - dstRight;
	currDst.size.width = dstRight;
	if (![self _renderTexture:texture src:currSrc dst:currDst])
		return NO;

 	/*************************************************************************\
	|* Bottom right corner
	\*************************************************************************/
	currSrc.origin.y = srcY + srcH - bottom;
	currDst.origin.y = dstY + dstH - dstBottom;
	currDst.size.height = dstBottom;
	if (![self _renderTexture:texture src:currSrc dst:currDst])
		return NO;

 	/*************************************************************************\
	|* Bottom left corner
	\*************************************************************************/
	currSrc.origin.x = srcX;
	currSrc.size.width = left;
	currDst.origin.x = dstX;
	currDst.size.width = dstLeft;
	if (![self _renderTexture:texture src:currSrc dst:currDst])
		return NO;

 	/*************************************************************************\
	|* Left side
	\*************************************************************************/
	currSrc.origin.y = srcY + top;
	currSrc.size.height = srcH - top - bottom;
	currDst.origin.y = dstY + dstTop;
	currDst.size.height = dstH - dstTop - dstBottom;
	if (![self _renderTexture:texture src:currSrc dst:currDst])
		return NO;

 	/*************************************************************************\
	|* Right side
	\*************************************************************************/
	currSrc.origin.x = srcX + srcW - right;
	currSrc.size.width = right;
	currDst.origin.x = dstX + dstW - dstRight;
	currDst.size.width = dstRight;
	if (![self _renderTexture:texture src:currSrc dst:currDst])
		return NO;

 	/*************************************************************************\
	|* Top side
	\*************************************************************************/
	currSrc = NSMakeRect(srcX + left, srcY, srcW - left - right, top);
	currDst = NSMakeRect(dstX + dstLeft, dstY, dstW - dstLeft - dstRight, dstTop);
	if (![self _renderTexture:texture src:currSrc dst:currDst])
		return NO;

 	/*************************************************************************\
	|* Bottom side
	\*************************************************************************/
	currSrc.origin.y = srcY + srcH - bottom;
	currDst.origin.y = dstY + dstH - dstBottom;
	currDst.size.height = dstBottom;
	if (![self _renderTexture:texture src:currSrc dst:currDst])
		return NO;

    return YES;
	}

/*****************************************************************************\
|* The text engine for this renderer
\*****************************************************************************/
- (TTF_TextEngine *) textEngine
	{
	return TTF_CreateGPUTextEngine(_gpu);
	}

/*****************************************************************************\
|* Perform a blit operation
\*****************************************************************************/
- (int)blitFrom:(NSInteger)textureId src:(NSRect)srcRect dst:(NSRect)dstRect
	{
	AZTexture *texture = _textures[@(textureId)];
	if (texture)
		return [self _renderTexture:texture src:srcRect dst:dstRect];

	SDL_Log("Cannot find texture %d to blit from", (int)textureId);
	return -1;
	}


/*****************************************************************************\
|* Perform a blit operation with rotation
\*****************************************************************************/
- (int)blitFrom:(NSInteger)textureId
			src:(NSRect)src
			dst:(NSRect)dst
		  angle:(NSInteger)angle
		 center:(NSPoint)centre
		   flip:(AZFlipMode)flip
	{
	AZTexture *texture = _textures[@(textureId)];
	if (texture == nil)
		return NO;

    if (flip == AZFlipNone && ((angle % 360) == 0))
		// fast path when we don't need rotation or flipping
		return [self blitFrom:textureId src:src dst:dst];

	NSRect realSrc = NSMakeRect(0,0,texture.size.width, texture.size.height);
	BOOL srcIsZero = (NSEqualRects(src, NSZeroRect));
    if (!srcIsZero)
		{
		NSRect intersection = NSIntersectionRect(src, realSrc);
		if (NSEqualRects(intersection, NSZeroRect))
            return YES;
		realSrc = intersection;
        }

    // We don't intersect the dstrect with the viewport as RenderCopy does
    // because of potential rotation clipping issues... TODO: should we?
	if (NSEqualRects(dst, NSZeroRect))
		dst = [self viewportSize];

	float srcX 	= NSMinX(src);
	float srcY 	= NSMinY(src);
	float srcW	= NSWidth(src);
	float srcH  = NSHeight(src);

	float dstX 	= NSMinX(dst);
	float dstY 	= NSMinY(dst);
	float dstW	= NSWidth(dst);
	float dstH  = NSHeight(dst);

	float texW	= texture.size.width;
	float texH 	= texture.size.height;

	NSPoint realCentre;
	BOOL centreIsZero = (NSEqualPoints(centre, NSZeroPoint));
	if (!centreIsZero)
        realCentre = centre;
    else
		{
        realCentre.x = NSWidth(dst)  / 2.f;
        realCentre.y = NSHeight(dst) / 2.f;
		}

    texture.lastCommandGen = _cmdGeneration;

    const float sx = _view->currentScale.x;
    const float sy = _view->currentScale.y;

	float xy[8];
	const int xyStride 		= 2 * sizeof(float);

	float uv[8];
	const int uvStride 		= 2 * sizeof(float);

	const int numVertices 	= 4;
    const int *indices 		= _rectIndexOrder;
	const int numIndices 	= 6;
	const int sizeIndices 	= 4;

	float minu 		= srcX / texW;
	float minv 		= srcY / texH;
	float maxu 		= (srcX + srcW) / texW;
	float maxv 		= (srcY + srcH) / texH;

	float cx 		= realCentre.x + dstX;
	float cy 		= realCentre.y + dstY;

	float minx, maxx;
	if (flip & AZFlipHorizontal)
		{
		minx = dstX + dstW;
		maxx = dstX;
		}
	else
		{
		minx = dstX;
		maxx = dstX + dstW;
		}

	float miny, maxy;
	if (flip & AZFlipVertical)
		{
		miny = dstY + dstH;
		maxy = dstY;
		}
	else
		{
		miny = dstY;
		maxy = dstY + dstH;
		}

	uv[0] = minu;
	uv[1] = minv;
	uv[2] = maxu;
	uv[3] = minv;
	uv[4] = maxu;
	uv[5] = maxv;
	uv[6] = minu;
	uv[7] = maxv;

	// apply rotation with 2x2 matrix ( c -s )
	//                                ( s  c )
	const float radians = (float)((SDL_PI_D * angle) / 180.f);
	const float s 		= SDL_sinf(radians);
	const float c 		= SDL_cosf(radians);

	float s_minx = s * (minx - cx);
	float s_miny = s * (miny - cy);
	float s_maxx = s * (maxx - cx);
	float s_maxy = s * (maxy - cy);
	float c_minx = c * (minx - cx);
	float c_miny = c * (miny - cy);
	float c_maxx = c * (maxx - cx);
	float c_maxy = c * (maxy - cy);

	// (minx, miny)
	xy[0] = (c_minx - s_miny) + cx;
	xy[1] = (s_minx + c_miny) + cy;
	// (maxx, miny)
	xy[2] = (c_maxx - s_miny) + cx;
	xy[3] = (s_maxx + c_miny) + cy;
	// (maxx, maxy)
	xy[4] = (c_maxx - s_maxy) + cx;
	xy[5] = (s_maxx + c_maxy) + cy;
	// (minx, maxy)
	xy[6] = (c_minx - s_maxy) + cx;
	xy[7] = (s_minx + c_maxy) + cy;

	SDL_FColor colour = texture.colour;
	return [self _queueCmdGeometryWithTexture:texture
										   xy:xy
									 xyStride:xyStride
									   colour:&colour
									  colourStride:0
										   uv:uv
									 uvStride:uvStride
								  numVertices:numVertices
									  indices:indices
								   numIndices:numIndices
								  sizeIndices:sizeIndices
									   scaleX:sx
									   scaleY:sy
								  addressMode:AZTextureAddressClamp];
	}

/*****************************************************************************\
|* Perform a blit operation with an affine transform:
|*
|* srcRect: the source rectangle or NSZeroRect for the entire texture
|* origin : point where top-left should be mapped to, or NSZeroPoint for the
|*          destination texture's origin
|* right  : point where top-right should be mapped to, or NSZeroPoint for the
|*          destination texture's top-right
|* down   : point where bottom-left should be mapped to, or NSZeroPoint for the
|*          destination texture's bottom-left
\*****************************************************************************/
- (BOOL) blitFrom:(NSInteger)textureId
			  src:(NSRect)src
		   origin:(NSPoint)origin
			right:(NSPoint)right
			 down:(NSPoint)down
	{
	/*************************************************************************\
	|* Get the texture from the identifier
	\*************************************************************************/
	AZTexture *texture = _textures[@(textureId)];
	if (texture == nil)
		return NO;

	/*************************************************************************\
	|* Make sure we either clip to the texture's rect, or set src to be the
	|* texture rect if it was passed in as NSZeroRect
	\*************************************************************************/
	NSRect realSrc = NSMakeRect(0,0,texture.size.width, texture.size.height);
	if (!NSEqualRects(src,NSZeroRect))
		{
		src = NSIntersectionRect(src, realSrc);
		if (NSEqualRects(src, NSZeroRect))
            return YES;
        }
	else
		src = realSrc;

	/*************************************************************************\
	|* Make sure we either clip to the texture's rect, or set src to be the
	|* texture rect if it was passed in as NSZeroRect
	\*************************************************************************/
	NSRect dst = [self viewportSize];
    texture.lastCommandGen = _cmdGeneration;

	float srcX 	= NSMinX(src);
	float srcY 	= NSMinY(src);
	float srcW	= NSWidth(src);
	float srcH  = NSHeight(src);

	float texW	= texture.size.width;
	float texH 	= texture.size.height;

	float dstX 	= NSMinX(dst);
	float dstY 	= NSMinY(dst);
	float dstW	= NSWidth(dst);
	float dstH  = NSHeight(dst);

    const float sx = _view->currentScale.x;
    const float sy = _view->currentScale.y;


	float xy[8];
	const int xyStride 		= 2 * sizeof(float);

	float uv[8];
	const int uvStride 		= 2 * sizeof(float);

	const int numVertices 	= 4;
    const int *indices 		= _rectIndexOrder;
	const int numIndices 	= 6;
	const int sizeIndices 	= 4;


	/*************************************************************************\
	|* Figure out the texture co-ords
	\*************************************************************************/
	float minu 		= srcX / texW;
	float minv 		= srcY / texH;
	float maxu 		= (srcX + srcW) / texW;
	float maxv 		= (srcY + srcH) / texH;

	uv[0] = minu;
	uv[1] = minv;
	uv[2] = maxu;
	uv[3] = minv;
	uv[4] = maxu;
	uv[5] = maxv;
	uv[6] = minu;
	uv[7] = maxv;

	/*************************************************************************\
	|* Figure out the spatial co-ords
	\*************************************************************************/
	// (minx, miny)
	BOOL haveOrigin = !NSEqualPoints(origin, NSZeroPoint);
	if (haveOrigin)
		{
		xy[0] = origin.x;
		xy[1] = origin.y;
		}
	else
		{
		xy[0] = dstX;
		xy[1] = dstY;
		}

	// (maxx, miny)
	BOOL haveRight = !NSEqualPoints(right, NSZeroPoint);
	if (haveRight)
		{
		xy[2] = right.x;
		xy[3] = right.y;
		}
	else
		{
		xy[2] = dstX + dstW;
		xy[3] = dstY;
		}

	// (minx, maxy)
	BOOL haveDown = !NSEqualPoints(down, NSZeroPoint);
	if (haveDown)
		{
		xy[6] = down.x;
		xy[7] = down.y;
		}
	else
		{
		xy[6] = dstX;
		xy[7] = dstY + dstH;
		}

	// (maxx, maxy)
	if (haveOrigin || haveRight || haveDown)
		{
		xy[4] = xy[2] + xy[6] - xy[0];
		xy[5] = xy[3] + xy[7] - xy[1];
		}
	else
		{
		xy[4] = dstX + dstW;
		xy[5] = dstY + dstH;
		}


	/*************************************************************************\
	|* Call...
	\*************************************************************************/
	SDL_FColor colour = texture.colour;
	return [self _queueCmdGeometryWithTexture:texture
										   xy:xy
									 xyStride:xyStride
									   colour:&colour
									  colourStride:0
										   uv:uv
									 uvStride:uvStride
								  numVertices:numVertices
									  indices:indices
								   numIndices:numIndices
								  sizeIndices:sizeIndices
									   scaleX:sx
									   scaleY:sy
								  addressMode:AZTextureAddressClamp];
	}


/*****************************************************************************\
|* blit a texture using provided geometry - convenience method
\*****************************************************************************/
- (BOOL) blit:(NSInteger)textureId
		 with:(int)numVertices
	 vertices:(SDL_Vertex *)vertices
	{
	return [self blit:textureId
				 with:numVertices
			 vertices:vertices
				  and:0
			  indices:NULL];
	}

/*****************************************************************************\
|* blit a texture using provided geometry - convenience method
\*****************************************************************************/
- (BOOL) blit:(NSInteger)textureId
		 with:(int)numVertices
	 vertices:(SDL_Vertex *)vertices
	      and:(int)numIndices
	  indices:(nullable const int *)indices
	{
	if (vertices)
		{
        const float *xy			= &(vertices->position.x);
        int xyStride 			= sizeof(SDL_Vertex);

        SDL_FColor *colours 	= &vertices->color;
        int colourStride 		= sizeof(SDL_Vertex);

        const float *uv 		= &vertices->tex_coord.x;
        int uvStride 			= sizeof(SDL_Vertex);
        int sizeIndices 		= 4;

		return [self blit:textureId
					 with:numVertices
					   xy:xy
				   stride:xyStride
				  colours:colours
				   stride:colourStride
					   uv:uv
				   stride:uvStride
					  and:numIndices
				  indices:indices
				   ofSize:sizeIndices];
		}
	return SDL_InvalidParamError("vertices");
	}

/*****************************************************************************\
|* blit a texture using provided geometry - real method
\*****************************************************************************/
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
	   ofSize:(int)sizeIndices
	{
    AZTextureAddressMode textureAddressMode;

	int count 		= indices ? numIndices : numVertices;
	AZTexture *azt 	= [self textureForId:textureId];

	/*************************************************************************\
	|* Do some tests on the input parameters
	\*************************************************************************/
    if (!xy)
        return SDL_InvalidParamError("xy");

    if (!colours)
        return SDL_InvalidParamError("color");

    if (azt && (!uv))
        return SDL_InvalidParamError("uv");

    if (count % 3 != 0)
        return SDL_InvalidParamError(indices ? "numIndices" : "numVertices");

	if (indices)
		{
		switch (sizeIndices)
			{
			case 1:
			case 2:
			case 4:
				break;
			default:
				return SDL_InvalidParamError("sizeIndices");
			}
		}
	else
		sizeIndices = 0;

    if (numVertices < 3)
        return YES;

	/*************************************************************************\
	|* If texture-address mode is auto, figure out which one we want via uv's
	\*************************************************************************/
    textureAddressMode = self.addressMode;
    if ((textureAddressMode == AZTextureAddressAuto) && azt)
		{
        textureAddressMode = AZTextureAddressClamp;
        for (int i = 0; i < numVertices; ++i)
			{
            const float *uv_ = (const float *)((const char *)uv + i * uvStride);
            float u 		 = uv_[0];
            float v 		 = uv_[1];
            if (u < 0.0f || v < 0.0f || u > 1.0f || v > 1.0f)
				{
                textureAddressMode = AZTextureAddressWrap;
                break;
				}
			}
		}

	/*************************************************************************\
	|* Make sure that indices make sense
	\*************************************************************************/
    if (indices)
		{
        for (int i = 0; i < numIndices; ++i)
			{
			int j = (sizeIndices == 4) ? ((const Uint32 *)indices)[i]
				  : (sizeIndices == 2) ? ((const Uint16 *)indices)[i]
				  : 					 ((const Uint8 *)indices)[i];

            if ((j < 0) || (j >= numVertices))
                return SDL_SetError("Values of 'indices' out of bounds");
			}
		}

	/*************************************************************************\
	|* Match texture and renderer generations
	\*************************************************************************/
    if (azt)
        azt.lastCommandGen = _cmdGeneration;

	return [self _queueCmdGeometryWithTexture:azt
	                                       xy:xy
									 xyStride:xyStride
									   colour:colours
								 colourStride:colourStride
										   uv:uv
									 uvStride:uvStride
								  numVertices:numVertices
									  indices:indices
								   numIndices:numIndices
								  sizeIndices:sizeIndices
									   scaleX:_view->currentScale.x
									   scaleY:_view->currentScale.y
								  addressMode:textureAddressMode];
	}


/*****************************************************************************\
|* Return the bounds of a given texture
\*****************************************************************************/
- (NSRect)boundsOfTexture:(NSInteger)refId
	{
	AZTexture *texture = _textures[@(refId)];
	if (texture)
		return NSMakeRect(0,0,texture.size.width, texture.size.height);
	return NSZeroRect;
	}

/*****************************************************************************\
|* Clear the rendering target
\*****************************************************************************/
- (BOOL)clear
	{
	return [self _queueCmdClear];
	}

/*****************************************************************************\
|* Set the clearing colour
\*****************************************************************************/
- (void) setClearColour:(AZColour *)colour
	{
	_clearColour = colour.copy;
	}


/*****************************************************************************\
|* Determine if the clip is enabled
\*****************************************************************************/
- (BOOL)clipEnabled
	{
	if (_view)
		return _view->doClip;
	return NO;
	}


/*****************************************************************************\
|* Return the actual clip-rect if enabled
\*****************************************************************************/
- (NSRect)clipRect
	{
	if (_view && _view->doClip)
		return _view->clip;
	return NSZeroRect;
	}


/*****************************************************************************\
|* Convert render co-ords to window ones. This is a NOP in the 3d renderer
\*****************************************************************************/
- (BOOL)convertRx:(float)rx
			   ry:(float)ry
			   to:(nonnull float *)wx
			   wy:(nonnull float *)wy
	{
	*wx = rx;
	*wy=  ry;
	return YES;
	}


/*****************************************************************************\
|* Create a texture of a given size.
\*****************************************************************************/
- (NSInteger)createTextureOfSize:(NSSize)size
	{
	/*************************************************************************\
	|* Create the GPU texture
	\*************************************************************************/
	SDL_GPUTextureUsageFlags flags = SDL_GPU_TEXTUREUSAGE_SAMPLER
								   | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET
								   | SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ
								   | SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE;

	return [self createTextureOfSize:size
							  format:SDL_PIXELFORMAT_BGRA32
						   withFlags:flags];
	}


/*****************************************************************************\
|* Create a texture using size, format, access-flags.
\*****************************************************************************/
- (NSInteger)createTextureOfSize:(NSSize)size
						  format:(SDL_PixelFormat)format
					   withFlags:(int)flags
	{
	NSMutableDictionary *props = NSMutableDictionary.new;
	props[AZRendererCreateWidth] = @(size.width);
	props[AZRendererCreateHeight] = @(size.height);
	props[AZRendererCreateFormat] = @(format);
	props[AZRendererCreateAccess] = @(flags);

	return [self createTextureWithProperties:props];
	}

/*****************************************************************************\
|* Create a texture using the given properties.
\*****************************************************************************/
- (NSInteger) createTextureWithProperties:(NSMutableDictionary *)props
	{
	NSNumber *pWidth 	= props[AZRendererCreateWidth];
	NSNumber *pHeight 	= props[AZRendererCreateHeight];
	NSNumber *pFlags	= props[AZRendererCreateAccess];
	NSNumber *pFormat	= props[AZRendererCreateFormat];
	if ((!pWidth) || (!pHeight) || (!pFlags) || (!pFormat))
		{
		SDL_Log("Insufficient properties to create texture");
		return -1;
		}

	NSSize size 			= NSMakeSize(pWidth.intValue, pHeight.intValue);
	int flags				= pFlags.intValue;
	SDL_PixelFormat format 	= (SDL_PixelFormat)pFormat.intValue;

	/*************************************************************************\
	|* Get a new unique texture id
	\*************************************************************************/
	NSNumber *tId = self.nextTextureId;

	AZTexture *tex = [AZTexture textureFor:self
								 withIndex:tId
									  size:size
									 format:format
									 usage:flags];

	/*************************************************************************\
	|* If we have a valid texture resource, then initialise and store it
	\*************************************************************************/
	if (tex)
		{
		_textures[tId] = tex;
		[self _updatePixelViewport:tex.view];
		[self _updatePixelClipRect:tex.view];

		NSInteger currentFocus = [self currentFocus];
		[self lockFocusOn:tId.integerValue];
		[self clear];
		[self restoreFocus:currentFocus];

		tex.properties = props;
		}
	else
		tId = @(-1);

	/*************************************************************************\
	|* Return the reference to the texture in the local map
	\*************************************************************************/
	return tId.integerValue;
	}

/*****************************************************************************\
|* Create a texture from a surface
\*****************************************************************************/
- (NSInteger)createTextureWithSurface:(nonnull struct SDL_Surface *)surface
	{
    if (!surface)
		{
        SDL_InvalidParamError("-createTextureWithSurface: surface");
		return -1;
		}

	/*************************************************************************\
	|* Determine if we need an alpha channel or not
	\*************************************************************************/
	BOOL isPixel		= SDL_ISPIXELFORMAT_ALPHA(surface->format);
	BOOL hasColourKey	= SDL_SurfaceHasColorKey(surface);
    BOOL needAlpha 		=  isPixel || hasColourKey;

    // If Palette contains alpha values, promotes to alpha format
    SDL_Palette *palette = SDL_GetSurfacePalette(surface);
    if (palette)
		{
        bool isOpaque, hasAlphaChannel;
        AZDetectPalette(palette, &isOpaque, &hasAlphaChannel);
        if (!isOpaque)
            needAlpha = true;
		}

 	/*************************************************************************\
	|* Try to have the best pixel format for the texture
	|* - No alpha, but a colorkey => promote to alpha
	\*************************************************************************/
    SDL_PixelFormat format 				= SDL_PIXELFORMAT_UNKNOWN;
    if ((!isPixel) && hasColourKey)
		{
        if (surface->format == SDL_PIXELFORMAT_XRGB8888)
			{
            for (NSInteger i = 0; i < _textureFormats.count; ++i)
				{
                if (_textureFormats[i].intValue == SDL_PIXELFORMAT_ARGB8888)
					{
                    format = SDL_PIXELFORMAT_ARGB8888;
                    break;
					}
				}
			}
		else if (surface->format == SDL_PIXELFORMAT_XBGR8888)
			{
            for (NSInteger i = 0; i < _textureFormats.count; ++i)
				{
                if (_textureFormats[i].intValue == SDL_PIXELFORMAT_ABGR8888)
					{
                    format = SDL_PIXELFORMAT_ABGR8888;
                    break;
					}
				}
			}
		}
	else
        // Exact match would be fine
		for (NSInteger i = 0; i < _textureFormats.count; ++i)
            if (_textureFormats[i].intValue == surface->format)
				{
                format = surface->format;
                break;
				}


 	/*************************************************************************\
	|* Try to have the best pixel format for the texture
	|* - Look for 10-bit pixel formats if needed
	\*************************************************************************/
	BOOL is10bit = SDL_ISPIXELFORMAT_10BIT(surface->format);
    if ((format == SDL_PIXELFORMAT_UNKNOWN) && is10bit)
		for (NSInteger i = 0; i < _textureFormats.count; ++i)
			if (SDL_ISPIXELFORMAT_10BIT(_textureFormats[i].intValue))
				{
                format = _textureFormats[i].intValue;
                break;
				}

 	/*************************************************************************\
	|* Try to have the best pixel format for the texture
	|* - Look for floating point pixel formats if needed
	\*************************************************************************/
	BOOL isFloat = is10bit || SDL_ISPIXELFORMAT_FLOAT(surface->format);
    if ((format == SDL_PIXELFORMAT_UNKNOWN) && isFloat)
		for (NSInteger i = 0; i < _textureFormats.count; ++i)
            if (SDL_ISPIXELFORMAT_FLOAT(_textureFormats[i].intValue))
				{
                format = _textureFormats[i].intValue;
                break;
				}

 	/*************************************************************************\
	|* Try to have the best pixel format for the texture
	|* - Fallback, choose a valid pixel format
	\*************************************************************************/
    if (format == SDL_PIXELFORMAT_UNKNOWN)
		{
        format = _textureFormats[0].intValue;
		for (NSInteger i = 0; i < _textureFormats.count; ++i)
			{
			BOOL is4cc = SDL_ISPIXELFORMAT_FOURCC(_textureFormats[i].intValue);
			BOOL alpha = SDL_ISPIXELFORMAT_ALPHA(_textureFormats[i].intValue);
			if ((!is4cc) && (alpha == needAlpha))
				{
                format = _textureFormats[i].intValue;
                break;
				}
			}
		}

 	/*************************************************************************\
	|* Figure out the colourspace
	\*************************************************************************/
	SDL_Colorspace texCs	= SDL_COLORSPACE_UNKNOWN;
    SDL_Colorspace cs 		= SDL_GetSurfaceColorspace(surface);
	BOOL isLinear 			= (cs == SDL_COLORSPACE_SRGB_LINEAR);
	BOOL pq = (SDL_COLORSPACETRANSFER(cs) == SDL_TRANSFER_CHARACTERISTICS_PQ);

    if (isLinear || pq)
        {
        if (SDL_ISPIXELFORMAT_FLOAT(format))
            texCs = SDL_COLORSPACE_SRGB_LINEAR;
        else if (SDL_ISPIXELFORMAT_10BIT(format))
            texCs = SDL_COLORSPACE_HDR10;
        else
            texCs = SDL_COLORSPACE_SRGB;
		}

	NSMutableDictionary *props = NSMutableDictionary.new;
	props[AZRendererCreateColourspace] = @(texCs);

	if (cs == texCs)
		{
		float whitepoint = AZGetSurfaceHDRHeadroom(cs);
		props[AZRendererCreateWhitePoint] = @(whitepoint);
		}
	float headroom = AZGetSurfaceSDRWhitePoint(cs);
	props[AZRendererCreateHeadroom] = @(headroom);
	props[AZRendererCreateFormat] = @(format);

	SDL_GPUTextureUsageFlags access = SDL_GPU_TEXTUREUSAGE_SAMPLER
								    | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET
								    | SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ
								    | SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE;
	props[AZRendererCreateAccess] = @(access);

	props[AZRendererCreateWidth] = @(surface->w);
	props[AZRendererCreateHeight] = @(surface->h);

	NSInteger tId = [self createTextureWithProperties:props];
	if (tId > 0)
		{
		if (![self _updateTexture:tId inRect:NSZeroRect FromSurface:surface])
			{
			[self _destroyTexture:tId];
			SDL_Log("Can't update the texture from the surface");
			return -1;
			}
		}

	/*************************************************************************\
	|* Return the reference to the texture in the local map
	\*************************************************************************/
	return tId;
	}


/*****************************************************************************\
|* Name a texture
\*****************************************************************************/
- (void) setName:(NSString *)name forTexture:(NSInteger)textureId
	{
	AZTexture *texture = _textures[@(textureId)];
	[texture setName:name];
	}


/*****************************************************************************\
|* Propagate the surface characteristics to a texture
\*****************************************************************************/
- (BOOL) _updateTexture:(NSInteger)textureId
				 inRect:(NSRect)rect
			FromSurface:(SDL_Surface *)surface
	{
	/*************************************************************************\
	|* Sanity checks...
	\*************************************************************************/
	AZTexture *texture = _textures[@(textureId)];
    if (texture == nil || surface == NULL)
        return NO;

	NSDictionary *texProps = texture.properties;
	if (texProps == nil)
		return NO;

    SDL_PropertiesID surfaceProps = SDL_GetSurfaceProperties(surface);
    if (surfaceProps == 0)
        return NO;

	if (NSEqualRects(rect, NSZeroRect))
		rect = NSMakeRect(0, 0, surface->w, surface->h);

	/*************************************************************************\
	|* Get some values from the properties
	\*************************************************************************/
	NSNumber *pFormat	 		= (NSNumber*)texProps[AZRendererCreateFormat];
	SDL_PixelFormat texFormat 	= (SDL_PixelFormat)pFormat.intValue;

//	NSNumber *pAccess			= (NSNumber *)texProps[AZRendererCreateAccess];
//	SDL_TextureAccess access	= (SDL_TextureAccess)pAccess.intValue;

	/*************************************************************************\
	|* Check the colourspace
	\*************************************************************************/
    SDL_Colorspace cs			= SDL_GetSurfaceColorspace(surface);
    SDL_Colorspace textureCS 	= cs;
	BOOL isLinear 				= (cs == SDL_COLORSPACE_SRGB_LINEAR);
	BOOL pq = (SDL_COLORSPACETRANSFER(cs) == SDL_TRANSFER_CHARACTERISTICS_PQ);

    if (isLinear || pq)
		{
        if (SDL_ISPIXELFORMAT_FLOAT(texFormat))
            textureCS = SDL_COLORSPACE_SRGB_LINEAR;
        else if (SDL_ISPIXELFORMAT_10BIT(texFormat))
            textureCS = SDL_COLORSPACE_HDR10;
        else
            textureCS = SDL_COLORSPACE_SRGB;
        }

	/*************************************************************************\
	|* Check if we need intermediate conversion
	\*************************************************************************/
    BOOL directUpdate;
    if ((texFormat == surface->format) && (textureCS == cs))
		{
		BOOL hasKey= SDL_SurfaceHasColorKey(surface);
        if (SDL_ISPIXELFORMAT_ALPHA(surface->format) && hasKey)
			{
            // Surface and Renderer formats are identical.
			// Intermediate conversion is needed to convert color key
			// to alpha (SDL_ConvertColorkeyToAlpha()).
			directUpdate = NO;
			}
		else
			{
            // Update Texture directly
			directUpdate = YES;
			}
		}
	else
		{
        // Surface and Renderer formats are different, it needs an
        // intermediate conversion.
        directUpdate = NO;
		}

	/*************************************************************************\
	|* Do it directly...
	\*************************************************************************/
    if (directUpdate)
		{
        if (SDL_MUSTLOCK(surface))
			{
            SDL_LockSurface(surface);
			[self _updateTexture:texture
						  inRect:rect
						  pixels:surface->pixels
						   pitch:surface->pitch];
            SDL_UnlockSurface(surface);
			}
		else
			{
			[self _updateTexture:texture
						  inRect:rect
						  pixels:surface->pixels
						   pitch:surface->pitch];
			}
		}

	/*************************************************************************\
	|* ... or indirectly...
	\*************************************************************************/
	else
		{
        // Set up a destination surface for the texture update
		SDL_Surface * temp = SDL_ConvertSurfaceAndColorspace(surface,
															 texFormat,
															 NULL,
															 textureCS,
															 surfaceProps);
        if (temp)
			{
			[self _updateTexture:texture
						  inRect:NSZeroRect
						  pixels:temp->pixels
						   pitch:temp->pitch];
            SDL_DestroySurface(temp);
			}
		else
            return NO;
		}


	/*************************************************************************\
	|* Transfer the mod-values and set the blendmode
	\*************************************************************************/
	Uint8 r, g, b, a;
	SDL_GetSurfaceColorMod(surface, &r, &g, &b);
	SDL_GetSurfaceAlphaMod(surface, &a);
	[self setTexture:textureId modR:r g:g b:b];
	[self setTexture:textureId modAlpha:a];


	if (SDL_SurfaceHasColorKey(surface))
		{
		// We converted to a texture with alpha format
		[self setTexture:textureId blendMode:SDL_BLENDMODE_BLEND];
		}
	else
		{
		SDL_BlendMode blendMode;
		SDL_GetSurfaceBlendMode(surface, &blendMode);
		[self setTexture:textureId blendMode:blendMode];
        }

    return YES;
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

/*****************************************************************************\
|* Update the data within a texture to the passed-in data
\*****************************************************************************/
- (BOOL) _updateTexture:(AZTexture *)texture
				 inRect:(NSRect)rect
				 pixels:(const void *)pixels
				  pitch:(int)pitch
	{
	/*************************************************************************\
	|* Sanity checks...
	\*************************************************************************/
    if (!pixels)
        return SDL_InvalidParamError("pixels");

    if (!pitch)
        return SDL_InvalidParamError("pitch");

	/*************************************************************************\
	|* Get the right rect
	\*************************************************************************/
	NSRect realRect = NSMakeRect(0, 0, texture.size.width, texture.size.height);
	if (!NSEqualRects(rect, NSZeroRect))
		{
		rect = NSIntersectionRect(rect, realRect);
		if (NSEqualRects(rect, NSZeroRect))
			return YES;
        }
	else
		rect = realRect;
		
	if ((realRect.size.width == 0) || (realRect.size.height == 0))
        return YES; // nothing to do.

	if (![self _flushRenderCommandsIfNeededForTexture:texture])
		return NO;

	/*************************************************************************\
	|* Figure out the data transfer sizes and check for overflow
	\*************************************************************************/
	SDL_PixelFormat fmt		= [AZTexture pixelFormatFor:texture.format];
	const Uint32 texturebpp = SDL_BYTESPERPIXEL(fmt);
    int rectH 				= NSHeight(rect);
    int rectW 				= NSWidth(rect);

    size_t rowSize, dataSize;
	BOOL ok = SDL_size_mul_check_overflow(rectW, texturebpp, &rowSize);
	if (!ok)
		return SDL_SetError("update size width overflow");
	ok = SDL_size_mul_check_overflow(rectH, rowSize, &dataSize);
 	if (!ok)
		return SDL_SetError("update size height overflow");

	/*************************************************************************\
	|* Create the transfer buffer
	\*************************************************************************/
    SDL_GPUTransferBufferCreateInfo tbci;
    SDL_zero(tbci);
    tbci.size = (Uint32)dataSize;
    tbci.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;

    SDL_GPUTransferBuffer *tbuf = SDL_CreateGPUTransferBuffer(_gpu, &tbci);
    if (tbuf == NULL)
        return SDL_SetError("cannot create transfer buffer");

	/*************************************************************************\
	|* Map the transfer buffer and copy data
	\*************************************************************************/
    Uint8 *output = SDL_MapGPUTransferBuffer(_gpu, tbuf, false);

    if ((size_t)pitch == rowSize)
        SDL_memcpy(output, pixels, dataSize);
    else
		{
        // FIXME is negative pitch supposed to work? If not, maybe
        // use SDL_GPUTextureTransferInfo::pixels_per_row instead of this
        const Uint8 *input = pixels;

        for (int i = 0; i < rectH; ++i)
			{
            SDL_memcpy(output, input, rowSize);
            output += rowSize;
            input += pitch;
			}
		}
    SDL_UnmapGPUTransferBuffer(_gpu, tbuf);

	/*************************************************************************\
	|* Use a copy-pass to upload
	\*************************************************************************/
    SDL_GPUCommandBuffer *cbuf = _state.commandBuffer;
    SDL_GPUCopyPass *cpass = SDL_BeginGPUCopyPass(cbuf);

    SDL_GPUTextureTransferInfo tex_src;
    SDL_zero(tex_src);
    tex_src.transfer_buffer = tbuf;
    tex_src.rows_per_layer = rectH;
    tex_src.pixels_per_row = rectW;

    SDL_GPUTextureRegion tex_dst;
    SDL_zero(tex_dst);
    tex_dst.texture = texture.texture;
    tex_dst.x = NSMinX(rect);
    tex_dst.y = NSMinY(rect);
    tex_dst.w = rectW;
    tex_dst.h = rectH;
    tex_dst.d = 1;

	/*************************************************************************\
	|* Housekeeping
	\*************************************************************************/
    SDL_UploadToGPUTexture(cpass, &tex_src, &tex_dst, NO);
    SDL_EndGPUCopyPass(cpass);
    SDL_ReleaseGPUTransferBuffer(_gpu, tbuf);

	return YES;
	}

/*****************************************************************************\
|* Flush the GPU command buffer if we're about to change the texture that is
|* already in use in the commandbuffer
\*****************************************************************************/
- (BOOL) _flushRenderCommandsIfNeededForTexture:(AZTexture *)texture
	{
	if (texture.lastCommandGen == _cmdGeneration)
        // the current command queue depends on this texture,
        // flush the queue now before it changes
		return [self _flushRenderCommands];

    return YES;
	}


/*****************************************************************************\
|* Return the current draw colour value as uint8_t's
\*****************************************************************************/
- (void)drawColourR:(nonnull uint8_t *)r
				  g:(nonnull uint8_t *)g
				  b:(nonnull uint8_t *)b
				  a:(nonnull uint8_t *)a
	{
	*r = _colour.R;
	*g = _colour.G;
	*b = _colour.B;
	*a = _colour.A;
	}


/*****************************************************************************\
|* Return the height of a given texture. Returns 0 if the texture cannot be
|* found
\*****************************************************************************/
- (float)heightOfTexture:(NSInteger)refId
	{
	AZTexture *texture = _textures[@(refId)];
	if (texture)
		return (int)texture.size.height;
	return 0;
	}

/*****************************************************************************\
|* Return the width of a given texture. Returns 0 if the texture cannot be
|* found
\*****************************************************************************/
- (float)widthOfTexture:(NSInteger)refId
	{
	AZTexture *texture = _textures[@(refId)];
	if (texture)
		return (int)texture.size.width;
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
		[self _setRenderTarget:target];
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

    if (![self _renderPresent])
        presented = NO;

    if (target)
		_target = target;
	}


/*****************************************************************************\
|* Return the current presentation mode
\*****************************************************************************/
- (int)presentationMode
	{
	return _logicalPresentMode;
	}


/*****************************************************************************\
|* Return the current presentation size
\*****************************************************************************/
- (NSSize)presentationSize
	{
	if (_logicalPresentMode == SDL_LOGICAL_PRESENTATION_DISABLED)
		return _view->view.size;
	return _logicalSize;
	}


/*****************************************************************************\
|* Retain a texture, bumping its use-count by +1
\*****************************************************************************/
- (void) retainTexture:(NSInteger)refId
	{
	AZTexture *texture = _textures[@(refId)];
	if (texture)
		texture.use ++;
	}

/*****************************************************************************\
|* Release a texture, removing it from the cache if its use-count == 0
\*****************************************************************************/
- (void) releaseTexture:(NSInteger)refId
	{
	AZTexture *texture = _textures[@(refId)];
	if (texture)
		{
		texture.use --;
		if (texture.use == 0)
			[self _destroyTexture:refId];
		}
	}

/*****************************************************************************\
|* Destroy a texture, removing it from the cache
\*****************************************************************************/
- (void) _destroyTexture:(NSInteger)refId
	{
	[_textures removeObjectForKey:@(refId)];
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


/*****************************************************************************\
|* Draw a line
\*****************************************************************************/
- (int)renderLineFrom:(NSPoint)p1 to:(NSPoint)p2
	{
	NSPoint pts[2] = {p1, p2};
	return [self _renderLines:pts count:2];
	}


/*****************************************************************************\
|* Draw a line
\*****************************************************************************/
- (int)renderLineFromX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2
	{
	return [self renderLineFrom:NSMakePoint(x1,y1) to:NSMakePoint(x2,y2)];
	}

/*****************************************************************************\
|* Draw lines
\*****************************************************************************/
- (int)renderLines:(NSPoint *)pts count:(int)count
	{
	return [self _renderLines:pts count:count];
	}


/*****************************************************************************\
|* Draw a point
\*****************************************************************************/
- (int)renderPointAt:(NSPoint)p
	{
	return [self _renderPoints:&p count:1];
	}


/*****************************************************************************\
|* Draw point
\*****************************************************************************/
- (int)renderPoints:(NSPoint *)pts count:(int)count
	{
	return [self _renderPoints:pts count:count];
	}


/*****************************************************************************\
|* Draw a point
\*****************************************************************************/
- (int)renderPointAtX:(int)x y:(int)y
	{
	NSPoint p = (NSPoint){x,y};
	return [self _renderPoints:&p count:1];
	}

/*****************************************************************************\
|* Draw a rectangle
\*****************************************************************************/
- (int)renderRect:(NSRect)r
	{
    NSPoint points[5];

    // If 'rect' == NSZeroRect, then outline the whole surface
	if (NSEqualRects(r, NSZeroRect))
		r = [self viewportSize];

    points[0].x = NSMinX(r);
    points[0].y = NSMinY(r);
    points[1].x = NSMaxX(r) - 1;
    points[1].y = NSMinY(r);
    points[2].x = NSMaxX(r) - 1;
    points[2].y = NSMaxY(r) - 1;
    points[3].x = NSMinX(r);
    points[3].y = NSMaxY(r) - 1;
    points[4].x = NSMinX(r);
    points[4].y = NSMinY(r);
	return [self renderLines:points count:5];
	}


/*****************************************************************************\
|* Return the renderer scale
\*****************************************************************************/
- (void)renderScaleX:(nonnull float *)xs y:(nonnull float *)ys
	{
	if (xs)
		*xs = _view->currentScale.x;
	if (ys)
		*ys = _view->currentScale.y;
	}


- (nonnull SDL_Renderer *)renderer
	{
	NSLog(@"%@:%@ should not be called", self, NSStringFromSelector(_cmd));
	return NULL;
	}


/*****************************************************************************\
|* Return the renderer name
\*****************************************************************************/
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


/*****************************************************************************\
|* Return the safe area for rendering into
\*****************************************************************************/
- (NSRect) safeAreaForRendering
	{
    if (_target || !_window)
        // The entire viewport is safe for rendering
        return [self _getRenderViewport];

	// Get the window safe rect
	SDL_Rect safeSDL;
	if (!SDL_GetWindowSafeArea(_window.window, &safeSDL))
		return NSZeroRect;


	// Convert the coordinates into the render space
	NSRect safe = NS_RECT(safeSDL);
	NSPoint min = safe.origin;
	NSPoint max = NSMakePoint(NSMaxX(safe), NSMaxY(safe));
	min = [self _renderCoordinatesFromWindow:min];
	max = [self _renderCoordinatesFromWindow:max];

	NSRect r = NSMakeRect(SDL_ceilf(min.x),
						  SDL_ceilf(min.y),
						  SDL_ceilf(max.x - min.x),
						  SDL_ceilf(max.y - min.y));

	// Clip with the viewport
	NSRect viewport = [self _getRenderViewport];
	return NSIntersectionRect(r, viewport);
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

/*****************************************************************************\
|* Set the draw colour
\*****************************************************************************/
- (void) setDrawColour:(nonnull AZColour *)colour
	{
	_colour = colour;
	}

/*****************************************************************************\
|* Set the draw colour using bytes
\*****************************************************************************/
- (int)setDrawColourToRed:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	_colour = [AZColour colourWithByteR:r g:g b:b a:a];
	return YES;
	}


/*****************************************************************************\
|* Set the logical presentation size
\*****************************************************************************/
- (void)setPresentationSize:(NSSize)size
					   mode:(SDL_RendererLogicalPresentation)mode
	{
	[self setLogicalPresentationWidth:size.width
							   height:size.height
								 mode:mode];
	}



/*****************************************************************************\
|* Set the blend mode on a texture
\*****************************************************************************/
- (int)setTexture:(NSInteger)refId blendMode:(SDL_BlendMode)blendMode
	{
    if (blendMode == SDL_BLENDMODE_INVALID)
        return SDL_InvalidParamError("invalid blendMode");

    if (![self _isSupportedBlendMode:blendMode])
        return SDL_Unsupported();

	AZTexture *texture = _textures[@(refId)];
	if (texture == nil)
		return SDL_InvalidParamError("unknown texture");

    texture.blendMode = blendMode;
    return YES;
	}


/*****************************************************************************\
|* Set the "mod" colour on a texture
\*****************************************************************************/
- (int)setTexture:(NSInteger)texId modR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b
	{
	AZTexture *texture = _textures[@(texId)];
	if (texture)
		{
		SDL_FColor colour = texture.colour;
		colour.r = r / 255.f;
		colour.g = g / 255.f;
		colour.b = b / 255.f;
		texture.colour = colour;
		return YES;
		}
	return NO;
	}

/*****************************************************************************\
|* Set the "mod" alpha on a texture
\*****************************************************************************/
- (int)setTexture:(NSInteger)texId modAlpha:(uint8_t)a
	{
	AZTexture *texture = _textures[@(texId)];
	if (texture)
		{
		SDL_FColor colour = texture.colour;
		colour.a = a / 255.f;
		texture.colour = colour;
		return YES;
		}
	return NO;
	}


// SDL_SetRenderViewport
/*****************************************************************************\
|* Set the viewport
\*****************************************************************************/
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

// SDL_GetRenderViewport
/*****************************************************************************\
|* Get the viewport
\*****************************************************************************/
- (NSRect) _getRenderViewport
	{
    NSRect rect;

	const AZViewState *view = _view;
	rect.origin.x = view->view.origin.x;
	rect.origin.y = view->view.origin.y;
	if (view->view.size.width >= 0)
		rect.size.width = view->view.size.width;
	else
		rect.size.width = SDL_ceilf(view->pixelW / view->currentScale.x);

	if (view->view.size.height >= 0)
		rect.size.height = view->view.size.height;
	else
		rect.size.height = SDL_ceilf(view->pixelH / view->currentScale.y);

    return rect;
	}

// SDL_SetRenderClipRect
/*****************************************************************************\
|* Set the clipRect
\*****************************************************************************/
- (BOOL) setClip:(NSRect)rect
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
/*****************************************************************************\
|* Set the rendering scale x,y
\*****************************************************************************/
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
|* Return a surface (which needs to be released by the caller) version of
|* the indicated texture
\*****************************************************************************/
- (nullable struct SDL_Surface *)surfaceFor:(NSInteger)refId
	{
	return [self surfaceFor:refId inRect:NSZeroRect];
	}

/*****************************************************************************\
|* Return a surface (which needs to be released by the caller) version of
|* the indicated texture, limited to a given rectangle
\*****************************************************************************/
- (nullable struct SDL_Surface *)surfaceFor:(NSInteger)refId inRect:(NSRect)rect
	{
	SDL_GPUFence *fence;

	AZTexture *texture = _textures[@(refId)];
	if (texture == nil)
		return NULL;

	if (NSEqualRects(rect, NSZeroRect))
		rect.size = texture.size;

	SDL_PixelFormat pixFmt 	= [AZTexture pixelFormatFor:texture.format];
    Uint32 bpp 				= SDL_BYTESPERPIXEL(pixFmt);
	int W 					= NSWidth(rect);
	int H 					= NSHeight(rect);

    size_t rowSize, imgSize;
	BOOL wBig = SDL_size_mul_check_overflow(W, bpp, &rowSize);
	BOOL hBig = SDL_size_mul_check_overflow(H, rowSize, &imgSize);
    if ((!wBig) || (!hBig))
		{
        SDL_SetError("read size overflow");
        return NULL;
		}

    SDL_Surface *surface = SDL_CreateSurface(W, H, pixFmt);
    if (!surface)
        return NULL;

    SDL_GPUTransferBufferCreateInfo tbci;
    SDL_zero(tbci);
    tbci.size = (Uint32)imgSize;
    tbci.usage = SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD;

    SDL_GPUTransferBuffer *tbuf = SDL_CreateGPUTransferBuffer(_gpu, &tbci);
    if (!tbuf)
        return NULL;


    SDL_GPUCopyPass *pass = SDL_BeginGPUCopyPass(_state.commandBuffer);

    SDL_GPUTextureRegion src;
    SDL_zero(src);
	src.texture = texture.texture;
    src.x = NSMinX(rect);
    src.y = NSMinY(rect);
    src.w = W;
    src.h = H;
    src.d = 1;

    SDL_GPUTextureTransferInfo dst;
    SDL_zero(dst);
    dst.transfer_buffer = tbuf;
    dst.rows_per_layer =H;
    dst.pixels_per_row = W;

    SDL_DownloadFromGPUTexture(pass, &src, &dst);
    SDL_EndGPUCopyPass(pass);

    fence = SDL_SubmitGPUCommandBufferAndAcquireFence(_state.commandBuffer);
    SDL_WaitForGPUFences(_gpu, YES, &fence, 1);
    SDL_ReleaseGPUFence(_gpu, fence);
    _state.commandBuffer = SDL_AcquireGPUCommandBuffer(_gpu);

    void *mapped = SDL_MapGPUTransferBuffer(_gpu, tbuf, NO);

    if ((size_t)surface->pitch == rowSize)
        SDL_memcpy(surface->pixels, mapped, imgSize);
    else
		{
        Uint8 *input = mapped;
        Uint8 *output = surface->pixels;

        for (int row = 0; row < H; ++row)
			{
            SDL_memcpy(output, input, rowSize);
            output += surface->pitch;
            input += rowSize;
			}
		}

    SDL_UnmapGPUTransferBuffer(_gpu, tbuf);
    SDL_ReleaseGPUTransferBuffer(_gpu, tbuf);

    return surface;
	}

/*****************************************************************************\
|* Synchronise to vsync, simulated via sleeping
\*****************************************************************************/
- (void)syncToVsync:(BOOL)vsync
	{
    if (![self _setVSync:vsync])
		_simulateVsync = vsync;

	_properties[AZRendererVSync] = @(vsync);
	}


/*****************************************************************************\
|* Get the blend mode from a texture
\*****************************************************************************/
- (int)texture:(NSInteger)refId blendMode:(nonnull SDL_BlendMode *)blendMode
	{
	AZTexture *texture = _textures[@(refId)];
	if (texture)
		{
		if (blendMode)
			*blendMode = texture.blendMode;
		return YES;
		}

	if (blendMode)
		*blendMode = SDL_BLENDMODE_INVALID;
	return NO;
	}


/*****************************************************************************\
|* Tile a texture across the current target at unity scale
\*****************************************************************************/
- (int)tileFrom:(NSInteger)textureId src:(NSRect)srcRect dst:(NSRect)dstRect
	{
	return [self tileFrom:textureId src:srcRect scale:1.f dst:dstRect];
	}


/*****************************************************************************\
|* Tile a texture across the current target
\*****************************************************************************/
- (int)tileFrom:(NSInteger)textureId
			src:(NSRect)src
		  scale:(float)scale
		    dst:(NSRect)dst
	{
	AZTexture *texture = _textures[@(textureId)];
	if (texture == nil)
		return NO;

    if (scale <= 0.0f)
        return SDL_InvalidParamError("scale");

	NSRect realSrc = NSMakeRect(0, 0, texture.size.width, texture.size.height);
	BOOL srcIsZero = (NSEqualRects(src, NSZeroRect));
	if (!srcIsZero)
		{
		NSRect intersection = NSIntersectionRect(src, realSrc);
		if (NSEqualRects(intersection, NSZeroRect))
            return YES;
		realSrc = intersection;
        }


	if (NSEqualRects(dst, NSZeroRect))
		dst = [self viewportSize];

    texture.lastCommandGen = _cmdGeneration;

    // See if we can use geometry with repeating texture coordinates
	BOOL atOrigin 	= NSEqualPoints(realSrc.origin, NSZeroPoint);
	BOOL fullExtent	= NSEqualSizes(realSrc.size, texture.size);
    if (srcIsZero || (atOrigin && fullExtent))
		return [self _tileWrappedFrom:texture src:realSrc scale:scale dst:dst];
	return [self _tileIterated:texture src:realSrc scale:scale dst:dst];
	}

/*****************************************************************************\
|* Internal method to tile a texture using iteration.
\*****************************************************************************/
- (int) _tileIterated:(AZTexture *)texture
				  src:(NSRect)src
				scale:(float)scale
				  dst:(NSRect)dst
	{
	float srcW			= NSWidth(src);
	float srcH			= NSHeight(src);
    float tileW		 	= srcW * scale;
    float tileH 		= srcH * scale;

    float floatCols;
    float todoW 		= SDL_modff(NSWidth(dst) / tileW, &floatCols);
    float floatRows;
    float todoH 		= SDL_modff(NSHeight(dst) / tileH, &floatRows);

    float todoSrcW 		= todoW * srcW;
    float todoSrcH 		= todoH * srcH;

    float todoDstW 		= todoW * tileW;
    float todoDstH 		= todoH * tileH;

	int rows 			= (int)floatRows;
    int cols 			= (int)floatCols;

    NSRect currSrc 		= src;
	NSRect currDst 		= NSMakeRect(0, dst.origin.y, tileW, tileH);
    for (int y = 0; y < rows; ++y)
		{
        currDst.origin.x = dst.origin.x;
        for (int x = 0; x < cols; ++x)
			{
			if (![self _renderTexture:texture src:currSrc dst:currDst])
                return NO;
            currDst.origin.x += currDst.size.width;
			}
        if (todoDstW > 0.0f)
			{
            currSrc.size.width = todoSrcW;
            currDst.size.width = todoDstW;
			if (![self _renderTexture:texture src:currSrc dst:currDst])
                return NO;
			currSrc.size.width = src.size.width;
            currDst.size.width = tileW;
			}
		currDst.origin.y += currDst.size.height;
		}

    if (todoDstH > 0.0f)
		{
        currSrc.size.height = todoSrcH;
        currDst.size.height = todoDstH;
        currDst.origin.x = dst.origin.x;
        for (int x = 0; x < cols; ++x)
			{
			if (![self _renderTexture:texture src:currSrc dst:currDst])
                return NO;

            currDst.origin.x += currDst.size.width;
			}

			if (todoDstW > 0.0f)
				{
				currSrc.size.width = todoSrcW;
				currDst.size.width = todoDstW;
				if (![self _renderTexture:texture src:currSrc dst:currDst])
					return NO;
			}
		}
    return true;
	}

/*****************************************************************************\
|* Internal method to tile a texture using geometry. This can't be used unless
|* the entire texture is being tiled
\*****************************************************************************/
- (int) _tileWrappedFrom:(AZTexture *)texture
					 src:(NSRect)src
				   scale:(float)scale
					 dst:(NSRect)dst
	{
	float xy[8];
	const int xyStride 		= 2 * sizeof(float);

	float uv[8];
	const int uvStride 		= 2 * sizeof(float);

	const int numVertices 	= 4;
    const int *indices 		= _rectIndexOrder;
	const int numIndices 	= 6;
	const int sizeIndices 	= 4;

	float minu = 0.f;
	float minv = 0.f;
	float maxu = NSWidth(dst)  / (NSWidth(src) * scale);
	float maxv = NSHeight(dst) / (NSHeight(src) * scale);

	float minx = NSMinX(dst);
	float miny = NSMinY(dst);
	float maxx = NSMaxX(dst);
	float maxy = NSMaxY(dst);

    uv[0] = minu;
    uv[1] = minv;
    uv[2] = maxu;
    uv[3] = minv;
    uv[4] = maxu;
    uv[5] = maxv;
    uv[6] = minu;
    uv[7] = maxv;

    xy[0] = minx;
    xy[1] = miny;
    xy[2] = maxx;
    xy[3] = miny;
    xy[4] = maxx;
    xy[5] = maxy;
    xy[6] = minx;
    xy[7] = maxy;

	SDL_FColor colour = texture.colour;
	return [self _queueCmdGeometryWithTexture:texture
										   xy:xy
									 xyStride:xyStride
									   colour:&colour
									  colourStride:0
										   uv:uv
									 uvStride:uvStride
								  numVertices:numVertices
									  indices:indices
								   numIndices:numIndices
								  sizeIndices:sizeIndices
									   scaleX:_view->currentScale.x
									   scaleY:_view->currentScale.y
								  addressMode:AZTextureAddressWrap];
	}


/*****************************************************************************\
|* UnLock focus, target the screen
\*****************************************************************************/
- (void)unlockFocus
	{
	[self _setRenderTarget:nil];
	}


/*****************************************************************************\
|* Unset the clip, setting to NSZeroRect also handles the boolean logic
\*****************************************************************************/
- (void)unsetClip
	{
	[self setClip:NSZeroRect];
	}


/*****************************************************************************\
|* Return the renderer viewport
\*****************************************************************************/
- (NSRect)viewport
	{
	return [self _getRenderViewport];
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

// MARK: Compute


/*****************************************************************************\
|* Run a compute pipeline
\*****************************************************************************/
- (BOOL) dispatchComputePipeline:(AZComputePipeline *)pipeline
				 withUniformData:(void *)data
						ofLength:(uint32_t)length
	{
	static BOOL warnedOfNilSwapchain 	= NO;
	BOOL ok 							= NO;

	// Make sure there isn't a render-pass currently in operation
	[self _flushRenderCommands];

	int numOutBufs = pipeline.numOutputBufferBindings;
	SDL_GPUStorageBufferReadWriteBinding sbo[numOutBufs];
	[pipeline populateOutputBufferBindings:sbo];

	int numInBufs = pipeline.numInputBufferBindings;
	SDL_GPUStorageBufferReadWriteBinding sbi[numInBufs];
	[pipeline populateInputBufferBindings:sbi];

	int numOutTex = pipeline.numOutputTextureBindings;
	SDL_GPUStorageTextureReadWriteBinding sto[numOutTex];
	[pipeline populateOutputTextureBindings:sto];

	int numInTex = pipeline.numInputTextureBindings;
	SDL_GPUStorageTextureReadWriteBinding sti[numOutTex];
	[pipeline populateInputTextureBindings:sti];

	int numSamp = pipeline.numSamplerBindings;
	SDL_GPUTextureSamplerBinding samp[numSamp];
	[pipeline populateSamplerBindings:samp];

	// Create a new compute pass
	SDL_GPUComputePass *pass = SDL_BeginGPUComputePass(
		_state.commandBuffer,
		sto, numOutTex,
		sbo, numOutBufs);

	if (_swapchain != NULL)
		{
		warnedOfNilSwapchain = NO;
		if (pass != NULL)
			{
			// Bind the pipeline itself
			SDL_BindGPUComputePipeline(pass, pipeline.pipeline);

			// Bind any input samplers
			if (numSamp > 0)
				SDL_BindGPUComputeSamplers(pass,
										   pipeline.samplerSlot,
										   samp,  numSamp);

			// Bind any input buffers
			if (numInBufs > 0)
				{
				SDL_GPUBuffer *buffers[numInBufs];
				for (int i=0; i<numInBufs; i++)
					buffers[i] = sbi[i].buffer;
				SDL_BindGPUComputeStorageBuffers(pass,
												 pipeline.bufferSlot,
												 buffers, numInBufs);
				}

			// Bind any input textures
			if (numInTex > 0)
				{
				SDL_GPUTexture *textures[numInTex];
				for (int i=0; i<numInTex; i++)
					textures[i] = sti[i].texture;
				SDL_BindGPUComputeStorageTextures(pass,
												  pipeline.textureSlot,
												  textures, numInTex);
				}
				
			// Push the uniform data
			SDL_PushGPUComputeUniformData(_state.commandBuffer,
										  pipeline.uniformSlot,
										  data,
										  length);

			SDL_DispatchGPUCompute(pass,
								   pipeline.jobs.x,
								   pipeline.jobs.y,
								   pipeline.jobs.z);

			SDL_EndGPUComputePass(pass);
			ok = YES;
			}
		else
			SDL_Log("Failed to create GPU compute pass: %s", SDL_GetError());
		}
	else if (!warnedOfNilSwapchain)
		{
		warnedOfNilSwapchain = YES;
		SDL_Log("Not running GPU compute while swapchain is nil");
		}

	return ok;
	}




// MARK: Private methods


/*****************************************************************************\
|* Sleep for a while to simulate a vsync
\*****************************************************************************/
- (void) _simulateVSync
	{
    Uint64  elapsed;
    const Uint64 interval = _vsyncIntervalNanos;
    if (!interval)
        // We can't do sub-ns delay, so just return here
        return;


    Uint64 now = SDL_GetTicksNS();
    elapsed = (now - _vsyncLastPresent);
    if (elapsed < interval)
		{
        Uint64 duration = (interval - elapsed);
        SDL_DelayPrecise(duration);
        now = SDL_GetTicksNS();
		}

    elapsed = (now - _vsyncLastPresent);
    if (!_vsyncLastPresent || elapsed > SDL_MS_TO_NS(1000))
        // It's been too long, reset the presentation timeline
        _vsyncLastPresent = now;
	else
        _vsyncLastPresent += (elapsed / interval) * interval;
    }



/*****************************************************************************\
|* Calculate a good vsync interval
\*****************************************************************************/
- (void) _calculateSimulatedVSyncInterval
	{
    SDL_DisplayID displayID = SDL_GetDisplayForWindow(_window.window);
    if (displayID == 0)
        displayID = SDL_GetPrimaryDisplay();

    const SDL_DisplayMode *mode = SDL_GetDesktopDisplayMode(displayID);

	int numerator 	= -1;
	int denominator	= -1;
	if (mode)
		{
		BOOL haveNumerator 		= (mode->refresh_rate_numerator > 0);
		BOOL haveDenominator	= (mode->refresh_rate_denominator > 0);

		if (haveNumerator && haveDenominator)
			{
			numerator = mode->refresh_rate_numerator;
			denominator = mode->refresh_rate_denominator;
			}
		}

	if ((numerator <= 0) || (denominator <= 0))
		{
        // Pick a good default refresh rate
        numerator 	= 60;
        denominator = 1;
		}
    // Flip numerator and denominator to change from framerate to interval
    _vsyncIntervalNanos = (SDL_NS_PER_SECOND * denominator) / numerator;
	}

/*****************************************************************************\
|* Attempt to set vsync mode
\*****************************************************************************/
- (BOOL) _setVSync:(BOOL)vsync
	{
    SDL_GPUPresentMode mode = SDL_GPU_PRESENTMODE_VSYNC;

	[self _choosePresentationMode:&mode vsync:vsync];

    if (mode != _renderData.swapchain.presentMode)
		{
        if (SDL_SetGPUSwapchainParameters(_gpu,
										  _window.window,
										  _renderData.swapchain.composition,
										  mode))
			{
            _renderData.swapchain.presentMode = mode;
			return YES;
			}
		return NO;
		}
    return YES;
	}

/*****************************************************************************\
|* Convert from window co-ords to render ones
\*****************************************************************************/
- (NSPoint) _renderCoordinatesFromWindow:(NSPoint)w
	{
	NSPoint r;

    // Convert from window coordinates to pixels within the window
    r.x = w.x * _dpiScale.x;
    r.y = w.y * _dpiScale.y;

    // Convert from pixels within the window to pixels within the view
	if (_logicalPresentMode != SDL_LOGICAL_PRESENTATION_DISABLED)
		{
		const NSRect src = _logicalSrcRect;
		const NSRect dst = _logicalDstRect;
		r.x = ((r.x - NSMinX(dst)) * NSWidth(src)) / NSWidth(dst);
		r.y = ((r.y - NSMinY(dst)) * NSHeight(src)) / NSHeight(dst);
		}

	const AZViewState *view = &_mainView;
	r.x = (r.x / view->scale.x) - view->view.origin.x;
	r.y = (r.y / view->scale.y) - view->view.origin.y;

	return r;
	}

/*****************************************************************************\
|* Set the viewpoint and scissor (clip)
\*****************************************************************************/
- (void) _setViewportAndScissor
	{
    SDL_SetGPUViewport(_state.renderPass, &_state.viewport);

    if (_state.scissorEnabled)
		{
		// Make sure the scissor doesn't extend beyond the bounds of the
		// current renderpass. Metal gets upset about that
		NSRect all 	= (_target == nil)
					? [self _getRenderViewport]
					: NSMakeRect(0,0,_target.size.width, _target.size.height);
		NSRect clip	= NS_RECT(_state.scissor);
		clip		= NSIntersectionRect(all, clip);

		if ((_target == _backbuffer) || (_target == nil))
			{
			NSRect back	= NSZeroRect;
			back.size 	= _backbuffer.size;
			clip 		= NSIntersectionRect(clip, back);
			}

		SDL_Rect scissor = SDL_RECT(clip);
        SDL_SetGPUScissor(_state.renderPass, &scissor);
        _state.scissorWasEnabled = YES;
		}
	else if (_state.scissorWasEnabled)
		{
		NSRect all  = NS_RECT(_state.viewport);
		NSRect clip	= NS_RECT(_state.scissor);
		clip		= NSIntersectionRect(all, clip);

		if ((_target == _backbuffer) || (_target == nil))
			{
			NSRect back	= NSZeroRect;
			back.size 	= _backbuffer.size;
			clip 		= NSIntersectionRect(clip, back);
			}

		SDL_Rect scissor = SDL_RECT(clip);
		SDL_SetGPUScissor(_state.renderPass, &scissor);
        _state.scissorWasEnabled = NO;
		}
	}

/*****************************************************************************\
|* Restart a renderpass
\*****************************************************************************/
- (SDL_GPURenderPass *) _restartRenderPass
	{
    if (_state.renderPass)
		{
		SDL_EndGPURenderPass(_state.renderPass);
		}

	_state.renderPass = SDL_BeginGPURenderPass(_state.commandBuffer,
											   &_state.colourAttachment,
											   1,
											   NULL);

    // *** FIXME ***
    // This is busted. We should be able to know which load op to use.
    // LOAD is incorrect behavior most of the time, unless we had to break
    //  a render pass.
    // -cosmonaut
    _state.colourAttachment.load_op = SDL_GPU_LOADOP_LOAD;
    _state.scissorWasEnabled 		= NO;

    return _state.renderPass;
	}

/*****************************************************************************\
|* Get a colour out of a command in the queue
\*****************************************************************************/
- (SDL_FColor) _drawColourForCommand:(AZRenderCommand *)cmd
	{
    SDL_FColor colour = cmd.colour;

	if ([self _renderingLinearSpace])
		[self _convertToLinear:&colour];

    colour.r *= cmd.colourScale;
    colour.g *= cmd.colourScale;
    colour.b *= cmd.colourScale;

    return colour;
	}

/*****************************************************************************\
|* Upload the vertices to the GPU
\*****************************************************************************/
- (BOOL) _uploadVertices
	{
	SDL_GPUCopyPass *pass	= NULL;
	void *staging			= NULL;

	// Quick sanity check
    if (_vertexDataInUse == 0)
        return YES;


	// Resize the buffers upwards if we need to
    if (_vertexDataInUse > _vertices.bufferSize)
		{
		[self _releaseVertexBuffer];
		if (![self _initialiseVertexBuffer:_vertexDataInUse])
            return NO;
        }

	// Push through the staging buffer
	staging = SDL_MapGPUTransferBuffer(_gpu, _vertices.transferBuf, YES);

    SDL_memcpy(staging, _vertexData, _vertexDataInUse);
    SDL_UnmapGPUTransferBuffer(_gpu, _vertices.transferBuf);

	// Create the copy-pass and execute
	pass = SDL_BeginGPUCopyPass(_state.commandBuffer);
    if (!pass)
        return NO;

    SDL_GPUTransferBufferLocation src;
    SDL_zero(src);
    src.transfer_buffer = _vertices.transferBuf;

    SDL_GPUBufferRegion dst;
    SDL_zero(dst);
    dst.buffer 	= _vertices.buffer;
    dst.size 	= _vertexDataInUse;

    SDL_UploadToGPUBuffer(pass, &src, &dst, true);
    SDL_EndGPUCopyPass(pass);

    return YES;
	}

/*****************************************************************************\
|* Upload data to a buffer
\*****************************************************************************/
- (BOOL) upload:(NSData *)data to:(AZGPUBuffer *)buffer
	{
	SDL_GPUCopyPass *pass	= NULL;
	void *staging			= NULL;

	// Quick sanity check
	if (buffer.size < data.length)
        {
        SDL_Log("Data of size %llu does not fit into buffer of size %llu",
				(uint64_t)data.length, (uint64_t)buffer.size);
        return NO;
		}

	// Flush any current render-pass commands
	[self _flushRenderCommands];

	// Create a transfer buffer
    SDL_GPUTransferBufferCreateInfo tbci;
    SDL_zero(tbci);
	tbci.size = (Uint32)data.length;
    tbci.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;

    SDL_GPUTransferBuffer *tbuf = SDL_CreateGPUTransferBuffer(_gpu, &tbci);
    if (tbuf == NULL)
        {
        SDL_Log("cannot create transfer buffer for upload to GPU");
        return NO;
		}

	// Push through the staging buffer
	staging = SDL_MapGPUTransferBuffer(_gpu, tbuf, NO);
    SDL_memcpy(staging, data.bytes, data.length);
    SDL_UnmapGPUTransferBuffer(_gpu, tbuf);

	// Create the copy-pass and execute
	SDL_GPUCommandBuffer *cbuf = SDL_AcquireGPUCommandBuffer(_gpu);
	pass = SDL_BeginGPUCopyPass(cbuf);
    if (!pass)
        return NO;

    SDL_GPUTransferBufferLocation src;
    SDL_zero(src);
    src.transfer_buffer = tbuf;

    SDL_GPUBufferRegion dst;
    SDL_zero(dst);
    dst.buffer 	= buffer.buffer;
    dst.size 	= (uint32_t) data.length;

    SDL_UploadToGPUBuffer(pass, &src, &dst, NO);
    SDL_EndGPUCopyPass(pass);
	SDL_SubmitGPUCommandBuffer(cbuf);
	SDL_ReleaseGPUTransferBuffer(_gpu, tbuf);

    return YES;
	}


/*****************************************************************************\
|* Download data from a buffer
\*****************************************************************************/
- (NSData *) download:(AZGPUBuffer *)buffer
	{
	SDL_GPUCopyPass *pass	= NULL;

	NSMutableData *data 	= [NSMutableData dataWithLength:buffer.size];

	// Flush any current-render-pass commands
	[self _flushRenderCommands];

	// Create a transfer buffer
    SDL_GPUTransferBufferCreateInfo tbci;
    SDL_zero(tbci);
	tbci.size 		= (Uint32)data.length;
	tbci.usage		= SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD;

    SDL_GPUTransferBuffer *tbuf = SDL_CreateGPUTransferBuffer(_gpu, &tbci);
    if (tbuf == NULL)
        {
        SDL_Log("cannot create transfer buffer for download from GPU");
        return nil;
		}

	// Create the copy-pass and configure
	SDL_GPUCommandBuffer *cbuf = SDL_AcquireGPUCommandBuffer(_gpu);
	pass = SDL_BeginGPUCopyPass(cbuf);
    if (!pass)
        return nil;

    SDL_GPUBufferRegion src;
    src.buffer 	= buffer.buffer;
    src.offset  = 0;
    src.size 	= (uint32_t) data.length;

    SDL_GPUTransferBufferLocation dst;
    dst.transfer_buffer = tbuf;
    dst.offset 			= 0;

	// Copy the data from GPU buffer to transfer buffer
	SDL_DownloadFromGPUBuffer(pass, &src, &dst);
    SDL_EndGPUCopyPass(pass);

	SDL_GPUFence* fence = SDL_SubmitGPUCommandBufferAndAcquireFence(cbuf);
	SDL_WaitForGPUFences(_gpu, true, &fence, 1);
	SDL_ReleaseGPUFence(_gpu, fence);

	// Copy from the staging buffer into the NSData
	void *staging 	= SDL_MapGPUTransferBuffer(_gpu, tbuf, NO);
	SDL_memcpy(data.mutableBytes, staging, data.length);
    SDL_UnmapGPUTransferBuffer(_gpu, tbuf);
	SDL_ReleaseGPUTransferBuffer(_gpu, tbuf);

	return data;
	}


/*****************************************************************************\
|* Clear a buffer to a value
\*****************************************************************************/
- (BOOL) clearBuffer:(AZGPUBuffer *)buffer to:(uint8_t)value
	{
	SDL_GPUCopyPass *pass	= NULL;
	void *staging			= NULL;

	// Flush any current render-pass commands
	[self _flushRenderCommands];

	// Create a transfer buffer
    SDL_GPUTransferBufferCreateInfo tbci;
    SDL_zero(tbci);
	tbci.size = (Uint32)buffer.size;
    tbci.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;

    SDL_GPUTransferBuffer *tbuf = SDL_CreateGPUTransferBuffer(_gpu, &tbci);
    if (tbuf == NULL)
        {
        SDL_Log("cannot create transfer buffer for upload to GPU");
        return NO;
		}

	// Push through the staging buffer
	staging = SDL_MapGPUTransferBuffer(_gpu, tbuf, NO);
	SDL_memset(staging, value, buffer.size);
    SDL_UnmapGPUTransferBuffer(_gpu, tbuf);

	// Create the copy-pass and execute
	SDL_GPUCommandBuffer *cbuf = SDL_AcquireGPUCommandBuffer(_gpu);
	pass = SDL_BeginGPUCopyPass(cbuf);
    if (!pass)
        return NO;

    SDL_GPUTransferBufferLocation src;
    SDL_zero(src);
    src.transfer_buffer = tbuf;

    SDL_GPUBufferRegion dst;
    SDL_zero(dst);
    dst.buffer 	= buffer.buffer;
    dst.size 	= (uint32_t) buffer.size;

    SDL_UploadToGPUBuffer(pass, &src, &dst, NO);
    SDL_EndGPUCopyPass(pass);
	SDL_SubmitGPUCommandBuffer(cbuf);
	SDL_ReleaseGPUTransferBuffer(_gpu, tbuf);

    return YES;
	}


/*****************************************************************************\
|* Create the back-buffer
\*****************************************************************************/
- (BOOL) _createBackBufferOfSize:(NSSize)size format:(SDL_PixelFormat)fmt
	{
	SDL_GPUTextureUsageFlags flags = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET
								   | SDL_GPU_TEXTUREUSAGE_SAMPLER;

	NSInteger identifier 	= [self createTextureOfSize:size
											     format:fmt
											  withFlags:flags];

	_backbuffer = _textures[@(identifier)];
	if (!_backbuffer)
        return NO;

	[self _updateMainViewDimensions];
	[self _updatePixelClipRect:&_mainView];
    return YES;
	}

/*****************************************************************************\
|* Select the presentation mode
\*****************************************************************************/
- (void) _choosePresentationMode:(out SDL_GPUPresentMode*)presentMode
						   vsync:(BOOL)vsync
	{
    SDL_GPUPresentMode mode;

    if (!vsync)
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
|* Create the vertex buffer
\*****************************************************************************/
- (BOOL) _initialiseVertexBuffer:(Uint32)size
	{
    SDL_GPUBufferCreateInfo bci;
    SDL_zero(bci);
    bci.size = size;
    bci.usage = SDL_GPU_BUFFERUSAGE_VERTEX;

    _vertices.buffer = SDL_CreateGPUBuffer(_gpu, &bci);

    if (!_vertices.buffer)
        return NO;

    SDL_GPUTransferBufferCreateInfo tbci;
    SDL_zero(tbci);
    tbci.size = size;
    tbci.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;

    _vertices.transferBuf = SDL_CreateGPUTransferBuffer(_gpu, &tbci);

    if (!_vertices.transferBuf)
        return NO;

    return YES;
	}


/*****************************************************************************\
|* Release the current vertex buffers
\*****************************************************************************/
- (void) _releaseVertexBuffer
	{
    if (_vertices.buffer)
        SDL_ReleaseGPUBuffer(_gpu, _vertices.buffer);

    if (_vertices.transferBuf)
        SDL_ReleaseGPUTransferBuffer(_gpu, _vertices.transferBuf);

    _vertices.bufferSize = 0;
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

		{AZTextureAddressWrap,
		 SDL_SCALEMODE_NEAREST,
		 SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
		 SDL_GPU_FILTER_NEAREST,
		 SDL_GPU_SAMPLERMIPMAPMODE_NEAREST,
		 0 },

		{AZTextureAddressWrap,
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
		[sampler buildWithRenderer:self];
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
			_shaders.fragShaders[identifier.intValue] = shader;
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
			_shaders.vertShaders[identifier.intValue] = shader;
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
    int method 		 = (hint) ? SDL_atoi(hint) : AZRenderLineMethodLines;

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
        _mainView.logicalOffset.x = _mainView.logicalOffset.y = 0.f;
        _mainView.logicalScale.x  = _mainView.logicalScale.y  = 1.f;

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
		NSRect origClip 	= NSZeroRect;
		if (doClip)
			origClip = view->clip;

        // trample some state.
		[self setLogicalPresentationWidth:logicalW
								   height:logicalH
									 mode:SDL_LOGICAL_PRESENTATION_DISABLED];

		[self setViewport:NSZeroRect];
        if (doClip)
			[self setClip:NSZeroRect];
		[self setScaleX:1.f y:1.f];

        // draw the borders.
        [self _renderLogicalBorders];


        // now set everything back.
        _logicalPresentMode 	= mode;
		[self setViewport:origViewport];

        if (doClip)
 			[self setClip:origClip];

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

    if (colourspace == SDL_COLORSPACE_SRGB_LINEAR)
        return YES;

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

/*****************************************************************************\
|* Render a texture
\*****************************************************************************/
- (BOOL) _renderTexture:(AZTexture *)texture src:(NSRect)src dst:(NSRect)dst
	{
	NSRect full = NSMakeRect(0,0,texture.size.width, texture.size.height);
	src			= NSIntersectionRect(src, full);

	if (NSEqualRects(src, NSZeroRect))
		src = full;
	if (NSEqualRects(dst, NSZeroRect))
		dst = full;
		
    const float sx = _view->currentScale.x;
    const float sy = _view->currentScale.y;

	float xy[8];
	const int xyStride 		= 2 * sizeof(float);

	float uv[8];
	const int uvStride 		= 2 * sizeof(float);

	const int numVertices 	= 4;
    const int *indices 		= _rectIndexOrder;
	const int numIndices 	= 6;
	const int sizeIndices 	= 4;

	float minu = src.origin.x / texture.size.width;
	float minv = src.origin.y / texture.size.height;
	float maxu = NSMaxX(src)  / texture.size.width;
	float maxv = NSMaxY(src)  / texture.size.height;

	float minx = NSMinX(dst);
	float miny = NSMinY(dst);
	float maxx = NSMaxX(dst);
	float maxy = NSMaxY(dst);

	uv[0] = minu;
	uv[1] = minv;
	uv[2] = maxu;
	uv[3] = minv;
	uv[4] = maxu;
	uv[5] = maxv;
	uv[6] = minu;
	uv[7] = maxv;

	xy[0] = minx;
	xy[1] = miny;
	xy[2] = maxx;
	xy[3] = miny;
	xy[4] = maxx;
	xy[5] = maxy;
	xy[6] = minx;
	xy[7] = maxy;

	texture.lastCommandGen = _cmdGeneration;

	SDL_FColor colour = texture.colour;
	return [self _queueCmdGeometryWithTexture:texture
										   xy:xy
									 xyStride:xyStride
									   colour:&colour
									  colourStride:0
										   uv:uv
									 uvStride:uvStride
								  numVertices:numVertices
									  indices:indices
								   numIndices:numIndices
								  sizeIndices:sizeIndices
									   scaleX:sx
									   scaleY:sy
								  addressMode:AZTextureAddressClamp];
	}

/*****************************************************************************\
|* Set the render target to a texture (if specified) or to the window (if
|* the texture is nil)
\*****************************************************************************/
- (BOOL) _setRenderTarget:(nullable AZTexture *)texture
	{
    if (texture)
        if ((texture.flags & SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) == 0)
            return SDL_SetError("Texture not created with "
								"SDL_GPU_TEXTUREUSAGE_COLOR_TARGET");

    if (texture == _target)
		{
        // Nothing to do!
        return YES;
		}

	// time to send everything to the GPU!
	[self _flushRenderCommands];

	[_targetLock lock];
		{
		_target = texture;
		if (texture)
			_view = [texture view];
		else
			_view = &_mainView;

		[self _updateColourScale];

		_state.renderTarget = texture;
		}
	[_targetLock unlock];

	if (![self _queueCmdSetViewport])
		return NO;

	if (![self _queueCmdSetClipRect])
		return NO;

    // All set!
    return YES;
	}

/*****************************************************************************\
|* Draw primitives
\*****************************************************************************/
- (void) _pushUniformsFor:(AZRenderCommand *)cmd
	{
    GPU_ShaderUniformData uniforms;
    SDL_zero(uniforms);
    uniforms.mvp.m[0][0] = 2.0f / _state.viewport.w;
    uniforms.mvp.m[1][1] = -2.0f / _state.viewport.h;
    uniforms.mvp.m[2][2] = 1.0f;
    uniforms.mvp.m[3][0] = -1.0f;
    uniforms.mvp.m[3][1] = 1.0f;
    uniforms.mvp.m[3][3] = 1.0f;

    uniforms.colour = _state.drawColour;

    if (cmd.texture)
		{
		uniforms.textureSize[0] = cmd.texture.size.width;
        uniforms.textureSize[1] = cmd.texture.size.height;
		}

    SDL_PushGPUVertexUniformData(_state.commandBuffer,
								 0,
								 &uniforms,
								 sizeof(uniforms));
	}

/*****************************************************************************\
|* Draw primitives
\*****************************************************************************/
- (void) _draw:(AZRenderCommand *)cmd
		 count:(Uint32)numVerts
	    offset:(Uint32)offset
	      type:(SDL_GPUPrimitiveType)prim
	{
	BOOL notRender	= !_state.renderPass;
	BOOL isClear   	= _state.colourAttachment.load_op == SDL_GPU_LOADOP_CLEAR;

    if (notRender|| isClear)
        [self _restartRenderPass];

    AZVertexShaderID 	v_shader;
    AZFragmentShaderID 	f_shader;
    SDL_GPURenderPass *pass = _state.renderPass;

    if (prim == SDL_GPU_PRIMITIVETYPE_TRIANGLELIST)
		{
        if (cmd.texture)
			{
            v_shader = AZVertShaderTriTexture;
            f_shader = cmd.texture.shader;
			}
		else
			{
            v_shader = AZVertShaderTriColour;
            f_shader = AZFragShaderColour;
			}
		}
	else
		{
        v_shader = AZVertShaderLinePoint;
        f_shader = AZFragShaderColour;
		}

    AZPipelineParameters pipeParams;
    SDL_zero(pipeParams);
    pipeParams.blendMode 		= cmd.blendMode;
    pipeParams.vertShader 		= v_shader;
    pipeParams.fragShader 		= f_shader;
    pipeParams.primitiveType	= prim;
	pipeParams.attachmentFormat = (_state.renderTarget)
								? _state.renderTarget.format
								: _backbuffer.format;

	AZRenderPipeline *pipe = [AZRenderPipeline withRenderer:self
													shaders:&_shaders
													 params:&pipeParams];
    if (!pipe)
        return;

	[self _setViewportAndScissor];

	SDL_BindGPUGraphicsPipeline(_state.renderPass, pipe.pipeline);

	if (cmd.texture)
		{
        SDL_GPUTextureSamplerBinding samplerBind;
        SDL_zero(samplerBind);
        AZSampler *sampler  = SAMPLER(cmd.addressMode, cmd.texture.scaleMode);
		samplerBind.sampler = sampler.sampler;
        samplerBind.texture = cmd.texture.texture;
        SDL_BindGPUFragmentSamplers(pass, 0, &samplerBind, 1);
    }

    SDL_GPUBufferBinding bufferBind;
    SDL_zero(bufferBind);
    bufferBind.buffer = _vertices.buffer;
    bufferBind.offset = offset;

    SDL_BindGPUVertexBuffers(pass, 0, &bufferBind, 1);
	[self _pushUniformsFor:cmd];
    SDL_DrawGPUPrimitives(_state.renderPass, numVerts, 1, 0, 0);
	}


// GPU_RenderPresent
/*****************************************************************************\
|* GPU side of the -present call
\*****************************************************************************/
- (BOOL) _renderPresent
	{
	SDL_GPUTextureFormat fmt;
    Uint32 swapW, swapH;
    BOOL result = SDL_WaitAndAcquireGPUSwapchainTexture(
						_state.commandBuffer,
						_window.window,
						&_swapchain,
						&swapW,
						&swapH);

    if (!result)
        SDL_LogError(SDL_LOG_CATEGORY_RENDER,
					 "Failed to acquire swapchain texture: %s",
					 SDL_GetError());


    if (_swapchain != NULL)
		{
        SDL_GPUBlitInfo blitInfo;
        SDL_zero(blitInfo);

        blitInfo.source.texture 		= _backbuffer.texture;
        blitInfo.source.w 				= _backbuffer.size.width;
        blitInfo.source.h 				= _backbuffer.size.height;
        blitInfo.destination.texture 	= _swapchain;
        blitInfo.destination.w 			= swapW;
        blitInfo.destination.h 			= swapH;
        blitInfo.load_op 				= SDL_GPU_LOADOP_DONT_CARE;
        blitInfo.filter 				= SDL_GPU_FILTER_LINEAR;

        SDL_BlitGPUTexture(_state.commandBuffer, &blitInfo);

        SDL_SubmitGPUCommandBuffer(_state.commandBuffer);
	    _state.commandBuffer = SDL_AcquireGPUCommandBuffer(_gpu);

		BOOL diffW = (swapW != (Uint32) _backbuffer.size.width);
		BOOL diffH = (swapH != (Uint32) _backbuffer.size.height);

        if (diffW || diffH)
			{
			[self releaseTexture:_backbuffer.index.integerValue];
			_backbuffer = nil;

			NSSize size = NSMakeSize(swapW, swapH);
			fmt = SDL_GetGPUSwapchainTextureFormat(_gpu, _window.window);

			SDL_PixelFormat pFmt = [AZTexture pixelFormatFor:fmt];
			[self _createBackBufferOfSize:size format:pFmt];
			}
		}
	else
		{
        SDL_SubmitGPUCommandBuffer(_state.commandBuffer);
	    _state.commandBuffer = SDL_AcquireGPUCommandBuffer(_gpu);
		}

    return YES;
	}

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
	if (![self _uploadVertices])
		return NO;

    _state.colourAttachment.load_op = SDL_GPU_LOADOP_LOAD;

    if (_target)
        _state.colourAttachment.texture = _target.texture;
	else
		_state.colourAttachment.texture = _backbuffer.texture;


    if (!_state.colourAttachment.texture)
        return SDL_SetError("Render target texture is NULL");

	NSInteger numCmds = _commandQ.count;
	NSInteger last    = numCmds - 1;

	for (NSInteger cmdId = 0; cmdId < numCmds; cmdId ++)
		{
		AZRenderCommand *cmd = _commandQ[cmdId];

        switch (cmd.command)
			{
			case AZRenderCmdSetDrawColour:
				{
            	_state.drawColour = [self _drawColourForCommand:cmd];
				break;
				}

			case AZRenderCmdSetViewport:
				{
				_state.viewport.x 	= cmd.rect.origin.x;
				_state.viewport.y 	= cmd.rect.origin.y;
				_state.viewport.w	= cmd.rect.size.width;
				_state.viewport.h	= cmd.rect.size.height;
				break;
				}

			case AZRenderCmdSetCliprect:
				{
				_state.scissor.x 		= _state.viewport.x + cmd.rect.origin.x;
				_state.scissor.y 		= _state.viewport.y + cmd.rect.origin.y;
				_state.scissor.w		= cmd.rect.size.width;
				_state.scissor.h		= cmd.rect.size.height;
				_state.scissorEnabled	= cmd.enabled;
				break;
				}

			case AZRenderCmdClear:
				{
				_state.colourAttachment.clear_color = [self _drawColourForCommand:cmd];
            	_state.colourAttachment.load_op 	= SDL_GPU_LOADOP_CLEAR;
				break;
				}

			case AZRenderCmdFillRects:
				// unused
				break;

			case AZRenderCmdCopy:
				// unused
				break;

			case AZRenderCmdCopyExtended:
				// unused
				break;

			case AZRenderCmdDrawLines:
				{
				Uint32 count 	= (Uint32)cmd.count;
				Uint32 offset 	= (Uint32)cmd.first;

				if (count > 2)
					{
					// joined lines cannot be grouped
					[self _draw:cmd
						  count:count
						 offset:offset
						   type:SDL_GPU_PRIMITIVETYPE_LINESTRIP];
					}
				else
					{
					// let's group non joined lines
                	AZRenderCommand *nextcmd 	= (cmdId == last)
												? nil
												: _commandQ[cmdId+1];
					SDL_BlendMode thisblend = cmd.blendMode;

					while (nextcmd)
						{
						const AZRenderCommandType nextType = nextcmd.command;
						if (nextType != AZRenderCmdDrawLines)
							// can't go any further on this draw call,
							// different render command up next.
							break;

						else if (nextcmd.count != 2)
							// can't go any further on this draw call,
							// those are joined lines
							break;

						else if (nextcmd.blendMode != thisblend)
							// can't go any further on this draw call,
							// different blendmode copy up next.
							break;

						else
							{
							// we can combine copy operations here.
							// Mark this one as the furthest okay command.
							count += (Uint32)nextcmd.count;
							}
						cmdId ++;
						nextcmd = (cmdId == last) ? nil : _commandQ[cmdId+1];
						}

					[self _draw:cmd
						  count:count
						 offset:offset
						   type:SDL_GPU_PRIMITIVETYPE_LINELIST];
					}
				break;
				}

			case AZRenderCmdDrawPoints:
			case AZRenderCmdGeometry:
				{
				// as long as we have the same copy command in a row, with the
				// same texture, we can combine them all into a single draw call
				AZTexture *thistexture 				= cmd.texture;
				SDL_BlendMode thisblend 			= cmd.blendMode;
				const AZRenderCommandType thisType 	= cmd.command;
				AZRenderCommand *nextcmd 			= (cmdId == last)
													? nil
													: _commandQ[cmdId+1];;
				Uint32 count 						= (Uint32)cmd.count;
				Uint32 offset 						= (Uint32)cmd.first;

				while (nextcmd)
					{
					const AZRenderCommandType nextType = nextcmd.command;
					BOOL diffTexture = (nextcmd.texture != thistexture);
					BOOL diffBlend   = (nextcmd.blendMode != thisblend);

					if (nextType != thisType)
						// can't go any further on this draw call,
						// different render command up next.
						break;

					else if (diffTexture || diffBlend)
						// FIXME should we check address mode too?
						// can't go any further on this draw call,
						// different texture/blendmode copy up next.
						break;


					// we can combine copy operations here.
					// Mark this one as the furthest okay command.
					count += (Uint32)nextcmd.count;
					cmdId ++;
					nextcmd = (cmdId == last) ? nil : _commandQ[cmdId+1];
					}

				// Default to SDL_RENDERCMD_GEOMETRY
				SDL_GPUPrimitiveType prim = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
				if (thisType == AZRenderCmdDrawPoints)
					prim = SDL_GPU_PRIMITIVETYPE_POINTLIST;

				[self _draw:cmd count:count offset:offset type:prim];
				break;
				}

			case AZRenderCmdNoOp:
				break;
			}
		}

	if (_state.colourAttachment.load_op == SDL_GPU_LOADOP_CLEAR)
		[self _restartRenderPass];

	if (_state.renderPass)
		{
        SDL_EndGPURenderPass(_state.renderPass);
        _state.renderPass = NULL;
		}

    return true;
	}


/*****************************************************************************\
|* Set the swapchain parameters
\*****************************************************************************/
- (BOOL) setSwapchainParameters:(SDL_GPUSwapchainComposition)composition
					presentMode:(SDL_GPUPresentMode) presentMode
	{
	return SDL_SetGPUSwapchainParameters(_gpu,
										 _window.window,
										 composition,
										 presentMode);
	}

/*****************************************************************************\
|* Set how many frames are allowed to be in-flight
\*****************************************************************************/
- (BOOL) setAllowedFramesInFlight:(uint32_t)number
	{
	return SDL_SetGPUAllowedFramesInFlight(_gpu, number);
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

// MARK: Line and point drawing


/*****************************************************************************\
|* Top level entry point for point drawing
\*****************************************************************************/
- (BOOL) _renderPoints:(NSPoint *)points count:(int)count
	{
    if (!points)
        return SDL_InvalidParamError("SDL_RenderPoints(): nil points");

    if (count < 1)
        return YES;

    if ((_view->currentScale.x != 1.0f) || (_view->currentScale.y != 1.0f))
        return [self _renderRectsFromPoints:points count:count];

    return [self _queueCmdDrawPoints:points count:count];
	}


#define ADD_TRIANGLE(i1, i2, i3)        \
    *ptrIndices++ = curIndex + (i1);    \
    *ptrIndices++ = curIndex + (i2);    \
    *ptrIndices++ = curIndex + (i3);    \
    numIndices += 3;

/*****************************************************************************\
|* Top level entry point for line drawing
\*****************************************************************************/
- (BOOL) _renderLines:(const NSPoint *)points count:(int)count
	{
    BOOL result = YES;

	/*************************************************************************\
	|* Quick sanity checks
	\*************************************************************************/
    if (!points)
        return SDL_InvalidParamError("SDL_RenderLines(): nil points");

    if (count < 2)
        return YES;


	/*************************************************************************\
	|* Are we doing logical presentation ?
	\*************************************************************************/
	BOOL logical   = (_logicalPresentMode != SDL_LOGICAL_PRESENTATION_DISABLED);
    BOOL islogical = (logical && (_view == &_mainView));
	BOOL isGeom	   = (_lineMethod == AZRenderLineMethodGeometry);

    if (islogical || isGeom)
		{
        BOOL isStack1, isStack2;
        const float sx 	= _view->currentScale.x;
        const float sy 	= _view->currentScale.y;
        float *xy 		= AZSmallAlloc(float, 4 * 2 * count, &isStack1);

        int countIndices 	= (4) * 3 * (count - 1) + (2) * 3 * (count);
        int *indices 		= AZSmallAlloc(int, countIndices, &isStack2);

        if (xy && indices)
			{
            float *ptrXY 			= xy;
            int *ptrIndices 		= indices;
            const int xyStride 		= 2 * sizeof(float);
            int numVertices 		= 4 * count;
            int numIndices 			= 0;
            const int sizeIndices 	= 4;
            int curIndex 			= -4;
            const int isLooping 	= (points[0].x == points[count - 1].x) &&
									   (points[0].y == points[count - 1].y);

            NSPoint p; // previous point
            p.x = p.y = 0.0f;

            //       p            q
			//
            //       0----1------ 4----5
            //       | \  |``\    | \  |
            //       |  \ |   ` `\|  \ |
            //       3----2-------7----6
            //

            for (int i = 0; i < count; ++i)
				{
				// current point
                NSPoint q = points[i];

                q.x *= sx;
                q.y *= sy;

                *ptrXY++ = q.x;
                *ptrXY++ = q.y;
                *ptrXY++ = q.x + sx;
                *ptrXY++ = q.y;
                *ptrXY++ = q.x + sx;
                *ptrXY++ = q.y + sy;
                *ptrXY++ = q.x;
                *ptrXY++ = q.y + sy;

                // closed polyline, don´t draw twice the point
                if (i || isLooping == 0)
					{
                    ADD_TRIANGLE(4, 5, 6)
                    ADD_TRIANGLE(4, 6, 7)
					}

                // first point only, no segment
                if (i == 0)
					{
                    p = q;
                    curIndex += 4;
                    continue;
					}

                // draw segment
                if (p.y == q.y)
					{
                    if (p.x < q.x)
						{
                        ADD_TRIANGLE(1, 4, 7)
                        ADD_TRIANGLE(1, 7, 2)
						}
					else
						{
                        ADD_TRIANGLE(5, 0, 3)
                        ADD_TRIANGLE(5, 3, 6)
						}
					}
				else if (p.x == q.x)
					{
                    if (p.y < q.y)
						{
                        ADD_TRIANGLE(2, 5, 4)
                        ADD_TRIANGLE(2, 4, 3)
						}
					else
						{
                        ADD_TRIANGLE(6, 1, 0)
                        ADD_TRIANGLE(6, 0, 7)
						}
					}
				else
					{
                    if (p.y < q.y)
						{
                        if (p.x < q.x)
							{
                            ADD_TRIANGLE(1, 5, 4)
                            ADD_TRIANGLE(1, 4, 2)
                            ADD_TRIANGLE(2, 4, 7)
                            ADD_TRIANGLE(2, 7, 3)
							}
						else
							{
                            ADD_TRIANGLE(4, 0, 5)
                            ADD_TRIANGLE(5, 0, 3)
                            ADD_TRIANGLE(5, 3, 6)
                            ADD_TRIANGLE(6, 3, 2)
							}
						}
					else
						{
                        if (p.x < q.x)
							{
                            ADD_TRIANGLE(0, 4, 7)
                            ADD_TRIANGLE(0, 7, 1)
                            ADD_TRIANGLE(1, 7, 6)
                            ADD_TRIANGLE(1, 6, 2)
							}
						else
							{
                            ADD_TRIANGLE(6, 5, 1)
                            ADD_TRIANGLE(6, 1, 0)
                            ADD_TRIANGLE(7, 6, 0)
                            ADD_TRIANGLE(7, 0, 3)
							}
						}
					}

                p = q;
                curIndex += 4;
				}

			SDL_FColor colour = _colour.sdlColour;
			result = [self _queueCmdGeometryWithTexture:nil
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
												 scaleY:1.f
											addressMode:AZTextureAddressClamp];

			}

		AZSmallFree(xy, isStack1);
		AZSmallFree(indices, isStack2);
		}
	else if (_lineMethod == AZRenderLineMethodPoints)
		result = [self _renderLinesAsRects:points count:count];
    else if (_view->scale.x != 1.0f || _view->scale.y != 1.0f)
		// we checked for logical scale elsewhere.
		result = [self _renderLinesAsRects:points count:count];
    else
		result = [self _queueCmdDrawLines:points count:count];

    return result;
}

/*****************************************************************************\
|* Render a set of points using rects
\*****************************************************************************/
- (BOOL) _renderRectsFromPoints:(NSPoint *)points count:(int)count
	{
    if (count < 1)
        return YES;


    BOOL isStack;
    NSRect *rects = AZSmallAlloc(NSRect, count, &isStack);
    if (!rects)
        return NO;

    const float sx = _view->currentScale.x;
    const float sy = _view->currentScale.y;
    for (int i = 0; i < count; ++i)
		{
        rects[i].origin.x 		= points[i].x * sx;
        rects[i].origin.y 		= points[i].y * sy;
        rects[i].size.width 	= sx;
        rects[i].size.height 	= sy;
		}

	BOOL result = [self _queueCmdFilledRects:rects count:count];

    AZSmallFree(rects, isStack);

    return result;
	}

/*****************************************************************************\
|* Render a line using the Bresenham algorithm
\*****************************************************************************/
- (BOOL) _renderLineFromX:(int)x1
						y:(int)y1
					  toX:(int)x2
						y:(int)y2
				 drawLast:(BOOL)drawLast
	{
    BOOL result = YES;

    const int MAX_PIXELS = SDL_max(_view->pixelW, _view->pixelH) * 4;

    // the backend might clip this further to the clipping rect, but we
    // just want a basic safety against generating millions of points for
    // massive lines.
    SDL_Rect viewport;
    NSRect view = _view->pixelView;
    viewport.x = 0;
    viewport.y = 0;
	viewport.w = view.size.width;
	viewport.h = view.size.height;

    if (!SDL_GetRectAndLineIntersection(&viewport, &x1, &y1, &x2, &y2))
        return YES;

    int numPixels;
    int d, dinc1, dinc2;
    int xinc1, xinc2;
    int yinc1, yinc2;

    int dx = SDL_abs(x2 - x1);
    int dy = SDL_abs(y2 - y1);

    if (dx >= dy)
		{
        numPixels = dx + 1;
        d = (2 * dy) - dx;
        dinc1 = dy * 2;
        dinc2 = (dy - dx) * 2;
        xinc1 = 1;
        xinc2 = 1;
        yinc1 = 0;
        yinc2 = 1;
		}
	else
		{
        numPixels = dy + 1;
        d = (2 * dx) - dy;
        dinc1 = dx * 2;
        dinc2 = (dx - dy) * 2;
        xinc1 = 0;
        xinc2 = 1;
        yinc1 = 1;
        yinc2 = 1;
		}

    if (x1 > x2)
		{
        xinc1 = -xinc1;
        xinc2 = -xinc2;
		}

    if (y1 > y2)
		{
        yinc1 = -yinc1;
        yinc2 = -yinc2;
		}

    int x = x1;
    int y = y1;

    if (!drawLast)
        --numPixels;


    if (numPixels > MAX_PIXELS)
        return SDL_SetError("Line too long (tried to draw %d pixels, max %d)",
							numPixels, MAX_PIXELS);


    BOOL isStack;
    NSPoint *points = AZSmallAlloc(NSPoint, numPixels, &isStack);
    if (!points)
        return NO;

    for (int i = 0; i < numPixels; ++i)
		{
        points[i].x = (float)x;
        points[i].y = (float)y;

        if (d < 0)
			{
            d += dinc1;
            x += xinc1;
            y += yinc1;
			}
		else
			{
            d += dinc2;
            x += xinc2;
            y += yinc2;
			}
		}

    if ((_view->currentScale.x != 1.0f) || (_view->currentScale.y != 1.0f))
		result = [self _renderRectsFromPoints:points count:numPixels];
    else
		result = [self _queueCmdDrawPoints:points count:numPixels];

    AZSmallFree(points, isStack);
    return result;
	}

/*****************************************************************************\
|* Render a line with rectangles
\*****************************************************************************/
- (BOOL) _renderLinesAsRects:(const NSPoint *)points count:(int)count
	{
    const float sx 		= _view->currentScale.x;
    const float sy 		= _view->currentScale.y;
    BOOL result 		= YES;
    BOOL drewLine 		= NO;
    BOOL drawLast 		= NO;
    int nRects 			= 0;

	BOOL isStack;
	NSRect *rects = AZSmallAlloc(NSRect, count - 1, &isStack);
    if (!rects)
        return NO;


    for (int i = 0; i < count - 1; ++i)
		{
		// Check for degenerate cases
        BOOL sameX = (points[i].x == points[i + 1].x);
        bool sameY = (points[i].y == points[i + 1].y);

        if (i == (count - 2))
			{
			BOOL xMatch = (points[i + 1].x != points[0].x);
			BOOL yMatch = (points[i + 1].y != points[0].y);
            if (!drewLine || xMatch || yMatch)
                drawLast = YES;
			}
		else
			{
            if (sameX && sameY)
                continue;
			}

		// Vertical line
        if (sameX)
			{
            const float minY = SDL_min(points[i].y, points[i + 1].y);
            const float maxY = SDL_max(points[i].y, points[i + 1].y);

            NSRect *rect = &rects[nRects++];
            rect->origin.x 		= points[i].x * sx;
            rect->origin.y 		= minY * sy;
            rect->size.width 	= sx;
			rect->size.height 	= (maxY - minY + drawLast) * sy;
            if (!drawLast && (points[i + 1].y < points[i].y))
                rect->origin.y += sy;
			}

		// Horizontal line
        else if (sameY)
			{
            const float minX = SDL_min(points[i].x, points[i + 1].x);
            const float maxX = SDL_max(points[i].x, points[i + 1].x);

            NSRect *rect = &rects[nRects++];
            rect->origin.x 		= minX * sx;
            rect->origin.y 		= points[i].y * sy;
            rect->size.width 	= (maxX - minX + drawLast) * sx;
            rect->size.height	= sy;
            if (!drawLast && points[i + 1].x < points[i].x)
                rect->origin.x += sx;
			}

		// General line, use Bresenham
        else
			result &= [self _renderLineFromX:(int)SDL_roundf(points[i].x)
										   y:(int)SDL_roundf(points[i].y)
										 toX:(int)SDL_roundf(points[i + 1].x)
										   y:(int)SDL_roundf(points[i + 1].y)
									drawLast:drawLast];
        drewLine = YES;
		}

    if (nRects)
		result &= [self _queueCmdFilledRects:rects count:nRects];


    AZSmallFree(rects, isStack);
    return result;
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

	[cmd zero];
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
|* Enqueue a clear command
\*****************************************************************************/
- (BOOL) _queueCmdClear
	{
    AZRenderCommand *cmd = [self _allocateCommand];
    if (!cmd)
        return NO;

	cmd.command 	= AZRenderCmdClear;
    cmd.first 		= 0;
	cmd.colourScale = _colourScale;
	cmd.colour 		= _clearColour.sdlColour;
    return true;
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
|* Draw points as a queue'd command
\*****************************************************************************/
- (BOOL) _queueCmdDrawPoints:(const NSPoint *)points count:(const int)count
	{
	AZRenderCommand *cmd = nil;

    BOOL result = NO;
	cmd 		= [self _prepQueueCommandDrawOfType:AZRenderCmdDrawPoints
											texture:NULL];
    if (cmd)
		{
		int sz		 	= 2 * sizeof(float);
		NSInteger first	= 0;
		float *verts 	= (float *) [self _allocateVerticesOfSize:count * sz
													withAlignment:0
														 atOffset:&first];
		if (!verts)
			cmd.command = AZRenderCmdNoOp;
		else
			{
			cmd.count = count;
			cmd.first = first;

			for (int i = 0; i < count; i++)
				{
				*(verts++) = 0.5f + points[i].x;
				*(verts++) = 0.5f + points[i].y;
				}
			result = YES;
			}
		}
    return result;
	}

/*****************************************************************************\
|* Draw lines as a queue'd command
\*****************************************************************************/
- (BOOL) _queueCmdDrawLines:(const NSPoint *)points count:(const int)count
	{
	AZRenderCommand *cmd = nil;

    BOOL result = NO;
	cmd 		= [self _prepQueueCommandDrawOfType:AZRenderCmdDrawLines
											texture:NULL];
    if (cmd)
		{
		int sz		 	= 2 * sizeof(float);
		NSInteger first	= 0;
		float *verts 	= (float *) [self _allocateVerticesOfSize:count * sz
													withAlignment:0
														 atOffset:&first];
		if (!verts)
			cmd.command = AZRenderCmdNoOp;
		else
			{
			cmd.count = count;
			cmd.first = first;

			for (int i = 0; i < count; i++)
				{
				*(verts++) = 0.5f + points[i].x;
				*(verts++) = 0.5f + points[i].y;
				}
			result = YES;
			}
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

/*****************************************************************************\
|* Construct a command to queue geometry
\*****************************************************************************/
- (BOOL) _queueCmdGeometryWithTexture:(nullable AZTexture *)texture
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
						  addressMode:(AZTextureAddressMode)addressMode
	{
	BOOL result = NO;
	AZRenderCommand *cmd = [self _prepQueueCommandDrawOfType:AZRenderCmdGeometry
													 texture:texture];
    if (cmd)
		{
		cmd.addressMode = addressMode;
		result = [self _queueGeometryWith:cmd
								  texture:texture
									   xy:xy
								 xyStride:xyStride
								   colour:colour
							 colourStride:colourStride
									   uv:uv
								 uvStride:uvStride
							  numVertices:numVertices
								  indices:indices
							   numIndices:numIndices
							  sizeIndices:sizeIndices
								   scaleX:scaleX
								   scaleY:scaleY];
        if (!result)
            cmd.command = AZRenderCmdNoOp;
		}
    return result;
	}

/*****************************************************************************\
|* Render geometry as a queue'd command
\*****************************************************************************/
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

	AZ_LOG_DECLARE(info, @"_queueGeometry vertices:\n");
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
        AZ_LOG_APPEND(info, @"(x=%.2f, y=%.2f)",
					xyPtr[0] * scaleX,
					xyPtr[1] * scaleY);

        colourVal 	= *(SDL_FColor *)((char *)colour + j * colourStride);
        if (convertColour)
			[self _convertToLinear:&colourVal];

        *(verts++) = colourVal.r * colourScale;
        *(verts++) = colourVal.g * colourScale;
        *(verts++) = colourVal.b * colourScale;
        *(verts++) = colourVal.a;
		AZ_LOG_APPEND(info, @" (rgba=%.2f,%.2f,%.2f,%.2f)",
			colourVal.r * colourScale,
			colourVal.g * colourScale,
			colourVal.b * colourScale,
			colourVal.a);

        if (texture)
			{
            float *uvPtr = (float *)((char *)uv + j * uvStride);
			*(verts++) = uvPtr[0] * texture.size.width;
            *(verts++) = uvPtr[1] * texture.size.height;

			AZ_LOG_APPEND(info, @" (u=%.2f, v=%.2f)",
				uvPtr[0] * texture.size.width,
				uvPtr[1] * texture.size.height);
			}
		AZ_LOG_APPEND(info, @"\n");
		}
	AZ_LOG_SHOW(info);

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
