//
//  AppDelegate.m
//  Azoth
//
//  Created by Simon Gornall on 1/15/25.
//

#import "AppDelegate.h"

@implementation AppDelegate

/*****************************************************************************\
|* Per-frame routine, called if exists
\*****************************************************************************/
- (SDL_AppResult) delegateFrame:(void *)state
	{
	id<AZRenderer> azr	= AZRenderer.renderer;

	[azr setClearColour:AZColour.grey50];
	[azr clear];

	// Get a texture
	AZWindowContentView *wcv = [AZWindow contentViewForWindow:AZApp.window];

	[azr setDrawColour:AZColour.green];
	[azr renderRect:NSMakeRect(50,50,100,100)];

	AZImage *icon = [AZImage imageWithSystemSymbolName:@"cyclone"];
	[azr blitFrom:icon.texture src:icon.bounds dst:NSMakeRect(200,200,48,48)];

	// Tell the renderer we're done
	[azr present];

    // carry on with the program!
    return SDL_APP_CONTINUE;
	}

@end
