//
//  App.m
//  AZDemo
//
//  Created by Simon Gornall on 12/11/24.
//

#import "App.h"

/*****************************************************************************\
|* File-private variables
\*****************************************************************************/
static SDL_Window *		_window 	= NULL;
static SDL_Renderer *	_renderer 	= NULL;
static App *			_app		= NULL;


/*****************************************************************************\
|* Callback: This function is called at startup
\*****************************************************************************/
SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[])
	{
    SDL_SetAppMetadata("quicksilver test app",
					   "1.0",
					   "com.moebius-tech.qstest");

	/*************************************************************************\
    |* Make sure we can initialise
    \*************************************************************************/
    if (!SDL_Init(SDL_INIT_VIDEO))
		{
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
		}

	/*************************************************************************\
    |* Create the window
    \*************************************************************************/
    if (!SDL_CreateWindowAndRenderer("Map and layer generator",
									 640,
									 480,
									 SDL_WINDOW_RESIZABLE,
									 &_window,
									 &_renderer))
		{
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
		}

	/*************************************************************************\
    |* Create the application
    \*************************************************************************/
	_app = [App sharedInstance];

	/*************************************************************************\
    |* .. and carry on with the program
    \*************************************************************************/
    return SDL_APP_CONTINUE;
	}

/*****************************************************************************\
|* Callback: This function runs when a new event occurs
\*****************************************************************************/
SDL_AppResult SDL_AppEvent(void *appState, SDL_Event *event)
	{
	return [_app handleEvent:event withAppState:appState];
	}

/*****************************************************************************\
|* Callback: process the next frame
\*****************************************************************************/
SDL_AppResult SDL_AppIterate(void *appState)
	{
	return [_app nextFrameWithAppState:appState];
	}

/*****************************************************************************\
|* Callback: handle death gracefully
\*****************************************************************************/
void SDL_AppQuit(void *appState, SDL_AppResult result)
	{
	[_app terminateBecause:result withAppState:appState];

    /* SDL will clean up the window/renderer for us. */
	}

@implementation App

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
+ (App *) sharedInstance
	{
	static App *instance;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		instance = [App new];
		});

	return instance;
	}

/*****************************************************************************\
|* Handle events
\*****************************************************************************/
- (SDL_AppResult) handleEvent:(SDL_Event *)e withAppState:(void *)state
	{
    if (e->type == SDL_EVENT_QUIT)
		{
		/* end the program, reporting success to the OS. */
        return SDL_APP_SUCCESS;
		}

	/* carry on with the program! */
    return SDL_APP_CONTINUE;
	}

/*****************************************************************************\
|* Handle events
\*****************************************************************************/
- (SDL_AppResult) nextFrameWithAppState:(void *)state
	{
	/* convert from milliseconds to seconds. */
    const double now = ((double)SDL_GetTicks()) / 1000.0;

    /* choose the color for the frame we will draw.
       The sine wave trick makes it fade between colors smoothly. */
    const float red = (float) (0.5 + 0.5 * SDL_sin(now));
    const float green = (float) (0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 2 / 3));
    const float blue = (float) (0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 4 / 3));

    /* new color, full alpha. */
    SDL_SetRenderDrawColorFloat(_renderer, red, green, blue, SDL_ALPHA_OPAQUE_FLOAT);

    /* clear the window to the draw color. */
    SDL_RenderClear(_renderer);

    /* put the newly-cleared rendering on the screen. */
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

