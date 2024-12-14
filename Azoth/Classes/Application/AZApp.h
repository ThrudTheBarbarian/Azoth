//
//  AZApp.h
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kTextureType;

enum SDL_AppResult;
union SDL_Event;
struct SDL_Renderer;
struct SDL_Texture;
struct SDL_Window;

@interface AZApp : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZApp *) sharedInstance;

/*****************************************************************************\
|* Handle SDL events as they come in
\*****************************************************************************/
- (enum SDL_AppResult) handleEvent:(union SDL_Event *)ev withAppState:(void *)state;

/*****************************************************************************\
|* Process the next frame on the screen
\*****************************************************************************/
- (enum SDL_AppResult) nextFrameWithAppState:(void *)state;

/*****************************************************************************\
|* Terminate the application gracefully (!)
\*****************************************************************************/
- (void) terminateBecause:(enum SDL_AppResult)reason withAppState:(void *)state;


/*****************************************************************************\
|* Application service: dispose of things after renderPresent called
\*****************************************************************************/
- (void) registerTextureForDisposal:(struct SDL_Texture *)texture;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The main window, where the rendering happens
@property (assign, nonatomic) struct SDL_Window *		window;

@property (assign, nonatomic) struct SDL_Renderer *		renderer;
@end

NS_ASSUME_NONNULL_END
