//
//  AZRenderer3d.m
//  Azoth
//
//  Created by Simon Gornall on 1/13/25.
//

#import <SDL3/SDL.h>

#import "AZRenderer3d.h"
#import "AZRenderPipeline.h"
#import "AZShader.h"
#import "AZWindow.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZRenderer3d()
// The SDL window we associate this renderer with
@property(assign, nonatomic) SDL_Window *							sdl;

// The AZWindow we associate this renderer with
@property(strong, nonatomic) AZWindow *								window;

// The GPU device
@property(assign, nonatomic) SDL_GPUDevice *						gpu;

// The sprite render pipeline
@property(strong, nonatomic) AZRenderPipeline *						spritePipe;

@end

@implementation AZRenderer3d
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
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
		azr = [AZRenderer3d new];
		});
	return azr;
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
	AZShader *vert, *frag;
	_spritePipe = [AZRenderPipeline new];


	vert = [AZShader shaderWithRenderer:self
								   name:@"TexturedQuadColorWithMatrix.vert"
							   samplers:0
						 uniformBuffers:1
						 storageBuffers:0
						storageTextures:0];

	frag = [AZShader shaderWithRenderer:self
								   name:@"TexturedQuadColor.frag"
							   samplers:1
						 uniformBuffers:0
						 storageBuffers:0
						storageTextures:0];

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


- (NSInteger)createTextureOfSize:(NSSize)size
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
	return 0;
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


- (void)releaseTexture:(NSInteger)refId
	{
	NSLog(@"%@:%@ not implemented", self, NSStringFromSelector(_cmd));
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



@end
