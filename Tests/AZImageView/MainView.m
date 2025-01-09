//
//  MainView.m
//  Azoth
//
//  Created by Simon Gornall on 1/9/25.
//

#import <SDL3/SDL.h>

#import "MainView.h"

@implementation MainView

- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		}
	return self;
	}

/*****************************************************************************\
|* indicates whether we accept first responder status
\*****************************************************************************/
- (BOOL) acceptsFirstResponder
	{
	return YES;
	}

/*****************************************************************************\
|* Return YES to accept becoming the first responder. Called from the AZWindow
|* makeFirstResponder method. Do not invoke directly
\*****************************************************************************/
- (BOOL) becomeFirstResponder
	{
	SDL_Log("Becoming first responder");
	return YES;
	}

/*****************************************************************************\
|* Return YES to accept un-becoming the first responder. Called from the
|* AZWindow makeFirstResponder method. Do not invoke directly. Subclasses can
|* override this method to update state or perform some action such as
|* unhighlighting the selection, or to return false, refusing to relinquish
|* first responder status
\*****************************************************************************/
- (BOOL) resignFirstResponder
	{
	SDL_Log("Resigning first responder");
	return YES;
	}

- (BOOL) keyDown:(struct SDL_KeyboardEvent *)e
	{
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
	[nc postNotificationName:@"key-down" object:nil];

	return YES;
	}
@end
