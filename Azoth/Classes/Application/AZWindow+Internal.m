//
//  AZWindow+Internal.m
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZDraggingItem.h"
#import "AZDraggingSession.h"
#import "AZEvent.h"
#import "AZEventSink.h"
#import "AZPasteboard.h"
#import "AZView.h"
#import "AZWindow+Internal.h"
#import "AZWindowContentView.h"
#import "AZResponder.h"

/*****************************************************************************\
|* We can only be dragging the mouse in one instance at a time, so this is ok
|* to be a static reference
\*****************************************************************************/
static AZDraggingSession *_session = nil;


@implementation AZWindow (Internal)

/*****************************************************************************\
|* Called by a view in this window when it adds a subview
\*****************************************************************************/
- (void) _didAddSubview:(AZView *)view
	{
	[self makeFirstResponder:view];
	}

/*****************************************************************************\
|* Initiate a dragging session. Should be called with the mouse-down event
|* that starts the drag going
|*
|* what we do:
|*
|* - create an event-sink to capture mouse movement everywhere in the window
|* - change the cursor to indicate a drag
|* - fetch the images/rects to handle the drag visuals
|* - use the sink/AZContentView to render the drag on top of all the views
|*   as the last stage of _renderToScreen
\*****************************************************************************/
- (nullable AZDraggingSession *)
		_beginDraggingSessionWithItems:(NSArray<AZDraggingItem *> *) items
								 event:(AZEvent *) event
								source:(id<AZDraggingSource>) source
	{
	/*************************************************************************\
	|* This should never happen!
	\*************************************************************************/
	if ((_session != nil) && (_session.sink != nil))
		{
		[AZApp removeEventSink:_session.sink];
		_session = nil;
		SDL_Log("WARNING: Removing stale event sink");
		}

	/*************************************************************************\
	|* If there's nothing to drag, then exit early
	\*************************************************************************/
	if (items.count == 0)
		return nil;

	_session = AZDraggingSession.new;
	_session.items = items;

	/*************************************************************************\
	|* Check that the source wants to drag something. We only support in-app
	|* drags right now
	\*************************************************************************/
	AZDragOperation op = [source draggingSession:_session
	  sourceOperationMaskForDraggingContext:AZDraggingContextWithinApplication];

	/*************************************************************************\
	|* If we want to drag something, set all the apparatus up here
	\*************************************************************************/
	if (op != AZDragOperationNone)
		{
		AZPasteboard *board = nil;

		// First we want to divert all the mouse-move/mouse-up events to
		// our event-sink
		_session.sink = [[AZEventSink alloc] initWithAction:@selector(dragEvent:)
												  forTarget:self];
		[_session.sink addEventMask:AZLeftMouseUpMask];
		[_session.sink addEventMask:AZMouseMovedMask];
		[AZApp addEventSink:_session.sink];

		// Now configure the dragging session. This is a temporary record of
		// what all the parties want, only valid during the drag
		_session.source 		= source;
		_session.operation 		= op;
		_session.start 			= event.locationInWindow;
		self.contentView.drag 	= _session;

		// And create the draggable content on the Drag pasteboard
		board = [AZPasteboard pasteboardWithName:AZPasteboardNameDrag];
		[board clearContents];
		NSMutableArray *writers = NSMutableArray.new;
		for (AZDraggingItem *item in items)
			[writers addObject:item.writer];
		[board writeObjects:writers];
		}
	else
		return nil;

	return _session;
	}


/*****************************************************************************\
|* Mouse event processing for dragging
\*****************************************************************************/
- (void) dragEvent:(AZEvent *)e
	{
	/*************************************************************************\
	|* Handle drag events
	\*************************************************************************/
	if (e.type == AZMouseMoved)
		{
		_session.at = e.locationInWindow;

		/*********************************************************************\
		|* Send a drag-started before drag-moved
		\*********************************************************************/
		if (_session.dragStarted == NO)
			{
			SEL beginSel = SELECTOR(@"draggingSession:willBeginAtPoint:");
			if ([_session.source respondsToSelector:beginSel])
				[_session.source draggingSession:_session
								willBeginAtPoint:e.locationInWindow];
			_session.dragStarted = YES;
			}
		else
			{
			SEL moveSel = SELECTOR(@"draggingSession:movedToPoint:");
			if ([_session.source respondsToSelector:moveSel])
				[_session.source draggingSession:_session
									movedToPoint:e.locationInWindow];
			}
		}

	/*************************************************************************\
	|* Handle mouse-release
	\*************************************************************************/
	else
		{
		/*********************************************************************\
		|* Send a drag-ended
		\*********************************************************************/
		SEL moveSel = SELECTOR(@"draggingSession:endedAtPoint:operation:");
		if ([_session.source respondsToSelector:moveSel])
			[_session.source draggingSession:_session
								endedAtPoint:e.locationInWindow
								   operation:_session.operation];

		/*********************************************************************\
		|* Clean up
		\*********************************************************************/
		[AZApp removeEventSink:_session.sink];
		_session 				= nil;
		self.contentView.drag 	= nil;
		}
	}

@end
