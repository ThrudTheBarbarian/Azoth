//
//  AppDelegate.m
//  AZDragAndDrop
//
//  Created by Simon Gornall on 1/10/25.
//

#import "AppDelegate.h"


#import "AppDelegate.h"

#define ROW_HEIGHT  (35.f)

@interface AppDelegate ()
@end

@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)notification
	{
	/*************************************************************************\
	|* Set up for vsync, though it doesn't seem to make much difference. We
	|* still consume far too much CPU for my liking - might have to look into
	|* how to limit FPS
	\*************************************************************************/
	AZRenderer *azr = AZRenderer.renderer;
	[azr syncToVsync:YES];
	}


@end
