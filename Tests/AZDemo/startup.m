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
#import "ColouredView.h"


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
	AZApp.delegate		= [AppDelegate new];
	AZApp.initialFrame	= NSMakeRect(50, 50, 1280, 960);
	AZApp.windowFlags	= SDL_WINDOW_RESIZABLE;
	AZApp.rendererType  = AZRendererType3d;
	
	*appstate			= (__bridge void *)(AZApp);

	[AZApp startWithArgc:argc argv:argv];

	if (AZApp.viability == SDL_APP_CONTINUE)
		{
		_testMouseEvents();

		/*********************************************************************\
		|* .. and carry on with the program
		\*********************************************************************/
		}
    return AZApp.viability;
	}

/*****************************************************************************\
|* Set up the UI for this application
\*****************************************************************************/
void _testMouseEvents(void)
	{
	AZView *cv		= [AZWindow contentViewForWindow:AZApp.window];
	[cv setIdentifier:@"content-view"];

	IdentifiedView *v1 = [[IdentifiedView alloc]
							initWithFrame:NSMakeRect(0,0, 1200, 720)
								  andName:@"view1"];
	[v1 setBackgroundColour:[AZColour white]];

	AZScrollView *sv = [[AZScrollView alloc]
							initWithFrame:NSMakeRect(100, 100, 600, 360)];
	[sv setHasVerticalScroller:YES];
	[sv setHasHorizontalScroller:YES];
	[sv setBorderType: AZLineBorder];
	[sv setDocumentView:v1];
	sv.autoresizingMask = AZViewHeightSizable|AZViewWidthSizable;
	//[cv addSubview:sv];

	NSRect r = NSMakeRect(100, 470, 600, 360);
	AZSplitView *spv = [[AZSplitView alloc] initWithFrame:r];
	spv.autoresizingMask = AZViewHeightSizable|AZViewWidthSizable;

	r = NSMakeRect(0, 0, 600, 180);
	AZView *c1 = [[ColouredView alloc] initWithFrame:r colour:AZColour.white];
	[spv addSubview:c1];


//	r = NSMakeRect(10, 10, 300, 300);
//	AZView *c2 = [[ColouredView alloc] initWithFrame:r colour:AZColour.whiteColour];
//	[cv addSubview:c2];

//	AZView *c2 = [[AZView alloc] initWithFrame:NSMakeRect(0, 180, 600, 180)];
//	c2.backgroundColour = AZColour.blueColour;
//	[spv addSubview:c2];
	[spv addSubview:sv];
	spv.isVertical = YES;
	spv.dividerStyle = AZSplitViewDividerStyleThin;
	[cv addSubview:spv];


	[cv setBackgroundColour:[AZColour orange]];
	}
