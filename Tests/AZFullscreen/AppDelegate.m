//
//  AppDelegate.m
//  AZFullscreen
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Azoth/Azoth.h>

#import "AppDelegate.h"
#import "MainView.h"

#define ROW_HEIGHT  (35.f)

@interface AppDelegate ()
@end

@implementation AppDelegate

/*****************************************************************************\
|* Called prior to setting up the window etc
\*****************************************************************************/
- (void) applicationWillLaunch:(NSNotification *)notification
	{
	AZApp.windowFlags = SDL_WINDOW_FULLSCREEN
					  | SDL_WINDOW_BORDERLESS
					  | SDL_WINDOW_INPUT_FOCUS
					  | SDL_WINDOW_MOUSE_FOCUS
					  ;
	}


/*****************************************************************************\
|* Called after setting up the window etc
\*****************************************************************************/
- (void) applicationDidFinishLaunching:(NSNotification *)notification
	{
	AppDelegate *ad = (AppDelegate *)AZApp.delegate;

	/*************************************************************************\
	|* Create the main view programmatically
	\*************************************************************************/
	MainView *mv = [[MainView alloc] initWithFrame:NSMakeRect(0,0,1920,1080)];
	[ad.window.contentView addSubview:mv];
	}

@end
