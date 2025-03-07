//
//  AZView.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/11/24.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZClipView.h"
#import "AZColour.h"
#import "AZDraggingSession.h"
#import "AZGeometry.h"
#import "AZImage.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZScrollView.h"
#import "AZTransform.h"
#import "AZView.h"
#import "AZView+Internal.h"
#import "AZWindow.h"
#import "AZWindow+Internal.h"
#import "AZZib.h"
#import "NSDictionary+ZIB.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZView()

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
		[self _commonViewInitWithFrame:frame];
		}

	return self;
	}

/*****************************************************************************\
|* Configuration via dictionary. This is called by the NIB loader, but is a
|* valid way to create the view
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info;
	{
	if (self = [super init])
		{
		NSRect frame = [info AZRectWithKey:kZibFrame];
		[self _commonViewInitWithFrame:frame];

		NSDictionary *resize 	= info[kZibResizeMask];
		_autoresizingMask 		= resize.AZResizeMask;

		if (info[kZibHidden])
			_hidden = YES;
		}
	return self;
	}

+ (AZView *) viewWithFrame:(NSRect)frame
	{
	return [[AZView alloc] initWithFrame:frame];
	}

/*****************************************************************************\
|* Common initialisation
\*****************************************************************************/
- (void) _commonViewInitWithFrame:(NSRect)frame
	{
	self.frame 						= frame;
	frame.origin					= (NSPoint){0,0};
	self.bounds						= frame;
	self.subviews					= [NSMutableArray new];
	self.superview					= nil;
	self.bg 						= -1;
	self.backgroundColour			= AZColour.grey95;
	self.isOpaque					= NO;
	self.autoresizesSubviews		= YES;
	self.postsFrameNotifications	= YES;
	self.postsBoundsNotifications	= YES;
	self.autoresizingMask		 	= AZViewNotSizable;
	self.transformToWindow			= [AZTransform new];
	self.transformFromWindow		= [AZTransform new];
	self.transformsAreValid			= NO;
	self.textureMutex				= SDL_CreateMutex();
	self.hidden						= NO;
	self.dragTypes					= NSSet.new;

	self.mouseCursor		= SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_DEFAULT);
	[self setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Clean up on deallocation
\*****************************************************************************/
- (void) dealloc
	{
	[self purge];
	}

/*****************************************************************************\
|* Purge the texture. Shouldn't be needed but sometimes the dealloc() doesn't
|* seem to be called even if retainCount == 0
\*****************************************************************************/
- (void) purge
	{
	if (_bg >= 0)
		{
		[AZRenderer.renderer releaseTexture:_bg];
		_bg = -1;
		}
	}

// MARK: Event manipulation


/*****************************************************************************\
|* The mouse has entered the view, default behaviour is to change the pointer
\*****************************************************************************/
- (void) mouseEntered:(AZEvent *)event
	{
	if (!self.hidden)
		SDL_SetCursor(self.mouseCursor);
	}

/*****************************************************************************\
|* The mouse has exited the view
\*****************************************************************************/
- (void) mouseExited:(AZEvent *)event
	{}

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
	AZView * from = otherView;
	if (from == nil)
		from = (AZView *) self.window.contentView;

	AZTransform * toWindow	= from.transformToWindow;
	AZTransform * fromWindow	= self.transformFromWindow;

	return [fromWindow applyToPoint:[toWindow applyToPoint:p]];
	}

/*****************************************************************************\
|* Convert a size from our own view's co-ordinate system to another. Calling
|* this with nil will convert to window co-ordinates.
\*****************************************************************************/
- (NSSize) convertSize:(NSSize)size fromView:(nullable AZView *)otherView
	{
	AZView * from = otherView;
	if (from == nil)
		from = (AZView *) self.window.contentView;

	AZTransform * toWindow	= from.transformToWindow;
	AZTransform *fromWindow	= self.transformFromWindow;

	return [fromWindow applyToSize:[toWindow applyToSize:size]];
	}

/*****************************************************************************\
|* Convert a rect from our own view's co-ordinate system to another. Calling
|* this with nil will convert to window co-ordinates.
\*****************************************************************************/
- (NSRect) convertRect:(NSRect)r fromView:(nullable AZView *)otherView
	{
	AZView * from = otherView;
	if (from == nil)
		from = (AZView *) self.window.contentView;

	AZTransform *toWindow	= from.transformToWindow;
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
	AZView * toView = otherView;
	if (toView == nil)
		toView = (AZView *) self.window.contentView;

	AZTransform * toWindow	= self.transformToWindow;
	AZTransform * fromWindow	= toView.transformFromWindow;

	return [fromWindow applyToPoint:[toWindow applyToPoint:p]];
	}

