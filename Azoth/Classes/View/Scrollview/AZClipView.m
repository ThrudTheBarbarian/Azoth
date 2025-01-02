//
//  AZClipView.m
//  Azoth
//
//  Created by Simon Gornall on 12/22/24.
//
#import <SDL3/SDL.h>


#import "AZApplication.h"
#import "AZClipView.h"
#import "AZColour.h"
#import "AZGeometry.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZScrollView.h"
#import "AZView+Internal.h"
#import "AZWindow.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZClipView()
@property(assign, nonatomic) NSRect									docRect;
@end

@implementation AZClipView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		self.backgroundColour 	= [AZColour controlColour];
		self.drawsBackground 	= YES;
		}
	return self;
	}

/*****************************************************************************\
|* Clean up on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	[NSNotificationCenter.defaultCenter removeObserver:self];
	}


/*****************************************************************************\
|* Set whether we draw the background, and refresh the view
\*****************************************************************************/
- (void) setDrawsBackground:(BOOL)value
	{
	_drawsBackground = value;
	[self setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Set the document view for this clipview
\*****************************************************************************/
- (void) setDocumentView:(AZView *)view
	{
	if(self.documentView != nil)
		{
		NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;

		[nc removeObserver:self
					  name:AZViewFrameDidChangeNotification
					object:self.documentView];

		[nc removeObserver:self
					  name:AZViewBoundsDidChangeNotification
					object:self.documentView];

		[self.documentView removeFromSuperview];
		}

	_documentView = view;
	[self addSubview:view];

	if(self.documentView != nil)
		{
		NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;

		[nc addObserver:self
			   selector:@selector(_viewFrameChanged:)
				   name:AZViewFrameDidChangeNotification
				 object:self.documentView];

		[nc addObserver:self
			   selector:@selector(_viewBoundsChanged:)
				   name:AZViewBoundsDidChangeNotification
				 object:self.documentView];
		}
	}

/*****************************************************************************\
|* Return the visible rect, in the document view co-ords, of the document view
\*****************************************************************************/
-(NSRect)documentVisibleRect
	{
	NSRect  r 	= self.bounds;
	r.origin	= [_documentView convertPoint:r.origin fromView:self];
	return r;
	}

/*****************************************************************************\
|* Make sure the scroll point is within bounds
\*****************************************************************************/
-(NSPoint)constrainScrollPoint:(NSPoint)point
	{
	NSRect bounds	= self.bounds;
	NSRect docFrame = self.documentView.frame;

	if (point.y < docFrame.origin.y)
		point.y = docFrame.origin.y;

	if(point.x < docFrame.origin.x)
		point.x = docFrame.origin.x;

	if(docFrame.size.height < bounds.size.height)
		point.y = docFrame.origin.y;
	else if (point.y + bounds.size.height > NSMaxY(docFrame))
		point.y = NSMaxY(docFrame) - bounds.size.height;

	if(docFrame.size.width < bounds.size.width)
		point.x=docFrame.origin.x;
	else if(point.x + bounds.size.width > NSMaxX(docFrame))
		point.x = NSMaxX(docFrame) - bounds.size.width;

	return point;
	}


/*****************************************************************************\
|* Return where we currently are scrolled to
\*****************************************************************************/
-(NSPoint)scrollPoint
	{
	return [self bounds].origin;
	}

// MARK: Private methods

/*****************************************************************************\
|* The view bounds changed
\*****************************************************************************/
- (void) _viewBoundsChanged:(NSNotification *)n
	{
	[self scrollToPoint:self.scrollPoint];

	// Be sure our scrollbars are in sync with the new docview bounds
	if ([self.superview isKindOfClass:AZScrollView.class])
		{
        AZScrollView *sv = (AZScrollView *)self.superview;
		[sv tile]; 	// tiling might be needed if autohide-scrollers is enabled
		[sv reflectScrolledClipView:self];
		}
	}


/*****************************************************************************\
|* The view frame changed
\*****************************************************************************/
-(void)_viewFrameChanged:(NSNotification *)n
	{
	[self scrollToPoint:self.scrollPoint];

	// Be sure our scrollbars are in sync with the new docview bounds
	if ([self.superview isKindOfClass:AZScrollView.class])
		{
        AZScrollView *sv = (AZScrollView *)self.superview;
		[sv tile]; 	// tiling might be needed if autohide-scrollers is enabled
		[sv reflectScrolledClipView:self];
		}
    
    // if the docview doesn't completely fill the clip view, we need a redraw
	// because some of our content has been revealed
    NSRect visibleRect 	= self.visibleRect;
	NSRect frame		= [self.documentView frame];

    if (NSContainsRect(frame, visibleRect) == NO)
		[self setNeedsDisplay:YES];
	}	

/*****************************************************************************\
|* Are we opaque
\*****************************************************************************/
- (BOOL) isOpaque
	{
    return self.drawsBackground && (self.backgroundColour.a >= 1.f);
	}

/*****************************************************************************\
|* Do a draw if we need to
\*****************************************************************************/
- (void) drawInRect:(NSRect)rect withPainter:(AZPainter *)painter
	{
	if ([self.documentView isOpaque])
		{
		NSRect frame = self.documentView.frame;

		// if the docview completely fills the drawing rect,
		// don't draw the background
		if (NSContainsRect(frame, rect))
			return;
		}

	if (self.drawsBackground)
		[painter rectangleWithRect:rect filled:YES colour:self.backgroundColour];
	}

/*****************************************************************************\
|* Autoscroll on a drag within the scrollview. Returns whether any scrolling
|* actually happened
\*****************************************************************************/
- (BOOL) autoscroll:(SDL_MouseMotionEvent *)e
	{
	int dx				= 0;
	int dy				= 0;
	NSRect bounds		= self.bounds;
	NSPoint p			= (NSPoint){e->x, e->y};
	p					= [self convertPoint:p fromView:nil];

	AZView *sv			= self.superview;

	if (NSPointInRect(p, bounds))
		return NO;

	BOOL superIsSV		= [sv isKindOfClass:AZScrollView.class];
	BOOL hasVScroll		= [(AZScrollView *)sv hasVerticalScroller];
	BOOL hasHScroll 	= [(AZScrollView *)sv hasHorizontalScroller];

	if (!superIsSV || hasVScroll)
		{
		if (p.y < NSMinY(bounds))
			dy = NSMinY(bounds)-p.y;
		else if (p.y > NSMaxY(bounds))
			dy = NSMaxY(bounds)-p.y;

		if (dy < -bounds.size.height)
			dy = -bounds.size.height;

		if (dy > bounds.size.height)
			dy = bounds.size.height;
		}

	if (!superIsSV || hasHScroll)
		{
		if(p.x < NSMinX(bounds))
			dx = NSMinX(bounds)-p.x;
		else if(p.x > NSMaxX(bounds))
			dx = NSMaxX(bounds)-p.x;

		if (dx < -bounds.size.width)
			dx = -bounds.size.width;

		if (dx > bounds.size.width)
			dx = bounds.size.width;
		}

	// "Returns YES if any scrolling is performed; otherwise returns NO."
	//  - AppKit documentation
	if (dx != 0.f || dy != 0.f)
		{
		bounds.origin.y -= dy;
		bounds.origin.x -= dx;
		[self scrollToPoint:bounds.origin];

		// Return YES only if some scrolling really happened
		return NSEqualPoints(bounds.origin, self.bounds.origin) == NO;
		}

	return NO;
	}

/*****************************************************************************\
|* Scroll the document view to a given point
\*****************************************************************************/
-(void)scrollToPoint:(NSPoint)point
	{
	if (!NSEqualPoints(point, self.bounds.origin))
		{
		[self setBoundsOrigin:point];
		[self setNeedsDisplay:YES];

		/*********************************************************************\
		|* If the document-view understands that it's being scrolled, give it
		|* a chance to optimise its display, so it doesnt have to maintain an
		|* enormous backing texture
		\*********************************************************************/
		SEL scrollToPoint = SELECTOR(@"scrollToPoint:");
		if ([self.documentView respondsToSelector:scrollToPoint])
			{
			IMP imp = [self.documentView methodForSelector:scrollToPoint];
			void (*func)(id, SEL, NSPoint) = (void *)imp;
			func(self.documentView, scrollToPoint, point);
			}

		/*********************************************************************\
		|* If we're in a ScrollView (which seems likely...) then reflect the
		|* current state of the scroll position into the scrollbars managed by
		|* the enclosing scrollview
		\*********************************************************************/
		if ([self.superview isKindOfClass:AZScrollView.class])
			[(AZScrollView *)self.superview reflectScrolledClipView:self];
		}
	}

@end
