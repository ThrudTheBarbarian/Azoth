//
//  AZWindow.h
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import <Azoth/AZResponder.h>

NS_ASSUME_NONNULL_BEGIN

struct SDL_Renderer;
struct SDL_Window;

@class AZView;

@interface AZWindow : AZResponder

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZWindow *) windowWithContentRect:(NSRect)contentRect
						   styleMask:(NSInteger)styleMask;

/*****************************************************************************\
|* Add a content view to the window
\*****************************************************************************/
- (void) installContentView;

/*****************************************************************************\
|* Return the contentView for any given (SDL_)Window.
\*****************************************************************************/
+ (AZView *) contentViewForWindow:(AZWindow *)window;
+ (AZView *) contentViewForSDLWindow:(struct SDL_Window *)window;


// The main window, where the rendering happens
@property(assign, nonatomic) struct SDL_Window *		window;

// The renderer for the window
@property(assign, nonatomic) struct SDL_Renderer *		renderer;
@end

NS_ASSUME_NONNULL_END