/*****************************************************************************\
|* Convert a size from our own view's co-ordinate system to another. Calling
|* this with nil will convert to window co-ordinates.
\*****************************************************************************/
- (NSSize) convertSize:(NSSize)size toView:(nullable AZView *)otherView
	{
	AZView * toView = otherView;
	if (toView == nil)
		toView = (AZView *) self.window.contentView;

	AZTransform * toWindow		= self.transformToWindow;
	AZTransform * fromWindow	= toView.transformFromWindow;

	return [fromWindow applyToSize:[toWindow applyToSize:size]];
	}


/*****************************************************************************\
|* Convenience method to do the same for a rect.
\*****************************************************************************/
- (NSRect) convertRect:(NSRect)r toView:(nullable AZView *)otherView
	{
	AZView * toView = otherView;
	if (toView == nil)
		toView = (AZView *) self.window.contentView;

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
|* Determine if this, or any view further up the view hierarchy, is hidden
\*****************************************************************************/
-(BOOL)isHiddenOrHasHiddenAncestor
	{
	return _hidden || [self.superview isHiddenOrHasHiddenAncestor];
	}

- (void) setHidden:(BOOL)hidden
	{
	_hidden = hidden;
	if (!hidden)
		[self _invalidateTransforms];
	}

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

- (void) rebuildTransforms
	{
	[self _invalidateTransforms];
	_buildTransformsIfNeeded(self);
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

	[view _invalidateTransforms];
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
	//[view _installBackingTexture];
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
	//[view _installBackingTexture];
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
	self.superview = nil;
	}

/*****************************************************************************\
|* Set the frame origin and size
\*****************************************************************************/
- (void) setFrameOrigin:(NSPoint)p
	{
	NSRect frame = self.frame;
	frame.origin = p;
	[self setFrame:frame];
	}

- (void) setFrameSize:(NSSize)s;
	{
	NSRect frame = self.frame;
	frame.size = s;
	[self setFrame:frame];
	}

/*****************************************************************************\
|* Set the bounds origin and size
\*****************************************************************************/
-(void)setBoundsSize:(NSSize)size
	{
	NSRect bounds 	= self.bounds;
	bounds.size		= size;
	[self setBounds:bounds];
	}

-(void)setBoundsOrigin:(NSPoint)origin
	{
	NSRect bounds	= self.bounds;
	bounds.origin	= origin;
	[self setBounds:bounds];
	}

/*****************************************************************************\
|* The visible part of the view
\*****************************************************************************/
- (NSRect) visibleRect
	{
	_buildTransformsIfNeeded(self);
	return _visibleRect;
	}

/*****************************************************************************\
|* Return the size of the texture to create. This is used when the view could
|* possibly grow outside of the size-limit of a GPU texture - eg when inside
|* an enormous scrollview. In that instance, it ought to implement the clipView
|* delegate -scrollToPoint:(NSPoint) to get where it is "scrolled" to, and
|* handle drawing specially with a window-sized texture rather than a backing-
|* sized texture. By default this method just returns the view's frame.size
\*****************************************************************************/
- (NSSize) textureSize
	{
	return _frame.size;
	}

/*****************************************************************************\
|* The companion method is -(BOOL)directRendering which turns off the view
|* translation and will always render from 0,0->W,H (where W,H are taken from
|* -(NSSize)textureSize. The default return from this method is NO
\*****************************************************************************/
- (BOOL) directRendering
	{
	return NO;
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
	if (self.isOpaque)
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
		[self _invalidateTransforms];

		// this also invalidates tracking areas
		// Yep, still not implemented
		// [_window invalidateCursorRectsForView:self];
		
		if (_postsBoundsNotifications)
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

	NSSize old = self.bounds.size;

	_bounds.size = frame.size;
	_frame=frame;

	// Not implemented yet, but note for later
	// this also invalidates tracking areas
	//[_window invalidateCursorRectsForView:self];

   if (_autoresizesSubviews)
		[self resizeSubviewsWithOldSize:old];

	// Invalidate the visible rect
	[self _invalidateTransforms];
	[self setNeedsDisplay:YES];

	// If the current backing texture is smaller than the new size, then
	// install a new backing texture to match
	if ((old.width < frame.size.width) || (old.height < frame.size.height))
		if (self.superview != nil)
			[self _installBackingTexture];

	if (self.postsFrameNotifications)
		{
		NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
		[nc postNotificationName:AZViewFrameDidChangeNotification object:self];
		}
	}

- (void) resizeSubviewsWithOldSize:(NSSize)size
	{
	for (AZView *subview in self.subviews)
		[subview resizeWithOldSuperviewSize:size];
	}

- (BOOL) resizeWithOldSuperviewSize:(NSSize)oldSize
	{
	NSRect superFrame 	= _superview.frame;
	NSRect frame		= self.frame;
	BOOL originChanged	= NO;
	BOOL sizeChanged	= NO;

	if(_autoresizingMask & AZViewMinXMargin)
		{
		if (_autoresizingMask & AZViewWidthSizable)
			{
			if (_autoresizingMask & AZViewMaxXMargin)
				{
				frame.origin.x   += ((superFrame.size.width - oldSize.width)/3);
				frame.size.width += ((superFrame.size.width - oldSize.width)/3);
				}
			else
				{
				frame.origin.x 	 += ((superFrame.size.width - oldSize.width)/2);
				frame.size.width += ((superFrame.size.width - oldSize.width)/2);
				}
			originChanged	= YES;
			sizeChanged		= YES;
			}
		else if(_autoresizingMask & AZViewMaxXMargin)
			{
			frame.origin.x += ((superFrame.size.width - oldSize.width)/2);
			originChanged 	= YES;
			}
		else
			{
			frame.origin.x += superFrame.size.width - oldSize.width;
			originChanged	= YES;
			}
		}
   else if (_autoresizingMask & AZViewWidthSizable)
		{
		if (_autoresizingMask & AZViewMaxXMargin)
			frame.size.width += ((superFrame.size.width - oldSize.width)/2);
		else
			frame.size.width += superFrame.size.width - oldSize.width;
		sizeChanged=YES;
		}
	else if (_autoresizingMask & AZViewMaxXMargin)
		{
		// don't move or resize
		}


	if (_autoresizingMask & AZViewMinYMargin)
		{
		if (_autoresizingMask & AZViewHeightSizable)
			{
			if (_autoresizingMask & AZViewMaxYMargin)
				{
				frame.origin.y    += ((superFrame.size.height - oldSize.height)/3);
				frame.size.height += ((superFrame.size.height - oldSize.height)/3);
				}
			else
				{
				frame.origin.y    += ((superFrame.size.height - oldSize.height)/2);
				frame.size.height += ((superFrame.size.height - oldSize.height)/2);
				}
			originChanged=YES;
			sizeChanged=YES;
			}
		else if (_autoresizingMask& AZViewMaxYMargin)
			{
			frame.origin.y += ((superFrame.size.height - oldSize.height)/2);
			originChanged=YES;
			}
		else
			{
			frame.origin.y+=superFrame.size.height - oldSize.height;
			originChanged=YES;
			}
		}
	else if (_autoresizingMask & AZViewHeightSizable)
		{
		if (_autoresizingMask & AZViewMaxYMargin)
			frame.size.height += ((superFrame.size.height - oldSize.height)/2);
		else
			frame.size.height += superFrame.size.height - oldSize.height;
		sizeChanged=YES;
		}

	if(originChanged || sizeChanged)
		{
		NSRect r = self.frame;
		[self setFrame:frame];
		[self didResizeFrom:r];
		return YES;
		}
	return NO;
	}

//- (BOOL) resizeWithOldSuperviewSize:(NSSize)size
//	{
//	if (self.autoresizingMask == AZViewNotSizable)
//		return NO;
//
//if (size.width == 968)
//	NSLog(@"size");
//
//	int dx = self.superview.frame.size.width  - size.width;
//	int dy = self.superview.frame.size.height - size.height;
//
//	BOOL left 	= (self.autoresizingMask & AZViewMinXMargin);
//	BOOL hcenter	= (self.autoresizingMask & AZViewWidthSizable);
//	BOOL right	= (self.autoresizingMask & AZViewMaxXMargin);
//
//	NSRect frame = self.frame;
//
//	// Distribute the gains fairly, so see how many LCR areas can change
//	int count 	= (left ? 1 : 0) + (hcenter ? 1 : 0)  + (right ? 1 : 0);
//	int done  	= 0;
//	if (count > 0)
//		{
//		int ddx = dx/count;
//		if (left)
//			{
//			frame.origin.x += ddx;
//			done ++;
//			dx -= ddx;
//			}
//		int delta = (done == count) ? dx : ddx;
//
//		if (hcenter)
//			{
//			frame.size.width += delta;
//			done ++;
//			dx -= delta;
//			}
//		delta = (done == count) ? dx : ddx;
//
//		if (right)
//			dx -= delta;
//
//		if (dx != 0)
//			SDL_Log("Error in width resizing calculation (dx=%d,%s%s%s)",
//					dx, (left ? "L" : "-"), (hcenter ? "C" : "-"),
//					(right ? "R" : "-"));
//		}
//
//	// Same story for the TCB areas
//	BOOL top 	= (self.autoresizingMask & AZViewMaxYMargin);
//	BOOL vcenter= (self.autoresizingMask & AZViewHeightSizable);
//	BOOL bottom	= (self.autoresizingMask & AZViewMinYMargin);
//
//	count 		= (top ? 1 : 0) + (vcenter ? 1 : 0)  + (bottom ? 1 : 0);
//	done  		= 0;
//
//	if (count > 0)
//		{
//		int ddy = dy/count;
//		if (bottom)
//			{
//			frame.origin.y += ddy;
//			done ++;
//			dy -= ddy;
//			}
//		int delta = (done == count-1) ? dy : ddy;
//
//		if (vcenter)
//			{
//			frame.size.height += delta;
//			done ++;
//			dy -= delta;
//			}
//		delta = (done == count-1) ? dy : ddy;
//
//		if (top)
//			dy -= delta;
//
//		if (dy != 0)
//			SDL_Log("Error in height resizing calculation (dy=%d,%s%s%s)",
//					dy, (top ? "T" : "-"), (vcenter ? "C" : "-"),
//					(bottom ? "B" : "-"));
//		}
//
//	// Finally, set the frame
//	if (!NSEqualRects(frame, _frame))
//		{
//		NSRect oldFrame	= _frame;
//		self.frame = frame;
//		[self _installBackingTexture];
//		[self didResizeFrom:oldFrame];
//		}
//
//	[self setNeedsDisplay:YES];
//	return YES;
//	}


/*****************************************************************************\
|* Called on a view when it resizes
\*****************************************************************************/
- (void) didResizeFrom:(NSRect)oldFrame
	{}

// MARK: Scrolling

/*****************************************************************************\
|* Scroll a view within an enclosing scrollview until the rect is visible
\*****************************************************************************/
- (BOOL) scrollRectToVisible:(NSRect)rect
	{
    AZClipView *clipView = [self enclosingClipView];
    AZView *documentView = [clipView documentView];

    // Fetch the document view visible rect in document view space
    NSRect vRect = [clipView documentVisibleRect];

    // Convert what we want in the document view space
    rect = [documentView convertRect:rect fromView:self];
    
    // Do the minimal amount of scrolling to show the rect
    
    // Missing amount on the four directions
    float missingLeft 	= NSMinX(vRect) - NSMinX(rect);
    float missingRight 	= NSMaxX(rect)  - NSMaxX(vRect);

    float missingTop 	= NSMinY(vRect) - NSMinY(rect);
    float missingBottom = NSMaxY(rect)  - NSMaxY(vRect);

    float dx = 0.f;
    float dy = 0.f;

    if (missingLeft * missingRight < 0)
		{
        // We need to scroll in one direction - no need to scroll if we're
        // missing bits both ways or if everything is visible

        // Let's do the minimal amount of scrolling
        if (fabs(missingLeft) < fabs(missingRight))
            dx = -missingLeft;
         else
            dx = missingRight;
		}

    if (missingTop * missingBottom < 0)
		{
        // We need to scroll in one direction - no need to scroll if we're  both ways or
        // missing bits if everything is visible

        // Let's do the minimal amount of scrolling
        if (fabs(missingTop) < fabs(missingBottom))
            dy = -missingTop;
        else
            dy = missingBottom;
        }

    if (dx != 0 || dy != 0)
		{
        NSPoint pt = vRect.origin;
        pt.x += dx;
        pt.y += dy;
        pt = [documentView convertPoint:pt toView:clipView];
        [clipView scrollToPoint:pt];
        return YES;
		}
    return NO;
	}

/*****************************************************************************\
|* Scroll to a point
\*****************************************************************************/
-(void)scrollPoint:(NSPoint)point
	{
	AZClipView *clipView = [self enclosingClipView];

	if (clipView != nil)
		{
		NSPoint origin=[self convertPoint:point toView:clipView];
		[clipView scrollToPoint:origin];
		}
	}

/*****************************************************************************\
|* Find the closest scrollview upwards in the hierarchy
\*****************************************************************************/
- (nullable AZScrollView *)enclosingScrollView
	{
	AZView * result = self.superview;

	for (;result != nil; result = result.superview)
		if ([result isKindOfClass:AZScrollView.class])
     return (AZScrollView *) result;

	return nil;
	}

/*****************************************************************************\
|* Find an enclosing clipview
\*****************************************************************************/
-(nullable AZClipView *) enclosingClipView
	{
	AZView *result = self.superview;

	for(;result != nil; result = result.superview)
		if ([result isKindOfClass:[AZClipView class]])
			return (AZClipView *)result;

	return nil;
	}


// MARK: AZDraggingSource

/*****************************************************************************\
|* AZDraggingSource: Return the type of drag the view wishes to perform. This
|* should be overridden in a subclass
\*****************************************************************************/
- (AZDragOperation)draggingSession:(AZDraggingSession *)session
	sourceOperationMaskForDraggingContext:(AZDraggingContext)context
	{
	return AZDragOperationNone;
	}


/*****************************************************************************\
|* Initiate a dragging session
\*****************************************************************************/
- (AZDraggingSession *)
beginDraggingSessionWithItems:(NSArray<AZDraggingItem *> *) items
						event:(AZEvent *) event
					   source:(id<AZDraggingSource>) source
	{
	return [self.window _beginDraggingSessionWithItems:items
												 event:event
											    source:source];
	}


/*****************************************************************************\
|* Create an image from the backing textures of the view and its subviews
\*****************************************************************************/
- (AZImage *) backingImage
	{
	NSSize size 		= self.bounds.size;
	AZImage *img 		= [AZImage imageWithSize:size];
	id<AZRenderer> azr	= AZRenderer.renderer;
	[azr lockFocusOn:img.texture];

	[self _renderRecursivelyAt:NSMakePoint(0,0)];
	[azr unlockFocus];
	return img;
	}

- (void) _renderRecursivelyAt:(NSPoint)p
	{
	id<AZRenderer> azr	= AZRenderer.renderer;
	NSRect dst = self.bounds;
	dst.origin.x += p.x;
	dst.origin.y += p.y;

	[azr blitFrom:self.bg src:self.bounds dst:dst];
	for (AZView *subview in [self.subviews reverseObjectEnumerator])
		{
		SDL_BlendMode mode = subview.isOpaque ? SDL_BLENDMODE_NONE
											  : SDL_BLENDMODE_ADD_PREMULTIPLIED;
		[azr setBlendMode:mode];
			{
			NSPoint pt = subview.frame.origin;
			pt.x += p.x;
			pt.y += p.y;
			[subview _renderRecursivelyAt:pt];
			}
		}
	}

// MARK: AZDraggingDestination

/*****************************************************************************\
|* Dragging has ended, inform the destination
\*****************************************************************************/
- (void)draggingEnded:(nonnull id<AZDraggingInfo>)sender
	{}

/*****************************************************************************\
|* Dragging has entered this view, return what drop is acceptable
\*****************************************************************************/
- (AZDragOperation)draggingEntered:(nonnull id<AZDraggingInfo>)sender
	{
	return AZDragOperationNone;
	}

/*****************************************************************************\
|* Dragging has exited this view
\*****************************************************************************/
- (void)draggingExited:(nonnull id<AZDraggingInfo>)sender
	{}

/*****************************************************************************\
|* Dragging has lingered in this view, return what drop is now acceptable
\*****************************************************************************/
- (AZDragOperation)draggingUpdated:(nonnull id<AZDraggingInfo>)sender
	{
	return AZDragOperationNone;
	}

/*****************************************************************************\
|* Inform the sender if we want to be updated (other than exit/enter)
\*****************************************************************************/
- (BOOL)wantsPeriodicDraggingUpdates
	{
	return NO;
	}

/*****************************************************************************\
|* Register this view as having an interest in a bunch of drag-types
\*****************************************************************************/
- (void)registerForDraggedTypes:(nonnull NSArray<NSString *> *)newTypes
	{
	_dragTypes = [NSSet setWithArray:newTypes];
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
|* Do the actual drop, sent if the -prepareForDragOperation returns YES
\*****************************************************************************/
- (BOOL) performDragOperation:(id<AZDraggingInfo>) sender
	{
	return NO;
	}

/*****************************************************************************\
|* And handle the drop completing, sent if -performDragOperation returns YES
\*****************************************************************************/
- (void) concludeDragOperation:(id<AZDraggingInfo>) sender
	{}


// MARK: Private methods

/*****************************************************************************\
|* Calculate the visible rect
\*****************************************************************************/
- (NSRect) _calculateVisibleRect
	{
	if ([self isHiddenOrHasHiddenAncestor])
		return NSZeroRect;

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
	BOOL doFrame			= YES;

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
