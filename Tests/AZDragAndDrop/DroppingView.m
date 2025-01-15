//
//  DroppingView.m
//  Azoth
//
//  Created by Simon Gornall on 1/11/25.
//

#import "DroppingView.h"

@interface DroppingView()
@property(assign, nonatomic) NSRect					dstRect;

@property(assign, nonatomic) BOOL 					mouseIsOver;
@end

@implementation DroppingView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		_dstRect = NSMakeRect(100,100,120, 120);
		_mouseIsOver = NO;

		[self registerForDraggedTypes:@[AZPasteboardTypeImage]];
		}
	return self;
	}


/*****************************************************************************\
|* Draw
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	if (_mouseIsOver)
		[painter rectangleWithRect:_dstRect filled:YES colour:AZColour.red];
	else
		[painter rectangleWithRect:_dstRect colour:AZColour.blue];
	}

/*****************************************************************************\
|* Dragging has entered this view, return what drop is acceptable
\*****************************************************************************/
- (AZDragOperation)draggingEntered:(nonnull id<AZDraggingInfo>)sender
	{
	NSLog(@"Entered drop view");
	NSPoint p = [self convertPoint:sender.draggingLocation fromView:nil];
	_mouseIsOver = NSPointInRect(p, _dstRect);
	return [self isAcceptedDrop];
	}

/*****************************************************************************\
|* Dragging has exited this view
\*****************************************************************************/
- (void)draggingExited:(nonnull id<AZDraggingInfo>)sender
	{
	NSLog(@"Exited drop view");
	}

/*****************************************************************************\
|* Dragging has lingered in this view, return what drop is now acceptable
\*****************************************************************************/
- (AZDragOperation)draggingUpdated:(nonnull id<AZDraggingInfo>)sender
	{
	NSPoint p = [self convertPoint:sender.draggingLocation fromView:nil];
	_mouseIsOver = NSPointInRect(p, _dstRect);
	[self setNeedsDisplay:YES];
	return [self isAcceptedDrop];
	}

/*****************************************************************************\
|* Inform the sender if we want to be updated (other than exit/enter)
\*****************************************************************************/
- (BOOL)wantsPeriodicDraggingUpdates
	{
	return YES;
	}

/*****************************************************************************\
|* Decide whethere we accept this drop or not
\*****************************************************************************/
- (AZDragOperation) isAcceptedDrop
	{
	return _mouseIsOver ? AZDragOperationCopy : AZDragOperationNone;
	}

/*****************************************************************************\
|* We got a mouse-release in an acceptable drop-target, prepare for the actual
|* drop
\*****************************************************************************/
- (BOOL) prepareForDragOperation:(id<AZDraggingInfo>) sender
	{
	return YES;
	}

/*****************************************************************************\
|* We got a mouse-release in an acceptable drop-target, prepare for the actual
|* drop
\*****************************************************************************/
- (BOOL) performDragOperation:(id<AZDraggingInfo>) sender
	{
	AZPasteboard *pb = [AZPasteboard draggingPasteboard];
	id plist		 = [pb propertyListForType:AZPasteboardTypeImage];
	NSLog(@"dropped: %@", plist);
	return YES;
	}

/*****************************************************************************\
|* Clean up after the drop
\*****************************************************************************/
- (void) concludeDragOperation:(id<AZDraggingInfo>)sender
	{
	_mouseIsOver = NO;
	[self setNeedsDisplay:YES];
	}

@end
