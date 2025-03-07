//
//  AZPipelineTarget.h
//  sdl3_gpu
//
//  Created by ThrudTheBarbarian on 1/13/25.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

NS_ASSUME_NONNULL_BEGIN

@class AZColourTarget;

@interface AZPipelineTarget : NSObject

/*****************************************************************************\
|* Add a colour target
\*****************************************************************************/
- (void) addColourTarget:(AZColourTarget *)colourTarget;

/*****************************************************************************\
|* Return the target info description
\*****************************************************************************/
- (SDL_GPUGraphicsPipelineTargetInfo) info;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The list of colour targets
@property(strong, nonatomic)
NSMutableArray<AZColourTarget *> *						colourTargets;

// The depth-stencil format, if one is used.
@property(assign, nonatomic) SDL_GPUTextureFormat		depthStencilTarget;

// true specifies that the pipeline uses a
// depth-stencil target
@property(assign, nonatomic) BOOL						hasDepthStencilTarget;

@end

NS_ASSUME_NONNULL_END
