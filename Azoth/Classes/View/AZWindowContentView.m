//
//  AZWindowContentView.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <SDL3/SDL.h>

#import "AZColour.h"
#import "AZDraggingItem.h"
#import "AZDraggingSession.h"
#import "AZPainter.h"
#import "AZView.h"
#import "AZView+Internal.h"
#import "AZWindow.h"
#import "AZWindow+Internal.h"
#import "AZWindowContentView.h"

@implementation AZWindowContentView

/*****************************************************************************\
|* Initialisation: Create with a window
\*****************************************************************************/
- (instancetype) initWithWindow:(AZWindow *)window
	{
	int w,h;
	SDL_GetWindowSizeInPixels(window.window, &w, &h);
	NSRect frame = NSMakeRect(0,0,w,h);

	if (self = [super initWithFrame:frame])
		{
		[self _commonWindowContentViewInit];
		self.window = window;
		}
	return self;
	}


/*****************************************************************************\
|* Convenience initialiser
\*****************************************************************************/
+ (instancetype) withWindow:(AZWindow *)window
	{
	return [[AZWindowContentView alloc] initWithWindow:window];
	}
	
/*****************************************************************************\
|* Configuration via dictionary. This is called by the NIB loader, but is a
|* valid way to create the view
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info;
	{
	if (self = [super initWithDictionary:info])
		{
		[self _commonWindowContentViewInit];
		}
	return self;
	}
	
/*****************************************************************************\
|* Common window-content view initialisation
\*****************************************************************************/
- (void) _commonWindowContentViewInit
	{
	self.backgroundColour 	= AZColour.grey95;
	self.isOpaque			= YES;
	self.autoresizingMask	= AZViewWidthSizable | AZViewHeightSizable;
	_drag  					= nil;
	}

	
/*****************************************************************************\
|* Make sure we have the backing texture if we want to draw
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	if (self.bg < 0)
		[self _installBackingTexture];
	[super drawInRect:dirtyRect withPainter:painter];
	}

/*****************************************************************************\
|* Represent the current dragging session
\*****************************************************************************/
- (void) showDragInProgress
	{
	if (_drag)
		{
		/*********************************************************************\
		|* Draw the image
		\*********************************************************************/
		float dx 			= _drag.at.x - _drag.start.x;
		float dy 			= _drag.at.y - _drag.start.y;

		AZPainter *painter	= [[AZPainter alloc] initWithView:self];

		for (AZDraggingItem *item in _drag.items)
			{
			AZImage *img 	= item.image;
			NSRect where	= item.draggingFrame;
			where.origin.x	+= dx;
			where.origin.y 	+= dy;

			[painter image:img to:where];
			}

		/*********************************************************************\
		|* Check to see if we've just crossed into a new view, and if so
		|* tell the view that dragging has entered the building
		\*********************************************************************/
		AZView *in = [self _findViewAtPoint:_drag.at];
		[self.window _draggedOverView:in];
		}
	}

@end
