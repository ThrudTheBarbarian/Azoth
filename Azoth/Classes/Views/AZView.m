//
//  AZView.m
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import <SDL3/SDL.h>

#import "AZView.h"
#import "AZView+Internal.h"

/*****************************************************************************\
|* Store the top-level content-views for each window we know about
\*****************************************************************************/
static NSMutableDictionary<NSNumber *, AZView *> * _contentViews = nil;

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZView()
@end

@implementation AZView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super init])
		{
		_frame 			= frame;
		_bounds			= frame;
		_bounds.origin 	= (NSPoint){0,0};
		_subviews		= [NSMutableArray new];
		_identifier		= @"";
		}

	return self;
	}

+ (AZView *) viewWithFrame:(NSRect)frame
	{
	return [[AZView alloc] initWithFrame:frame];
	}


// MARK: Event handling

/*****************************************************************************\
|* Determine if we even want mouse events. This allows a subview to limit its
|* control of the event. By default we answer unconditional YES
\*****************************************************************************/
- (BOOL) hitTestAtPoint:(NSPoint)pt
	{ return YES; }

/*****************************************************************************\
|* Mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDown:(struct SDL_MouseButtonEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseUp:(struct SDL_MouseButtonEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseMoved:(struct SDL_MouseMotionEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseWheeled:(struct SDL_MouseWheelEvent *)e;
	{ return NO; }


// MARK: Internal methods

/*****************************************************************************\
|* Return the contentView for any given SDL_Window. If one does not exist it
|* will be created and returned
\*****************************************************************************/
+ (AZView *) contentViewForWindow:(SDL_Window *)window
	{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		_contentViews = [NSMutableDictionary new];
		});

	NSNumber *windowId 		= @(SDL_GetWindowID(window));
	AZView * contentView 	= [_contentViews objectForKey:windowId];
	if (contentView == nil)
		{
		int w, h;
		SDL_GetWindowSize(window, &w, &h);
		NSRect frame			= (NSRect){{0,0}, {w,h}};
		contentView 			= [AZView viewWithFrame:frame];
		_contentViews[windowId] = contentView;
		}
	return contentView;
	}

/*****************************************************************************\
|* Process a mouse event through the subview list recursively, seeing if the
|* view wants to handle it
\*****************************************************************************/
- (BOOL) processMouseEvent:(SDL_Event *)e atPoint:(NSPoint)p
	{
	/*************************************************************************\
	|* We do a depth-first search (so all subviews first), procedure is:
	|*  - Does the event co-ordinate lie within the subview
	|*  - if so, does -hitTest() respond back with YES (does by default)
	|*  - if so, does the specific mouse-handler return YES ?
	|*  - if so, we're done
	|*  - if not, loop to next subview
	|*  - if all subviews deny the event, then try ourselves (since this is a
	|*    recursive call)
	|*  - return whether handled
	\*************************************************************************/

	BOOL done 	= NO;
	for (AZView *subview in _subviews)
		{
		done = [subview processMouseEvent:e atPoint:p];
		if (done)
			break;
		}

	/*************************************************************************\
	|* This is where the 1st view without subviews will start affecting 'done'
	\*************************************************************************/
	if (!done)
		{
		if (NSPointInRect(p, [self frame]))
			{
			if ([self hitTestAtPoint:p])
				{
				switch (e->type)
					{
					case SDL_EVENT_MOUSE_BUTTON_DOWN:
						done = [self mouseDown:(SDL_MouseButtonEvent *)e];
						break;

					case SDL_EVENT_MOUSE_BUTTON_UP:
						done = [self mouseUp:(SDL_MouseButtonEvent *)e];
						break;

					case SDL_EVENT_MOUSE_MOTION:
						done = [self mouseMoved:(SDL_MouseMotionEvent *)e];
						break;

					case SDL_EVENT_MOUSE_WHEEL:
						done = [self mouseWheeled:(SDL_MouseWheelEvent *)e];
						break;

					default:
						// FIXME: SDL Log here
						break;
					}
				}
			}
		}

	return done;
	}


// MARK: Private methods

@end
