//
//  AZColourTarget.h
//  sdl3_gpu
//
//  Created by Simon Gornall on 1/13/25.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZColourTarget : NSObject

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
