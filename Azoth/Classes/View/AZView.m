//
//  AZView.m
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZColour.h"
#import "AZGeometry.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZTransform.h"
#import "AZView.h"
#import "AZView+Internal.h"
#import "AZWindow.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZView()
// Current 'visible rect' or NSZeroRect if not known
@property(assign, nonatomic) NSRect						visRect;

// Post notifications when the frame is changed
@property(assign, nonatomic) BOOL						postFrameNotifications;

// Post notifications when the bounds are changed
@property(assign, nonatomic) BOOL						postBoundsNotifications;

// Whether the transforms are currently valid
@property(assign, nonatomic) BOOL						transformsAreValid;

// Transform from the window co-ords space
@property(strong, nonatomic, nullable)  AZTransform *	transformFromWindow;

// Transform to the window co-ords space
@property(strong, nonatomic, nullable)  AZTransform *	transformToWindow;
@end

@implementation AZView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super init])
		{
		_frame 						= frame;
		_bounds						= frame;
		_bounds.origin 				= (NSPoint){0,0};
		_subviews					= [NSMutableArray new];
		_superview					= nil;
		_bg 						= -1;
		_backgroundColour			= [AZColour blackColour];
		_isOpaque					= NO;
		_autoresizesSubviews		= YES;
		_postFrameNotifications		= YES;
		_postBoundsNotifications	= YES;
		_autoresizingMask		 	= AZViewNotSizable;
		_transformToWindow			= [AZTransform new];
		_transformFromWindow		= [AZTransform new];
		_transformsAreValid			= NO;

		[self setNeedsDisplay:YES];
		}

	return self;
	}

+ (AZView *) viewWithFrame:(NSRect)frame
	{
	return [[AZView alloc] initWithFrame:frame];
	}


/*****************************************************************************\
|* Clean up on deallocation
\*****************************************************************************/
- (void) dealloc
	{
	if (_bg >= 0)
		[AZRenderer.renderer releaseTexture:_bg];
	}

// MARK: Event manipulation

/*****************************************************************************\
|* Determine if we even want mouse events. This allows a subview to limit its
|* control of the event. By default we answer unconditional YES
\*****************************************************************************/
- (BOOL) hitTestAtPoint:(NSPoint)pt
	{ return YES; }

/*****************************************************************************\
|* Convert a point from another window's co-ordinate system to our own. Calling
|* this with nil will convert from window co-ordinates.
\*****************************************************************************/
- (NSPoint) convertPoint:(NSPoint)p fromView:(nullable AZView *)otherView
	{
	AZView *fromView 	= (otherView != nil)
						? otherView
						: [AZWindow contentViewForWindow:self.window];

	AZTransform * toWindow		= fromView.transformToWindow;
	AZTransform * fromWindow	= self.transformFromWindow;

	return [fromWindow applyToPoint:[toWindow applyToPoint:p]];
	}

/*****************************************************************************\
|* Convert a size from our own view's co-ordinate system to another. Calling
|* this with nil will convert to window co-ordinates.
\*****************************************************************************/
- (NSSize) convertSize:(NSSize)size fromView:(nullable AZView *)viewOrNil
	{
	AZView *fromView		= (viewOrNil != nil)
							? viewOrNil
							: [AZWindow contentViewForWindow:self.window];

	AZTransform *toWindow	= fromView.transformToWindow;
	AZTransform *fromWindow	= self.transformFromWindow;

	return [fromWindow applyToSize:[toWindow applyToSize:size]];
	}

/*****************************************************************************\
|* Convert a rect from our own view's co-ordinate system to another. Calling
|* this with nil will convert to window co-ordinates.
\*****************************************************************************/
- (NSRect) convertRect:(NSRect)r fromView:(nullable AZView *)viewOrNil
	{
	AZView *fromView		= (viewOrNil != nil)
							? viewOrNil
							: [AZWindow contentViewForWindow:self.window];
	AZTransform *toWindow	= fromView.transformToWindow;
	AZTransform *fromWindow	= self.transformFromWindow;

	NSPoint p1				= r.origin;
	NSPoint p2				= NSMakePoint(NSMaxX(r), NSMaxY(r));

	p1 = [fromWindow applyToPoint:[toWindow applyToPoint:p1]];
	p2 = [fromWindow applyToPoint:[toWindow applyToPoint:p2]];

	if (p2.y < p1.y)
		{
		float temp=p2.y;
		p2.y = p1.y;
		p1.y = temp;
		}

	return NSMakeRect(p1.x,p1.y,p2.x-p1.x,p2.y-p1.y);
	}

