//
//  AZEventSink.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/19/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZEvent;

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
- (void) addEventMask:(NSUInteger)type;

/*****************************************************************************\
|* Determine if this sink matches a given event, using its filter
\*****************************************************************************/
- (BOOL) matches:(AZEvent *)e;

/*****************************************************************************\
|* Make the sink call its action with the corresponding event
\*****************************************************************************/
- (BOOL) call:(AZEvent *)e;

@end

NS_ASSUME_NONNULL_END
