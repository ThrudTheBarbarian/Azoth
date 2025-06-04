//
//  AZResponder.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*****************************************************************************\
|* SDL event structures/unions
\*****************************************************************************/
@class AZEvent;

union SDL_Event;
struct SDL_KeyboardEvent;
struct SDL_TextEditingEvent;
struct SDL_TextInputEvent;

@interface AZResponder : NSObject


// MARK: First responder

/*****************************************************************************\
|* indicates whether we accept first responder status
\*****************************************************************************/
- (BOOL) acceptsFirstResponder;

/*****************************************************************************\
|* Return YES to accept becoming the first responder. Called from the AZWindow
|* makeFirstResponder method. Do not invoke directly
\*****************************************************************************/
- (BOOL) becomeFirstResponder;

/*****************************************************************************\
|* Return YES to accept un-becoming the first responder. Called from the
|* AZWindow makeFirstResponder method. Do not invoke directly. Subclasses can
|* override this method to update state or perform some action such as
|* unhighlighting the selection, or to return false, refusing to relinquish
|* first responder status
\*****************************************************************************/
- (BOOL) resignFirstResponder;

// MARK: Event handling

/*****************************************************************************\
|* Mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e;

/*****************************************************************************\
|* Mouse-button-up event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseUp:(AZEvent *)e;

/*****************************************************************************\
|* Mouse-moved event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseMoved:(AZEvent *)e;

/*****************************************************************************\
|* Mouse-dragged event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDragged:(AZEvent *)e;

/*****************************************************************************\
|* Mouse-wheel event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseWheeled:(AZEvent *)e;

/*****************************************************************************\
|* Right mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) rightMouseDown:(AZEvent *)e;

/*****************************************************************************\
|* Right mouse-button-dragged event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) rightMouseDragged:(AZEvent *)e;

/*****************************************************************************\
|* Right mouse-button-up event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) rightMouseUp:(AZEvent *)e;

/*****************************************************************************\
|* Key event handling.
\*****************************************************************************/
- (BOOL) keyDown:(AZEvent *)e;

- (BOOL) keyUp:(AZEvent *)e;

// composition-related events. TBD
- (BOOL) textEditingCandidates:(union SDL_Event *)e;
- (BOOL) textEditing:(struct SDL_TextEditingEvent *)e;
- (BOOL) textInput:(struct SDL_TextInputEvent *)e;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Identifier, used for table views etc.
@property(copy, nonatomic) NSString *						identifier;

@end

NS_ASSUME_NONNULL_END
