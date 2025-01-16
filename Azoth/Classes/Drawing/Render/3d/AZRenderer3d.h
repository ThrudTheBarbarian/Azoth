//
//  AZRenderer3d.h
//  Azoth
//
//  Created by Simon Gornall on 1/13/25.
//

#import <SDL3/SDL.h>

#import <Foundation/Foundation.h>
#import <Azoth/AZRenderer.h>
#import <Azoth/AZTypes.h>

typedef enum
	{
    AZ_RENDERLINEMETHOD_POINTS,
    AZ_RENDERLINEMETHOD_LINES,
    AZ_RENDERLINEMETHOD_GEOMETRY,
	} AZRenderLineMethod;

NS_ASSUME_NONNULL_BEGIN

@class AZColour;

@interface AZRenderer3d : NSObject <AZRenderer>

/*****************************************************************************\
|* Return the 3D renderer
\*****************************************************************************/
+ (AZRenderer3d *) renderer;


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
@end

NS_ASSUME_NONNULL_END
