//
//  AZWindow.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/16/24.
//

#import <Azoth/AZResponder.h>

NS_ASSUME_NONNULL_BEGIN

struct SDL_Renderer;
struct SDL_Window;

@class AZWindowContentView;

@interface AZWindow : AZResponder

#if 0
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithContentRect:(NSRect)contentRect
						   styleMask:(NSInteger)style
						     backing:(NSInteger)ignored
						       defer:(BOOL)alsoIgnored;

- (instancetype) initWithContentRect:(NSRect)contentRect
						   styleMask:(NSInteger)style;

+ (AZWindow *) windowWithContentRect:(NSRect)contentRect
						   styleMask:(NSInteger)styleMask;
#endif

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithWindow:(struct SDL_Window *)window;


/*****************************************************************************\
|* Add a content view to the window, either make a default one, or install one
|* we already have ready to go
\*****************************************************************************/
- (void) installContentView;
- (void) installContentView:(AZWindowContentView *)contentView;

/*****************************************************************************\
|* Return the window for any given SDL_Window.
\*****************************************************************************/
+ (AZWindow *) windowForSDLWindow:(struct SDL_Window *)sdlWindow;

/*****************************************************************************\
|* Return the contentView for any given (SDL_)Window.
\*****************************************************************************/
+ (AZWindowContentView *) contentViewForWindow:(AZWindow *)window;
+ (AZWindowContentView *) contentViewForSDLWindow:(struct SDL_Window *)window;

/*****************************************************************************\
|* End editing in table-views. Should this move to AZTableView ?
\*****************************************************************************/
- (void)endEditingFor:(nullable id)sender;

/*****************************************************************************\
|* Make an AZResponder the first-responder
\*****************************************************************************/
- (BOOL) makeFirstResponder:(nullable AZResponder *)responder;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The main window, where the rendering happens
@property(assign, nonatomic) struct SDL_Window *			window;

// The renderer for the window
@property(assign, nonatomic) struct SDL_Renderer *			renderer;

// The current first-responder
@property(retain, nonatomic, nullable) AZResponder *		firstResponder;

/*****************************************************************************\
|* Interface builder properties. Only here for compatibility. May or may not
|* have any actual effect
\*****************************************************************************/

// The max size of the window
@property(assign, nonatomic) NSSize							maxSize;

// The min size of the window
@property(assign, nonatomic) NSSize							minSize;

// indicates whether the window is removed from the
// screen when its application becomes inactive
@property(assign, nonatomic) BOOL							hidesOnDeactivate;

// whether the window is released when it receives
// the close message
@property(assign, nonatomic) BOOL							releasedWhenClosed;

// The title of the window
@property(copy, nonatomic) NSString *						title;

// The content-view for the window
@property(strong, nonatomic) AZWindowContentView *			contentView;
@end


NS_ASSUME_NONNULL_END
