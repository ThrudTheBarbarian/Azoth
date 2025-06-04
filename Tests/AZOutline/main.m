//
//  main.m
//  AZOutline
//
//  Created by ThrudTheBarbarian for Azoth.
//

#define SDL_MAIN_USE_CALLBACKS 1
#import <SDL3/SDL.h>
#import <SDL3/SDL_main.h>

#import <Azoth/Azoth.h>
#import "AppDelegate.h"

/*****************************************************************************\
|* Callback: This function is called at startup
\*****************************************************************************/
SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[])
	{
    SDL_SetAppMetadata("Azoth outline-view-testing app",
					   "1.0",
					   "com.moebius-tech.azoth");

	/*************************************************************************\
    |* Create the application.
    \*************************************************************************/
	AZApp.delegate		= [AppDelegate new];
	AZApp.initialFrame	= NSMakeRect(0, 0, 512, 512);
	AZApp.windowFlags	= SDL_WINDOW_RESIZABLE;
	AZApp.rendererType	= AZRendererType3d;
	*appstate			= (__bridge void *)(AZApp);

	[AZApp startWithArgc:argc argv:argv];

	if (AZApp.viability == SDL_APP_CONTINUE)
		{
		/*********************************************************************\
		|* .. carry on with any initialisation
		\*********************************************************************/
		}
    return AZApp.viability;
	}

