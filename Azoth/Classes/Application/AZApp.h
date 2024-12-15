//
//  AZApp.h
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kTextureType;

enum SDL_AppResult;
union SDL_Event;
struct SDL_Renderer;
struct SDL_Texture;
struct SDL_Window;

@class AZFont;

@protocol AZAppDelegate;

@interface AZApp : NSObject
	
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZApp *) sharedInstance;

/*****************************************************************************\
|* Startup code
\*****************************************************************************/
- (void) startWithArgc:(int)argc
				  argv:(char *_Nonnull *_Nonnull)argv
				 state:(void * _Nullable)state;

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
|* Application service: dispose of things after renderPresent called. Useful
|* when the renderer has to hang onto a resource in order to process something
\*****************************************************************************/
- (void) registerTextureForDisposal:(struct SDL_Texture *)texture;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The main window, where the rendering happens
@property(assign, nonatomic) struct SDL_Window *		window;

// The renderer for the window
@property(assign, nonatomic) struct SDL_Renderer *		renderer;

// The delegate for the application
@property(strong, nonatomic) id<AZAppDelegate>			delegate;

// The application viability - whether it can continue
@property(assign, nonatomic) int						viability;

// The system font info, the app provides default values
// before notifying the delegate that it has been started
// so the delegate can override these at that point
@property(assign, nonatomic) AZFontStyle				systemFontInfo;

// The system font itself
@property(strong, nonatomic) AZFont *					systemFont;
@end

NS_ASSUME_NONNULL_END
