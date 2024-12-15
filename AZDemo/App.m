//
//  app.m
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//


#define SDL_MAIN_USE_CALLBACKS 1
#import <SDL3/SDL.h>
#import <SDL3/SDL_main.h>
#import <SDL3_image/SDL_image.h>

#import <Azoth/Azoth.h>

#import "AppDelegate.h"
#import "IdentifiedView.h"

/*****************************************************************************\
|* Function declarations
\*****************************************************************************/
void _testMouseEvents(void);



/*****************************************************************************\
|* File-private variables
\*****************************************************************************/
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
    |* Create the application. SDL initialisation is done in the app-delegate
    \*************************************************************************/
	_app 			= [AZApp sharedInstance];
	_app.delegate	= [AppDelegate new];

	[_app startWithArgc:argc argv:argv state:*appstate];

	if (_app.viability == SDL_APP_CONTINUE)
		{
		_testMouseEvents();

		/*********************************************************************\
		|* .. and carry on with the program
		\*********************************************************************/
		}
    return _app.viability;
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


// MARK: Testing routines

/*****************************************************************************\
|* Set up some frames, wait for clicks and report
\*****************************************************************************/
void _testMouseEvents(void)
	{
	AZApp *app		= [AZApp sharedInstance];
	AZView *cv		= [AZView contentViewForWindow:app.window];
	[cv setIdentifier:@"content-view"];

	IdentifiedView *v1 = [[IdentifiedView alloc]
							initWithFrame:NSMakeRect(100,100, 600, 600)
								  andName:@"view1"];
	[v1 setBgColour:[AZColour redColour]];
	[cv addSubview:v1];

	IdentifiedView *v2 = [[IdentifiedView alloc]
							initWithFrame:NSMakeRect(100,100, 100, 100)
								  andName:@"view2"];
	[v2 setBgColour:[AZColour greenColour]];
	v2.bgColour.a = 0.5;
	[v1 addSubview:v2];

	[cv setBgColour:[AZColour orangeColour]];
	}