/*****************************************************************************\
|* Convert a point from our own view's co-ordinate system to another. Calling
|* this with nil will convert to window co-ordinates.
\*****************************************************************************/
- (NSPoint) convertPoint:(NSPoint)p toView:(nullable AZView *)otherView
	{
	AZView *toView 	= (otherView != nil)
					? otherView
					: [AZWindow contentViewForWindow:self.window];

	AZTransform * toWindow		= self.transformToWindow;
	AZTransform * fromWindow	= toView.transformFromWindow;

	return [fromWindow applyToPoint:[toWindow applyToPoint:p]];
	}

/*****************************************************************************\
|* Convert a size from our own view's co-ordinate system to another. Calling
|* this with nil will convert to window co-ordinates.
\*****************************************************************************/
- (NSSize) convertSize:(NSSize)size toView:(nullable AZView *)viewOrNil
	{
	AZView *toView 	= (viewOrNil != nil)
					? viewOrNil
					: [AZWindow contentViewForWindow:self.window];

	AZTransform * toWindow		= self.transformToWindow;
	AZTransform * fromWindow	= toView.transformFromWindow;

	return [fromWindow applyToSize:[toWindow applyToSize:size]];
	}


/*****************************************************************************\
|* Convenience method to do the same for a rect.
\*****************************************************************************/
- (NSRect) convertRect:(NSRect)r toView:(nullable AZView *)viewOrNil
	{
	AZView *toView 	= (viewOrNil != nil)
					? viewOrNil
					: [AZWindow contentViewForWindow:self.window];

	AZTransform * toWindow		= self.transformToWindow;
	AZTransform * fromWindow	= toView.transformFromWindow;

	NSPoint p1				= r.origin;
	NSPoint p2				= NSMakePoint(NSMaxX(r), NSMaxY(r));

	p1 = [fromWindow applyToPoint:[toWindow applyToPoint:p1]];
	p2 = [fromWindow applyToPoint:[toWindow applyToPoint:p2]];

	if (p2.y < p1.y)
		{
		float temp=p2.y;
		p2.y = p1.y;
		p1.y = temp;
		}

	return NSMakeRect(p1.x,p1.y,p2.x-p1.x,p2.y-p1.y);
	}



// MARK: View processing

/*****************************************************************************\
|* Return the transforms to/from the window co-ords
\*****************************************************************************/
- (AZTransform *) transformFromWindow
	{
	_buildTransformsIfNeeded(self);
	return _transformFromWindow;
	}

- (AZTransform *) transformToWindow
	{
	_buildTransformsIfNeeded(self);
	return _transformToWindow;
	}

/*****************************************************************************\
|* Set the window for a view, recursively
\*****************************************************************************/
- (void) setWindow:(AZWindow *)window
	{
	_window = window;
	for (AZView *view in self.subviews)
		[view setWindow:window];
	}

/*****************************************************************************\
|* Add a subview to the list of views
\*****************************************************************************/
- (BOOL) addSubview:(AZView *)view
	{
	[_subviews addObject:view];
	view.superview 	= self;
	view.window		= _window;
	[view _installBackingTexture];
	[view _invalidateTransforms];
	//[self setNeedsDisplayInRect:[view frame]];
	return YES;
	}

/*****************************************************************************\
|* Add a subview to the list of views, in front of another view
\*****************************************************************************/
- (BOOL) addSubview:(AZView *)view before:(AZView *)other
	{
	BOOL ok 		= NO;
	NSInteger idx 	= 0;

	if (other == nil)
		{
		[_subviews insertObject:view atIndex:0];
		ok = YES;
		}
	else
		for (AZView *view in _subviews)
			if (view == other)
				{
				[_subviews insertObject:view atIndex:idx];
				ok = YES;
				}

	if (!ok)
		[_subviews addObject:view];

	view.superview 	= self;
	view.window		= _window;
	[view _installBackingTexture];
	return ok;
	}

/*****************************************************************************\
|* Add a subview to the list of views, behind another view
\*****************************************************************************/
- (BOOL) addSubview:(AZView *)view after:(AZView *)other
	{
	BOOL ok 		= NO;
	NSInteger idx 	= 0;

	for (AZView *view in _subviews)
		if (view == other)
			{
			if (idx < _subviews.count-1)
				[_subviews insertObject:view atIndex:idx+1];
			else
				[_subviews addObject:view];
			ok = YES;
			}

	if (!ok)
		[_subviews addObject:view];

	view.superview 	= self;
	view.window		= _window;
	[view _installBackingTexture];
	return ok;
	}

/*****************************************************************************\
|* Tell the view it needs to redraw itself (or not)
\*****************************************************************************/
- (void) setNeedsDisplay:(BOOL)yn
	{
	if (yn)
		_dirty = [self bounds];
	else
		_dirty = NSZeroRect;
	}

