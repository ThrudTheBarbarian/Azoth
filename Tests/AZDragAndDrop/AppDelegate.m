//
//  AppDelegate.m
//  AZDragAndDrop
//
//  Created by Simon Gornall on 1/10/25.
//

#import "AppDelegate.h"
#import "DraggingView.h"
#import "DroppingView.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)notification
	{
	/*************************************************************************\
	|* Set up the UI for this application
	\*************************************************************************/
	AZView *cv		= [AZWindow contentViewForWindow:AZApp.window];
	[cv setIdentifier:@"content-view"];

	/*************************************************************************\
	|* Add a view that supports dragging
	\*************************************************************************/
	NSRect bounds = cv.bounds;
	bounds.size.width /= 2;
	DraggingView *left = [[DraggingView alloc] initWithFrame:bounds];
	left.backgroundColour = [AZColour colourNamed:@"goldenrod"];
	[cv addSubview:left];

	/*************************************************************************\
	|* Add a view that supports dropping
	\*************************************************************************/
	bounds = cv.bounds;
	bounds.size.width /= 2;
	bounds.origin.x = bounds.size.width;
	DroppingView *right = [[DroppingView alloc] initWithFrame:bounds];
	right.backgroundColour = [AZColour colourNamed:@"snow"];
	[cv addSubview:right];

	}


@end
