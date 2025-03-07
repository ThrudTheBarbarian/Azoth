//
//  AZEvent.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/25/24.
//
// Note: It is expected that AZEvent objects are very ephemeral. They take a
// weak reference to the SDL_Event that defines them and therefore only have
// the lifetime of that underlying event. They are typically created on event
// reception in the SDL callback and live a single iteration through that
// event cycle

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class AZView;
union SDL_Event;

@interface AZEvent : NSObject
/*****************************************************************************\
|* Instantiation : generic - calls into the specific initialisers if it
|*                 recognises the event as one of the below
\*****************************************************************************/
- (instancetype) initWithSDLEvent:(union SDL_Event *)e;

/*****************************************************************************\
|* Instantiation : specific
\*****************************************************************************/
- (instancetype) initWithMouseButtonEvent:(union SDL_Event *)sdlEvent;
- (instancetype) initWithMouseMotionEvent:(union SDL_Event *)sdlEvent;
- (instancetype) initWithMouseWheelEvent:(union SDL_Event *)sdlEvent;
- (instancetype) initWithKeyEvent:(union  SDL_Event *)sdlEvent;

/*****************************************************************************\
|* Instantiation: mouse has entered/exited view
\*****************************************************************************/
- (instancetype) initAsExitViewEvent:(AZView *)oldView;
- (instancetype) initAsEnterViewEvent:(AZView *)oldView;

/*****************************************************************************\
|* Return the current modifier state
\*****************************************************************************/
+ (NSInteger) modifierFlags;

/*****************************************************************************\
|* Return the event co-ordinates (if any) in the global window space
\*****************************************************************************/
- (NSPoint) locationInWindow;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The type of event
@property(assign, nonatomic) AZEventType					type;

// Position in global co-ords
@property(assign, nonatomic, readonly) NSPoint				locationInWindow;

// Which buttons are pressed (from AZButtonMask)
@property(assign, nonatomic, readonly) NSInteger			state;

// AZEvent key modifier masks
@property(assign, nonatomic, readonly) NSInteger			modifierFlags;

// How many clicks
@property(assign, nonatomic, readonly) NSInteger			clickCount;

// Mouse-wheel event, change in X
@property(assign, nonatomic, readonly) NSInteger			deltaX;

// Mouse-wheel event, change in Y
@property(assign, nonatomic, readonly) NSInteger			deltaY;

// Which keyboard the key was pressed on
@property(assign, nonatomic, readonly) SDL_KeyboardID		keyboard;

// Which Scancode we got
@property(assign, nonatomic, readonly) SDL_Scancode			scanCode;

// Which Keycode we got
@property(assign, nonatomic, readonly) SDL_Keycode			keyCode;

// Whether this was a repeated keypress
@property(assign, nonatomic, readonly) BOOL					aRepeat;

// The character pressed in the event
@property(assign, nonatomic, readonly) NSString *			characters;


@end

NS_ASSUME_NONNULL_END
