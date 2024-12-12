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
		_superview		= nil;
		}

	return self;
	}

+ (AZView *) viewWithFrame:(NSRect)frame
	{
	return [[AZView alloc] initWithFrame:frame];
	}


// MARK: Event manipulation

/*****************************************************************************\
|* Determine if we even want mouse events. This allows a subview to limit its
|* control of the event. By default we answer unconditional YES
\*****************************************************************************/
- (BOOL) hitTestAtPoint:(NSPoint)pt
	{ return YES; }

/*****************************************************************************\
|* Convert a point from another window's co-ordinate system to our own. Calling
|* this with nil will convert from window co-ordinates. The view must be in
|* the superview-hierarchy otherwise.
\*****************************************************************************/
- (NSPoint) convertPoint:(NSPoint)p fromView:(nullable AZView *)otherView
	{
	AZView *view = self;
	while (view != otherView)
		{
		if (view == nil)
			break;

		p.x -= view.frame.origin.x;
		p.y -= view.frame.origin.y;
		view = view.superview;
		}

	return p;
	}



// MARK: Event handling

/*****************************************************************************\
|* Mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDown:(struct SDL_MouseButtonEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-button-up event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseUp:(struct SDL_MouseButtonEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-moved event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseMoved:(struct SDL_MouseMotionEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-dragged event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDragged:(struct SDL_MouseMotionEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-wheel event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseWheeled:(struct SDL_MouseWheelEvent *)e;
	{ return NO; }



// MARK: View processing

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
		contentView.window		= window;
		_contentViews[windowId] = contentView;
		}
	return contentView;
	}

/*****************************************************************************\
|* Add a subview to the list of views
\*****************************************************************************/
- (BOOL) addSubview:(AZView *)view
	{
	[_subviews addObject:view];
	view.superview 	= self;
	view.window		= _window;

	return YES;
	}

/*****************************************************************************\
|* Add a subview to the list of views, in front of another view
\*****************************************************************************/
- (BOOL) addSubview:(AZView *)view before:(AZView *)other
	{
	BOOL ok 		= NO;
	NSInteger idx 	= 0;

	for (AZView *view in _subviews)
		if (view == other)
			{
			[_subviews insertObject:view atIndex:idx];
			ok = YES;
			}

	if (!ok)
		[_subviews addObject:view];

	view.superview = self;
	return ok;
	}

/*****************************************************************************\
|* Add a subview to the list of views, behind another view
\*****************************************************************************/
- (BOOL) addSubview:(AZView *)view after:(AZView *)other
	{
	BOOL ok 		= NO;
	NSInteger idx 	= 0;

	for (AZView *view in _subviews)
		if (view == other)
			{
			if (idx < _subviews.count-1)
				[_subviews insertObject:view atIndex:idx+1];
			else
				[_subviews addObject:view];
			ok = YES;
			}

	if (!ok)
		[_subviews addObject:view];

	view.superview = self;
	return ok;
	}



// MARK: Internal methods

/*****************************************************************************\
|* Process a mouse event through the subview list recursively, seeing if the
|* view wants to handle it
\*****************************************************************************/
- (BOOL) processMouseEvent:(SDL_Event *)e atPoint:(NSPoint)p 
	{
	static AZView * dragView = nil;

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
		NSPoint local = NSMakePoint(p.x - subview.frame.origin.x,
									p.y - subview.frame.origin.y);
		done = [subview processMouseEvent:e atPoint:local];
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
				SDL_MouseMotionEvent *mme = (SDL_MouseMotionEvent *)e;
				SDL_MouseButtonEvent *mbe = (SDL_MouseButtonEvent *)e;
				SDL_MouseWheelEvent  *mwe = (SDL_MouseWheelEvent *)e;

				switch (e->type)
					{
					case SDL_EVENT_MOUSE_BUTTON_DOWN:
						done = [self mouseDown:mbe];
						dragView = self;
						break;

					case SDL_EVENT_MOUSE_BUTTON_UP:
						done = (dragView != nil)
							 ? [dragView mouseUp:mbe]
							 : [self mouseUp:mbe];
						dragView = nil;
						break;

					case SDL_EVENT_MOUSE_MOTION:
						// If we're no longer pressing the button, we might
						// have dragged out of window and released it. Zero out
						// the dragging-view
						if ((mme->state & SDL_BUTTON_LEFT) == 0)
							dragView = nil;

						done = (dragView != nil)
							 ? [dragView mouseDragged:mme]
							 : [self mouseMoved:mme];
						break;

					case SDL_EVENT_MOUSE_WHEEL:
						done = [self mouseWheeled:mwe];
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
