//
//  AppDelegate.m
//  NibTest
//
//  Created by Simon Gornall on 1/1/25.
//

#import "AppDelegate.h"

#define ROW_HEIGHT  (35.f)

@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)notification
	{
	/*************************************************************************\
	|* Try to load a view-xib in this bundle
	\*************************************************************************/
	AZRenderer *azr = AZRenderer.renderer;
	[azr syncToVsync:YES];
	}


- (void) clicked:(id)sender
	{
	NSLog(@"Button '%@' was clicked", [sender stringValue]);
	}

@end
