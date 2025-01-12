//
//  DraggingView.m
//  AZDragAndDrop
//
//  Created by Simon Gornall on 1/10/25.
//

#import "DraggingView.h"

@interface DraggingView()
@property(strong, nonatomic) AZImage *				srcImg;
@property(assign, nonatomic) NSRect					srcRect;
@end

@implementation DraggingView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		_srcImg = [AZImage imageWithSystemSymbolName:@"cyclone"];
		_srcRect = NSMakeRect(200,200,_srcImg.width, _srcImg.height);
		}
	return self;
	}

/*****************************************************************************\
|* Draw
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	[painter image:_srcImg to:_srcRect];
	}

/*****************************************************************************\
|* Handle mousedown
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];
	if (NSPointInRect(p, _srcRect))
		{
		NSMutableArray<AZDraggingItem *> *items = NSMutableArray.new;

		AZDraggingItem *item = [AZDraggingItem itemWithPasteboardWriter:_srcImg];
		[items addObject:item];
		[item setDraggingFrame:_srcRect contents:_srcImg];
		[self beginDraggingSessionWithItems:items event:e source:self];
		}

	return YES;
	}

// MARK: AZDraggingSource

/*****************************************************************************\
|* We want to allow copy-drags
\*****************************************************************************/
- (AZDragOperation) draggingSession:(AZDraggingSession *)session
			sourceOperationMaskForDraggingContext:(AZDraggingContext)context
	{
	return AZDragOperationCopy;
	}

/*****************************************************************************\
|* We want to know where the drag started
\*****************************************************************************/
- (void) draggingSession:(AZDraggingSession *)session willBeginAtPoint:(NSPoint)p
	{
	NSLog(@"src: drag start at %@", NSStringFromPoint(p));
	}

/*****************************************************************************\
|* We want to know where the drag ended
\*****************************************************************************/
- (void) draggingSession:(AZDraggingSession *)session
			endedAtPoint:(NSPoint)p
			   operation:(AZDragOperation)op
	{
	NSLog(@"src: drag end at %@ [%d]", NSStringFromPoint(p), op);
	}

@end
