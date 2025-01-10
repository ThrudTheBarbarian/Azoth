//
//  AppDelegate.m
//  AZDragAndDrop
//
//  Created by Simon Gornall on 1/10/25.
//

#import "AppDelegate.h"
#import "DraggingView.h"

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
	|* Add a view that supports dragging and dropping
	\*************************************************************************/
	NSRect bounds = cv.bounds;
	bounds.size.width /= 2;
	DraggingView *left = [[DraggingView alloc] initWithFrame:bounds];
	left.backgroundColour = [AZColour colourNamed:@"goldenrod"];
	[cv addSubview:left];

	}


@end
