//
//  AZColourTarget.h
//  sdl3_gpu
//
//  Created by ThrudTheBarbarian on 1/13/25.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

NS_ASSUME_NONNULL_BEGIN

@class AZRenderer3d;

@interface AZColourTarget : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZColourTarget*) targetWithFormat:(SDL_GPUTextureFormat)format;


/*****************************************************************************\
|* Use the renderer to convert a blend mode to a target-blendstate
\*****************************************************************************/
- (void) updataBlendStateWith:(AZRenderer3d *)renderer
				 andBlendMode:(SDL_BlendMode)mode;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The pixel format of the texture to be used
// as a color target.
@property(assign, nonatomic) SDL_GPUTextureFormat			format;

// The blend state to be used for the color target
// Must be one of
@property(assign, nonatomic) SDL_GPUColorTargetBlendState	blendState;

@end

NS_ASSUME_NONNULL_END
