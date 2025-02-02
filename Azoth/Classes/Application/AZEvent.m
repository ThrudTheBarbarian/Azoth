//
//  AZEvent.m
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#import <SDL3/SDL.h>

#import "AZEvent.h"
#import "AZView.h"

/*****************************************************************************\
|* "private" properties
\*****************************************************************************/
@interface AZEvent()

// The SDL event pointer
@property(assign, nonatomic) SDL_Event *							sdlEvent;
@end

@implementation AZEvent
/*****************************************************************************\
|* Instantiation
\*****************************************************************************/
- (instancetype) initWithSDLEvent:(SDL_Event *)e
	{
	switch (e->type)
		{
		case SDL_EVENT_MOUSE_BUTTON_DOWN:
		case SDL_EVENT_MOUSE_BUTTON_UP:
			return [self initWithMouseButtonEvent:e];

		case SDL_EVENT_MOUSE_MOTION:
			return [self initWithMouseMotionEvent:e];

		case SDL_EVENT_MOUSE_WHEEL:
			return [self initWithMouseWheelEvent:e];

		default:
			// Fall through to generic event
			break;
		}

	if (self = [super init])
		{
		_type				= AZAppKitSystem;
		_sdlEvent 			= e;
		_locationInWindow	= (NSPoint){0,0};
		_modifierFlags		= 0;
		}
	return self;
	}

/*****************************************************************************\
|* Instantiation: mouse has exited view
\*****************************************************************************/
- (instancetype) initAsExitViewEvent:(AZView *)oldView
	{
	if (self = [super init])
		{
		float mx, my;
		_state 				= SDL_GetMouseState(&mx, &my);
		_locationInWindow 	= NSMakePoint(mx, my);
		_type 				= AZMouseExited;
		_modifierFlags		= SDL_GetModState();
		}
	return self;
	}

/*****************************************************************************\
|* Instantiation: mouse has entered view
\*****************************************************************************/
- (instancetype) initAsEnterViewEvent:(AZView *)oldView
	{
	if (self = [super init])
		{
		float mx, my;
		_state 				= SDL_GetMouseState(&mx, &my);
		_locationInWindow 	= NSMakePoint(mx, my);
		_type 				= AZMouseEntered;
		_modifierFlags		= SDL_GetModState();
		}
	return self;
	}

/*****************************************************************************\
|* Instantiation: mouse button
\*****************************************************************************/
- (instancetype) initWithMouseButtonEvent:(SDL_Event *)e
	{
	if (self = [super init])
		{
		if (e->button.down)
			_type = (e->button.button == SDL_BUTTON_LEFT)
				  ? AZLeftMouseDown
				  : AZRightMouseDown;
		else
			_type = (e->button.button == SDL_BUTTON_LEFT)
				  ? AZLeftMouseUp
				  : AZRightMouseUp;

		_state				= 1 << (e->button.button - 1);
		_sdlEvent 			= e;
		_locationInWindow	= (NSPoint){e->button.x, e->button.y};
		_modifierFlags		= SDL_GetModState();
		_clickCount			= e->button.clicks;
		}
	return self;
	}

/*****************************************************************************\
|* Instantiation: mouse motion
\*****************************************************************************/
- (instancetype) initWithMouseMotionEvent:(SDL_Event *)e
	{
	if (self = [super init])
		{
		_type 				= AZMouseMoved;
		_sdlEvent 			= e;
		_state				= e->motion.state;
		_locationInWindow	= (NSPoint){e->motion.x, e->motion.y};
		_modifierFlags		= SDL_GetModState();
		_clickCount			= 0;
		}
	return self;
	}

/*****************************************************************************\
|* Instantiation: mouse wheel
\*****************************************************************************/
- (instancetype) initWithMouseWheelEvent:(SDL_Event *)e
	{
	if (self = [super init])
		{
		_type				= AZScrollWheel;
		_sdlEvent 			= e;
		_state				= 0;
		_locationInWindow	= (NSPoint){e->wheel.mouse_x, e->wheel.mouse_y};
		_modifierFlags		= SDL_GetModState();
		_clickCount			= 0;
		_deltaX				= e->wheel.x;
		_deltaY 			= e->wheel.y;
		}
	return self;
	}

/*****************************************************************************\
|* Modifier flags currently set. Flags are mapped to SDL-native types
\*****************************************************************************/
+ (NSInteger) modifierFlags
	{
	return SDL_GetModState();
	}
@end
