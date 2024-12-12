//
//  app.m
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//


#define SDL_MAIN_USE_CALLBACKS 1
#import <SDL3/SDL.h>
#import <SDL3/SDL_main.h>

#import <Azoth/Azoth.h>

/*****************************************************************************\
|* File-private variables
\*****************************************************************************/
static SDL_Window *		_window 	= NULL;
static SDL_Renderer *	_renderer 	= NULL;
static AZApp *			_app		= NULL;


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
									 1280,
									 960,
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
	_app = [AZApp sharedInstance];
	_app.window 	= _window;
	_app.renderer	= _renderer;

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
