//
//  AZEventSink.h
//  Azoth
//
//  Created by Simon Gornall on 12/19/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

union SDL_Event;

@interface AZEventSink : NSObject


/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithAction:(SEL)action forTarget:(NSObject *)target;

/*****************************************************************************\
|* Clear the bitmask of which events we match
\*****************************************************************************/
- (void) clearEventMask;

/*****************************************************************************\
|* Add an event to the types we want to match
\*****************************************************************************/
- (void) addEventType:(NSUInteger)type;

/*****************************************************************************\
|* Determine if this sink matches a given event, using its filter
\*****************************************************************************/
- (BOOL) matches:(union SDL_Event *)e;

/*****************************************************************************\
|* Make the sink call its action with the corresponding event
\*****************************************************************************/
- (BOOL) call:(union SDL_Event *)e;

@end

NS_ASSUME_NONNULL_END