/*****************************************************************************\
|* Tell the view it needs to redraw a section of itself
\*****************************************************************************/
- (void) setNeedsDisplayInRect:(NSRect)rect
	{
	_dirty = NSUnionRect(_dirty, rect);

	for (AZView *subview in _subviews)
		{
		NSRect intersect = NSIntersectionRect(rect, subview.frame);
		intersect.origin = [subview convertPoint:intersect.origin fromView:self];
		[subview setNeedsDisplayInRect:intersect];
		}
	}


/*****************************************************************************\
|* Remove a view from its superview
\*****************************************************************************/
- (void) removeFromSuperview
	{
	AZView *superview = self.superview;
	[superview _removeSubview:self];
	}

/*****************************************************************************\
|* Set the frame origin and size
\*****************************************************************************/
- (void) setFrameOrigin:(NSPoint)p
	{
	_frame.origin = p;
	[self setFrame:_frame];
	}

- (void) setFrameSize:(NSSize)s;
	{
	_frame.size = s;
	[self setFrame:_frame];
	}

/*****************************************************************************\
|* Set the bounds origin and size
\*****************************************************************************/
-(void)setBoundsSize:(NSSize)size
	{
	NSRect bounds 	= self.bounds;
	bounds.size		= size;
	self.bounds 	= bounds;
	}

-(void)setBoundsOrigin:(NSPoint)origin
	{
	NSRect bounds	= self.bounds;
	bounds.origin	= origin;
	self.bounds 	= bounds;
	}

/*****************************************************************************\
|* The visible part of the view
\*****************************************************************************/
- (NSRect) visibleRect
	{
	if (NSEqualRects(_visRect, NSZeroRect))
		_visRect = [self _calculateVisibleRect];

	return _visRect;
	}



// MARK: Redraw


/*****************************************************************************\
|* What to override in subclasses to get a view to draw. This renders into the
|* local texture, so is at (0,0) wrt to that texture. Pixel positioning ought
|* to be perfectly aligned. By default the view is cleared to its background
|* colour
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[painter rectangleWithRect:dirtyRect
						filled:YES
					    colour:self.backgroundColour];
	}


/*****************************************************************************\
|* Called by a top-level contentView, check if any of the subviews needs
|* to be redrawn to their backing textures. Note that the contentView
|* itself will always be fully drawn first, so no need to check that one
\*****************************************************************************/
- (void) redrawSubViewsIfNecessary
	{
	for (AZView *view in self.subviews)
		[view _redrawViewAndSubviews];
	}


// MARK: Resize

/*****************************************************************************\
|* Set the frame of this view
\*****************************************************************************/
- (void) setBounds:(NSRect)bounds
	{
	if (!NSEqualRects(bounds, self.bounds))
		{
		_bounds = bounds;
		self.visRect = NSZeroRect;
		[self _invalidateTransforms];

		// this also invalidates tracking areas
		// Yep, still not implemented
		// [_window invalidateCursorRectsForView:self];
		
		if (_postBoundsNotifications)
			{
			NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
			[nc postNotificationName:AZViewBoundsDidChangeNotification
							  object:self];
			}
		}
	}

/*****************************************************************************\
|* Set the frame of this view
\*****************************************************************************/
- (void) setFrame:(NSRect)frame
	{
	// We don't post anything if the frame is the same
	if(NSEqualRects(self.frame,frame))
		return;

	NSSize oldSize = self.bounds.size;

	_bounds.size = frame.size;
	_frame=frame;

	// Not implemented yet, but note for later
	//[_window invalidateCursorRectsForView:self]; // this also invalidates tracking areas

   if (_autoresizesSubviews)
		[self resizeSubviewsWithOldSize:oldSize];

	// Invalidate the visible rect
	_visRect = NSZeroRect;
	[self _invalidateTransforms];

	if (self.postFrameNotifications)
		{
		NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
		[nc postNotificationName:AZViewFrameDidChangeNotification object:self];
		}
	}

- (void) resizeSubviewsWithOldSize:(NSSize)size
	{
	for (AZView *subview in self.subviews)
		if ([subview resizeWithOldSuperviewSize:size])
			[subview resizeSubviewsWithOldSize:subview.frame.size];
	}

