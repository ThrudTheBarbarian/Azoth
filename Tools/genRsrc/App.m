//
//  App.m
//  genRsrc
//
//  Created by Simon Gornall on 12/15/24.
//

#import <Foundation/Foundation.h>


#define SDL_MAIN_USE_CALLBACKS 1
#import <SDL3/SDL.h>
#import <SDL3/SDL_main.h>
#import <SDL3_image/SDL_image.h>

#import "RsrcMaker.h"

/*****************************************************************************\
|* Callback: This function is called at startup
\*****************************************************************************/
SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[])
	{
    SDL_SetAppMetadata("resource-generation utility",
					   "1.0",
					   "com.moebius-tech.rsrcgen");

	/*************************************************************************\
    |* Make sure we can initialise
    \*************************************************************************/
    if (!SDL_Init(SDL_INIT_VIDEO))
		{
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
        exit(0);
		}

	/*************************************************************************\
    |* Create the application.
    \*************************************************************************/
	NSMutableArray<NSString *> *args = [NSMutableArray new];
	for (int i=1; i<argc; i++)
		[args addObject:[NSString stringWithUTF8String:argv[i]]];
	(void)[[RsrcMaker alloc] initWithArgs:args];

    return SDL_APP_SUCCESS;
	}

/*****************************************************************************\
|* Callback: This function runs when a new event occurs
\*****************************************************************************/
SDL_AppResult SDL_AppEvent(void *appState, SDL_Event *event)
	{
	return SDL_APP_CONTINUE;
	}

/*****************************************************************************\
|* Callback: process the next frame
\*****************************************************************************/
SDL_AppResult SDL_AppIterate(void *appState)
	{
	return SDL_APP_CONTINUE;
	}

/*****************************************************************************\
|* Callback: handle death gracefully
\*****************************************************************************/
void SDL_AppQuit(void *appState, SDL_AppResult result)
	{
    /* SDL will clean up the window/renderer for us. */
	}
