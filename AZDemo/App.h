//
//  App.h
//  AZDemo
//
//  Created by Simon Gornall on 12/11/24.
//

#import <Foundation/Foundation.h>

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

NS_ASSUME_NONNULL_BEGIN


@interface App : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (App *) sharedInstance;

/*****************************************************************************\
|* Handle SDL events as they come in
\*****************************************************************************/
- (SDL_AppResult) handleEvent:(SDL_Event *)ev withAppState:(void *)state;

/*****************************************************************************\
|* Process the next frame on the screen
\*****************************************************************************/
- (SDL_AppResult) nextFrameWithAppState:(void *)state;

/*****************************************************************************\
|* Terminate the application gracefully (!)
\*****************************************************************************/
- (void) terminateBecause:(SDL_AppResult)reason withAppState:(void *)state;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

@end

NS_ASSUME_NONNULL_END
