//
//  AZDraggingSession.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/9/25.
//

#import "AZDraggingItem.h"
#import "AZDraggingSession.h"
#import "AZPasteboard.h"
#import "AZWindow.h"

@interface AZDraggingSession()
// Window we were created by
@property (strong, nonatomic) AZWindow * 								window;

@end

@implementation AZDraggingSession
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithWindow:(AZWindow *)window
	{
	if (self = [super init])
		{
		_window   	= window;
		_lastView 	= nil;
		_lastUpdate	= nil;
		_response 	= AZDragOperationNone;
		}
	return self;
	}

/*****************************************************************************\
|* The number of valid items for a drop operation
\*****************************************************************************/
- (NSInteger) numberOfValidItemsForDrop
	{
	AZPasteboard *pb = [AZPasteboard pasteboardWithName:AZPasteboardNameDrag];
	return pb.itemCount;
	}

/*****************************************************************************\
|* We only support in-window drag, so source window = destination window
\*****************************************************************************/
- (AZWindow *) draggingDestinationWindow
	{
	return _window;
	}

/*****************************************************************************\
|* The current location of the mouse pointer
\*****************************************************************************/
- (NSPoint) draggingLocation
	{
	return _at;
	}

/*****************************************************************************\
|* The current location of the dragged image’s origin
\*****************************************************************************/
- (NSPoint) draggedImageLocation
	{
	if (_items.count > 0)
		{
		AZDraggingItem* item = _items[0];
		float dx = item.draggingFrame.origin.x - _start.x;
		float dy = item.draggingFrame.origin.y - _start.y;
		return NSMakePoint(_at.x-dx, _at.y-dy);
		}
	return _at;
	}

/*****************************************************************************\
|* Information about the dragging operation and the data it contains
\*****************************************************************************/
- (AZDragOperation) draggingSourceOperationMask
	{
	return _operation;
	}


/*****************************************************************************\
|* The source, or owner, of the dragged data
\*****************************************************************************/
- (id<AZDraggingSource>) draggingSource
	{
	return _source;
	}


/*****************************************************************************\
|* A number that uniquely identifies the dragging session
\*****************************************************************************/
- (NSInteger) draggingSequenceNumber
	{
	AZPasteboard *pb = [AZPasteboard pasteboardWithName:AZPasteboardNameDrag];

	return pb.changes;
	}

/*****************************************************************************\
|*
\*****************************************************************************/
- (AZPasteboard *) draggingPasteboard
	{
	return [AZPasteboard pasteboardWithName:AZPasteboardNameDrag];
	}

@end