- (BOOL) resizeWithOldSuperviewSize:(NSSize)size
	{
	if (self.autoresizingMask == AZViewNotSizable)
		return NO;

	int dx = self.superview.frame.size.width  - size.width;
	int dy = self.superview.frame.size.height - size.height;

	BOOL left 	= (self.autoresizingMask & AZViewMinXMargin);
	BOOL center	= (self.autoresizingMask & AZViewWidthSizable);
	BOOL right	= (self.autoresizingMask & AZViewMaxXMargin);

	NSRect frame = self.frame;

	// Distribute the gains fairly, so see how many LCR areas can change
	int count 	= (left ? 1 : 0) + (center ? 1 : 0)  + (right ? 1 : 0);
	int done  	= 0;
	if (count > 0)
		{
		int ddx = dx/count;
		if (left)
			{
			frame.origin.x += ddx;
			done ++;
			dx -= ddx;
			}
		int delta = (done == count) ? dx : ddx;

		if (center)
			{
			frame.size.width += delta;
			done ++;
			dx -= delta;
			}
		delta = (done == count) ? dx : ddx;

		if (right)
			dx -= delta;

		if (dx != 0)
			SDL_Log("Error in width resizing calculation (dx=%d,%s%s%s)",
					dx, (left ? "L" : "-"), (center ? "C" : "-"),
					(right ? "R" : "-"));
		}

	// Same story for the TCB areas
	BOOL top 	= (self.autoresizingMask & AZViewMaxYMargin);
	center		= (self.autoresizingMask & AZViewHeightSizable);
	BOOL bottom	= (self.autoresizingMask & AZViewMinYMargin);

	count 		= (top ? 1 : 0) + (center ? 1 : 0)  + (bottom ? 1 : 0);
	done  		= 0;

	if (count > 0)
		{
		int ddy = dy/count;
		if (bottom)
			{
			frame.origin.y += ddy;
			done ++;
			dy -= ddy;
			}
		int delta = (done == count-1) ? dy : ddy;

		if (center)
			{
			frame.size.height += delta;
			done ++;
			dy -= delta;
			}
		delta = (done == count-1) ? dy : ddy;

		if (top)
			dy -= delta;

		if (dy != 0)
			SDL_Log("Error in height resizing calculation (dy=%d,%s%s%s)",
					dy, (top ? "T" : "-"), (center ? "C" : "-"),
					(bottom ? "B" : "-"));
		}

	// Finally, set the frame
	if (!NSEqualRects(frame, _frame))
		{
		_frame 		 = frame;
		_bounds.size = _frame.size;
		[self _installBackingTexture];
		}
		
	[self setNeedsDisplay:YES];
	return YES;
	}



// MARK: Private methods

/*****************************************************************************\
|* Calculate the visible rect
\*****************************************************************************/
- (NSRect) _calculateVisibleRect
	{
	// Don't support this (yet ?)
	//if ([self isHiddenOrHasHiddenAncestor])
	//	return NSZeroRect;

	if (self.superview == nil)
		return self.bounds;

    NSRect result	= self.superview.visibleRect;
    result 			= [self convertRect:result fromView:self.superview];
    result 			= NSIntersectionRect(result, self.bounds);

    return result;
	}

static inline void _buildTransformsIfNeeded(AZView *self)
	{
	if (!self->_transformsAreValid)
		{
		self->_transformToWindow	= [self _createTransformToWindow];
		self->_transformFromWindow	= [self->_transformToWindow invert];
		self->_transformsAreValid	= YES;

		self->_visibleRect			= [self _calculateVisibleRect];
		}
	}

/*****************************************************************************\
|* Get a transform for the window by concat'ing from the superview if we can
\*****************************************************************************/
- (AZTransform *) _createTransformToWindow
	{
	AZTransform *result = [AZTransform new];
	AZView *sv			= self.superview;
	BOOL doFrame		= YES;

	if (sv != nil)
		result = [sv transformToWindow];

	result = [self _concatViewTransform:result
								   view:self
							    doFrame:doFrame];

	return result;
	}

/*****************************************************************************\
|* Apply the transformation for the view
\*****************************************************************************/
- (AZTransform *) _concatViewTransform:(AZTransform *)result
								  view:(AZView *)view
							   doFrame:(BOOL)doFrame
	{
	NSRect bounds = view.bounds;
	NSRect frame  = view.frame;

	if (doFrame)
		result = [result translateX:frame.origin.x y:frame.origin.y];

	// Apply bounds scaling to fit in the frame if needed
	float sx = NSWidth(frame)/NSWidth(bounds);
	float sy = NSHeight(frame)/NSHeight(bounds);
	if ((sx != 1.f) || (sy != 1.f))
		{
		AZTransform *scale = [AZTransform scaleX:sx y:sy];
		result = [result concat:scale];
		}

	return [result translateX:-bounds.origin.x y:-bounds.origin.y];
	}

/*****************************************************************************\
|* Invalidate the view transforms, forcing them to be recalculated when needed
\*****************************************************************************/
- (void) _invalidateTransforms
	{
	_transformsAreValid = NO;
	for (AZView *view in _subviews)
		[view _invalidateTransforms];
	}


@end
