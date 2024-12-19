//
//  AZResponder.h
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*****************************************************************************\
|* SDL event structures/unions
\*****************************************************************************/
union SDL_Event;
struct SDL_MouseButtonEvent;
struct SDL_MouseMotionEvent;
struct SDL_MouseWheelEvent;
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
- (BOOL) mouseDown:(struct SDL_MouseButtonEvent *)e;

/*****************************************************************************\
|* Mouse-button-up event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseUp:(struct SDL_MouseButtonEvent *)e;

/*****************************************************************************\
|* Mouse-moved event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseMoved:(struct SDL_MouseMotionEvent *)e;

/*****************************************************************************\
|* Mouse-dragged event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDragged:(struct SDL_MouseMotionEvent *)e;

/*****************************************************************************\
|* Mouse-wheel event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseWheeled:(struct SDL_MouseWheelEvent *)e;

/*****************************************************************************\
|* Key event handling. This copes with composition as well as simple key
|* presses. See AZTextField for details of how to use
\*****************************************************************************/
- (BOOL) keyDown:(struct SDL_KeyboardEvent *)e;
- (BOOL) textEditingCandidates:(union SDL_Event *)e;
- (BOOL) textEditing:(struct SDL_TextEditingEvent *)e;
- (BOOL) textInput:(struct SDL_TextInputEvent *)e;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Identifier, purely for debugging
@property(copy, nonatomic) NSString *						identifier;

@end

NS_ASSUME_NONNULL_END
