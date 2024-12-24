//
//  startup.m
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//


#define SDL_MAIN_USE_CALLBACKS 1
#import <SDL3/SDL.h>
#import <SDL3/SDL_main.h>

#import <Azoth/Azoth.h>

#import "AppDelegate.h"
#import "IdentifiedView.h"

/*****************************************************************************\
|* File-private variables
\*****************************************************************************/
static AZApp *			_app		= NULL;

/*****************************************************************************\
|* Function declarations
\*****************************************************************************/
void _testMouseEvents(void);

/*****************************************************************************\
|* Callback: This function is called at startup
\*****************************************************************************/
SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[])
	{
    SDL_SetAppMetadata("Azoth test app",
					   "1.0",
					   "com.moebius-tech.azoth");

	/*************************************************************************\
    |* Create the application.
    \*************************************************************************/
	_app 				= [AZApp sharedInstance];
	_app.delegate		= [AppDelegate new];
	_app.initialFrame	= NSMakeRect(50, 50, 780, 480);
	_app.windowFlags	= SDL_WINDOW_RESIZABLE;
	*appstate			= (__bridge void *)(_app);

	[_app startWithArgc:argc argv:argv];

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
|* Set up the UI for this application
\*****************************************************************************/
void _testMouseEvents(void)
	{
	AZView *cv		= [AZWindow contentViewForWindow:_app.window];
	[cv setIdentifier:@"content-view"];

	IdentifiedView *v1 = [[IdentifiedView alloc]
							initWithFrame:NSMakeRect(0,0, 1200, 720)
								  andName:@"view1"];
	[v1 setBackgroundColour:[AZColour whiteColour]];

	AZScrollView *sv = [[AZScrollView alloc]
							initWithFrame:NSMakeRect(100, 100, 600, 360)];
	[sv setHasVerticalScroller:YES];
	[sv setHasHorizontalScroller:YES];
	[sv setBorderType: AZLineBorder];
	[sv setDocumentView:v1];
	sv.autoresizingMask = AZViewHeightSizable|AZViewWidthSizable;

	[cv addSubview:sv];
	[cv setBackgroundColour:[AZColour orangeColour]];
	}
