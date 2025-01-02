//
//  AZEventSink.m
//  Azoth
//
//  Created by Simon Gornall on 12/19/24.
//

#import <SDL3/SDL.h>

#import "AZEventSink.h"

@interface AZEventSink()

// Method to call with the event, if we match
@property(nullable) SEL									action;
@property(nullable, weak, nonatomic) NSObject *			target;
@property(assign, nonatomic) NSUInteger					maxEvent;
@property(nullable, assign, nonatomic)	uint8_t *		map;
@end

@implementation AZEventSink

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithAction:(SEL)action forTarget:(NSObject *)target;
	{
	if (self = [super init])
		{
		_action 	= action;
		_target		= target;
		_map		= NULL;
		_maxEvent	= 0;
		}
	return self;
	}

/*****************************************************************************\
|* Clear up on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	if (_map != NULL)
		{
		free(_map);
		_map = NULL;
		}
	}

/*****************************************************************************\
|* Add an event into the filter-map
\*****************************************************************************/
- (void) addEventType:(NSUInteger)type
	{
	if (type >= _maxEvent)
		{
		uint8_t *map = (uint8_t *) calloc(1, type+1);
		memcpy(map, _map, _maxEvent);
		free(_map);
		_map = map;
		_maxEvent = type;
		}
	_map[type] = 1;
	}

/*****************************************************************************\
|* Clear the bitmask of which events we match
\*****************************************************************************/
- (void) clearEventMask
	{
	memset(_map, 0, _maxEvent);
	}

/*****************************************************************************\
|* Determine if this sink matches a given event, using its filter
\*****************************************************************************/
- (BOOL) matches:(SDL_Event *)event
	{
	if (event)
		if (event->type < _maxEvent)
			if (_map[event->type])
				return YES;
	return NO;
	}

/*****************************************************************************\
|* Make the sink call its action with the corresponding event
\*****************************************************************************/
- (BOOL) call:(union SDL_Event *)e
	{
	if ((_target != nil) && (_action != nil))
		{
		IMP imp = [_target methodForSelector:_action];
		void (*func)(id, SEL, union SDL_Event *) = (void *)imp;
		func(_target, _action, e);
		return YES;
		}
	return NO;
	}


@end
