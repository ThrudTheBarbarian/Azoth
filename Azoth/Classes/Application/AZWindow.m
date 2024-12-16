//
//  AZWindow.m
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import <SDL3/SDL.h>
#import <SDL3_image/SDL_image.h>
#import <SDL3_ttf/SDL_ttf.h>

#import "AZView.h"
#import "AZView+Internal.h"
#import "AZWindow.h"

/*****************************************************************************\
|* Store the top-level content-views for each window we know about
\*****************************************************************************/
static NSMutableDictionary<NSNumber *, AZView *> * _contentViews = nil;

@implementation AZWindow
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithContentRect:(NSRect)contentRect
						   styleMask:(NSInteger)style
	{
	if (self = [super init])
		{
		if ([self _initWithRect:contentRect style:style] != SDL_APP_CONTINUE)
			self = nil;
		}
	return self;
	}

+ (AZWindow *) windowWithContentRect:(NSRect)contentRect
						   styleMask:(NSInteger)styleMask
	{
	return [[AZWindow alloc] initWithContentRect:contentRect
								  	   styleMask:styleMask];
	}

/*****************************************************************************\
|* Common initialisation
\*****************************************************************************/
- (SDL_AppResult) _initWithRect:(NSRect)r style:(NSInteger)style
	{
	SDL_AppResult ok = SDL_APP_CONTINUE;

	/*************************************************************************\
    |* Set up the content-view map
    \*************************************************************************/
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		_contentViews = [NSMutableDictionary new];
		});


	/*************************************************************************\
    |* Make sure we can initialise
    \*************************************************************************/
    if (!SDL_Init(SDL_INIT_VIDEO))
		{
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
		ok = SDL_APP_FAILURE;
		}

	/*************************************************************************\
    |* Create the window
    \*************************************************************************/
    if (!SDL_CreateWindowAndRenderer("Demo app",
									 r.size.width,
									 r.size.height,
									 style,
									 &_window,
									 &_renderer))
		{
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        ok = SDL_APP_FAILURE;
		}

	/*************************************************************************\
    |* Initialise font system
    \*************************************************************************/
    if (!TTF_Init())
		{
        SDL_Log("Couldn't initialize TTF: %s\n",SDL_GetError());
        ok = SDL_APP_FAILURE;
		}

	return ok;
	}

/*****************************************************************************\
|* Add a content view to the window
\*****************************************************************************/
- (void) installContentView
	{
	int w,h;
	SDL_GetWindowSizeInPixels(_window, &w, &h);

	AZView *contentView 	= [AZView viewWithFrame:NSMakeRect(0,0,w,h)];
	contentView.window		= self;
	NSNumber *windowId 		= @(SDL_GetWindowID(_window));

	_contentViews[windowId] = contentView;
	contentView.isOpaque 	= YES;

	[contentView _installBackingTexture];
	}

/*****************************************************************************\
|* Return the contentView for any given SDL_Window. If one does not exist it
|* will be created and returned
\*****************************************************************************/
+ (AZView *) contentViewForWindow:(AZWindow *)window
	{
	return [self contentViewForSDLWindow:window.window];
	}

+ (AZView *) contentViewForSDLWindow:(struct SDL_Window *)window;
	{
	NSNumber *windowId = @(SDL_GetWindowID(window));
	return [_contentViews objectForKey:windowId];
	}

@end
