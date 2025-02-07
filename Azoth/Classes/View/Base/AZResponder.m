//
//  AZResponder.m
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import "AZResponder.h"

@implementation AZResponder

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_identifier = [NSString stringWithFormat:@"%@{%p}", [self class], self];
		}
	return self;
	}


// MARK: First responder

/*****************************************************************************\
|* indicates whether we accept first responder status
\*****************************************************************************/
- (BOOL) acceptsFirstResponder
	{
	return NO;
	}

/*****************************************************************************\
|* Return YES to accept becoming the first responder. Called from the AZWindow
|* makeFirstResponder method. Do not invoke directly
\*****************************************************************************/
- (BOOL) becomeFirstResponder
	{
	return YES;
	}

/*****************************************************************************\
|* Return YES to accept un-becoming the first responder. Called from the
|* AZWindow makeFirstResponder method. Do not invoke directly. Subclasses can
|* override this method to update state or perform some action such as
|* unhighlighting the selection, or to return false, refusing to relinquish
|* first responder status
\*****************************************************************************/
- (BOOL) resignFirstResponder
	{
	return YES;
	}

// MARK: Event handling

/*****************************************************************************\
|* Mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-button-up event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseUp:(AZEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-moved event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseMoved:(AZEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-dragged event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDragged:(AZEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-wheel event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseWheeled:(AZEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Right mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) rightMouseDown:(AZEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Right mouse-button-up event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) rightMouseUp:(AZEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Key event handling. This copes with composition as well as simple key
|* presses. See AZTextField for details of how to use
\*****************************************************************************/
- (BOOL) keyDown:(AZEvent *)e
	{ return NO; }

- (BOOL) keyUp:(AZEvent *)e
	{ return NO; }

- (BOOL) textEditingCandidates:(union SDL_Event *)e
	{ return NO; }

- (BOOL) textEditing:(struct SDL_TextEditingEvent *)e
	{ return NO; }

- (BOOL) textInput:(struct SDL_TextInputEvent *)e
	{ return NO; }


@end
