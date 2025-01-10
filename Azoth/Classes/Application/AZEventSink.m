//
//  AZEventSink.m
//  Azoth
//
//  Created by Simon Gornall on 12/19/24.
//

#import <SDL3/SDL.h>

#import "AZEvent.h"
#import "AZEventSink.h"

@interface AZEventSink()

// Method to call with the event, if we match
@property(nullable) SEL									action;
@property(nullable, weak, nonatomic) NSObject *			target;

@property(assign, nonatomic) NSUInteger					mask;
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
		}
	return self;
	}

/*****************************************************************************\
|* Add an event into the filter-map
\*****************************************************************************/
- (void) addEventMask:(NSUInteger)type
	{
	_mask |= type;
	}

/*****************************************************************************\
|* Clear the bitmask of which events we match
\*****************************************************************************/
- (void) clearEventMask
	{
	_mask = 0;
	}

/*****************************************************************************\
|* Determine if this sink matches a given event, using its filter
\*****************************************************************************/
- (BOOL) matches:(AZEvent *)event
	{
	if (event && (((1 << event.type) & _mask) != 0))
		return YES;
	return NO;
	}

/*****************************************************************************\
|* Make the sink call its action with the corresponding event
\*****************************************************************************/
- (BOOL) call:(AZEvent *)e
	{
	if ((_target != nil) && (_action != nil))
		{
		IMP imp = [_target methodForSelector:_action];
		void (*func)(id, SEL, AZEvent *) = (void *)imp;
		func(_target, _action, e);
		return YES;
		}
	return NO;
	}


@end
