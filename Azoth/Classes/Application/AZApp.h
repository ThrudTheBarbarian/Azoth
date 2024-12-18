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
struct TTF_TextEngine;

@class AZFont;
@class AZWindow;

@protocol AZAppDelegate;

@interface AZApp : NSObject
	
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZApp *) sharedInstance;

/*****************************************************************************\
|* Startup code
\*****************************************************************************/
- (void) startWithArgc:(int)argc argv:(char *_Nonnull *_Nonnull)argv;

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
- (void) registerTextureForDisposal:(NSNumber *)texture;


/*****************************************************************************\
|* Fill out a box that defines a particular named piece of the UI texture atlas
\*****************************************************************************/
- (NSRect) srcRectFor:(NSString *)uiName;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The main application window
@property(strong, nonatomic) AZWindow *					window;

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

// And an appropriately sized control font
@property(strong, nonatomic) AZFont *					controlFont;

// The UI texture atlas id
@property(assign, nonatomic) NSInteger 					ui;

// The Initial frame at startup. If not set, a default
// 640x480 size will be used
@property(assign, nonatomic) NSRect						initialFrame;

// Any window flags to be passed to the call
// SDL_CreateWindowAndRenderer
@property(assign, nonatomic) NSInteger					windowFlags;

// The TTF render-engine used for text editing
@property(assign, nonatomic) struct TTF_TextEngine * 	textEngine;
@end

NS_ASSUME_NONNULL_END
