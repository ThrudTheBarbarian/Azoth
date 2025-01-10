//
//  AZWindow+Internal.m
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import "AZDraggingSession.h"
#import "AZEventSink.h"
#import "AZView.h"
#import "AZWindow+Internal.h"
#import "AZResponder.h"

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
- (AZDraggingSession *)
_beginDraggingSessionWithItems:(NSArray<AZDraggingItem *> *) items
						 event:(AZEvent *) event
					    source:(id<AZDraggingSource>) source
	{
	AZDraggingSession *session = AZDraggingSession.new;

	session.sink = [[AZEventSink alloc] initWithAction:@selector(dragEvent:)
											 forTarget:self];
	[session.sink addEventMask:AZLeftMouseUpMask];
	[session.sink addEventMask:AZMouseMovedMask];
	return session;
	}


/*****************************************************************************\
|* Mouse event processing for dragging
\*****************************************************************************/
- (void) dragEvent:(AZEvent *)e
	{
	}

@end
