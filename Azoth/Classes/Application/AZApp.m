//
//  AZApp.m
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZGeometry.h"
#import "AZView.h"
#import "AZView+Internal.h"

@implementation AZApp

/*****************************************************************************\
|* Constructor
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{}
	return self;
	}

/*****************************************************************************\
|* Constructor
\*****************************************************************************/
+ (AZApp *) sharedInstance
	{
	static AZApp *instance;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		instance = [AZApp new];
		});

	return instance;
	}

/*****************************************************************************\
|* Handle events
\*****************************************************************************/
- (SDL_AppResult) handleEvent:(SDL_Event *)e withAppState:(void *)state
	{
	SDL_AppResult result 	= SDL_APP_CONTINUE;
	AZView *cv 				= [AZView contentViewForWindow:_window];
	NSPoint p				= (NSPoint){-1,-1};

	switch (e->type)
		{
		/*********************************************************************\
		|* Tell the OS that we successfully quit
		\*********************************************************************/
		case SDL_EVENT_QUIT:
			result = SDL_APP_SUCCESS;
			break;

		/*********************************************************************\
		|* Handle mouse events
		\*********************************************************************/
		case SDL_EVENT_MOUSE_BUTTON_DOWN:
		case SDL_EVENT_MOUSE_BUTTON_UP:
			p.x = ((SDL_MouseButtonEvent *)e)->x;
			p.y = ((SDL_MouseButtonEvent *)e)->y;
			[cv processMouseEvent:e atPoint:p];
			break;

		case SDL_EVENT_MOUSE_MOTION:
			p.x = ((SDL_MouseMotionEvent *)e)->x;
			p.y = ((SDL_MouseMotionEvent *)e)->y;
			[cv processMouseEvent:e atPoint:p];
			break;

		case SDL_EVENT_MOUSE_WHEEL:
			p.x = ((SDL_MouseMotionEvent *)e)->x;
			p.y = ((SDL_MouseMotionEvent *)e)->y;
			[cv processMouseEvent:e atPoint:p];
			break;
		}

	/* carry on with the program! */
	return result;
	}

/*****************************************************************************\
|* Handle redraw
\*****************************************************************************/
- (SDL_AppResult) nextFrameWithAppState:(void *)state
	{

//	/* convert from milliseconds to seconds. */
//    const double now = ((double)SDL_GetTicks()) / 1000.0;
//
//    /* choose the color for the frame we will draw.
//       The sine wave trick makes it fade between colors smoothly. */
//    const float red = (float) (0.5 + 0.5 * SDL_sin(now));
//    const float green = (float) (0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 2 / 3));
//    const float blue = (float) (0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 4 / 3));
//
//    /* new color, full alpha. */
//    SDL_SetRenderDrawColorFloat(_renderer, red, green, blue, SDL_ALPHA_OPAQUE_FLOAT);
//
//    /* clear the window to the draw color. */
//    SDL_RenderClear(_renderer);
//
//    /* put the newly-cleared rendering on the screen. */
//    SDL_RenderPresent(_renderer);
//
	// Redraw any of the subviews that need it into their own textures
	AZView *view = [AZView contentViewForWindow:_window];
	[view redrawSubViewsIfNecessary];

	// Get the top-level view, draw it as the background
	SDL_FRect rect = SDLFRectFromNSRect(view.bounds);
	SDL_SetRenderDrawBlendMode(_renderer, SDL_BLENDMODE_NONE);
	SDL_RenderTexture(_renderer, view.bg, &rect, &rect);

	// Run through the views in reverse order, telling them to render their
	// subviews to the screen
	for (AZView *subview in [view.subviews reverseObjectEnumerator])
		[subview _render];

	// Tell the renderer we're done
	SDL_RenderPresent(_renderer);

    /* carry on with the program! */
    return SDL_APP_CONTINUE;
	}

/*****************************************************************************\
|* Die gracefully
\*****************************************************************************/
- (void) terminateBecause:(SDL_AppResult)reason withAppState:(void *)state
	{}
	
@end

