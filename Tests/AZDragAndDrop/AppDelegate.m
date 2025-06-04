//
//  AppDelegate.m
//  AZDragAndDrop
//
//  Created by ThrudTheBarbarian for Azoth.
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
	AZView *contentView = [AZWindow contentViewForWindow:AZApp.window];
	[contentView setIdentifier:@"content-view"];

	/*************************************************************************\
	|* Add a view that supports dragging, taking up the left hand side of the
	|* window's content-view
	\*************************************************************************/
	NSRect bounds = contentView.bounds;
	bounds.size.width /= 2;
	DraggingView *left = [[DraggingView alloc] initWithFrame:bounds];
	left.backgroundColour = [AZColour colourNamed:@"goldenrod"];
	[contentView addSubview:left];

	/*************************************************************************\
	|* Add a view that supports dropping, taking up the right hand side of the
	|* window's content-view
	\*************************************************************************/
	bounds = contentView.bounds;
	bounds.size.width /= 2;
	bounds.origin.x = bounds.size.width;
	DroppingView *right = [[DroppingView alloc] initWithFrame:bounds];
	right.backgroundColour = [AZColour colourNamed:@"snow"];
	[contentView addSubview:right];
	}


@end
