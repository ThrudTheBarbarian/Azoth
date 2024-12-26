//
//  AZSplitView.m
//  Azoth
//
//  Created by Simon Gornall on 12/24/24.
//

#import <SDL3/SDL.h>

#import "AZColour.h"
#import "AZEvent.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZSplitView.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZSplitView()
// Whether we clicked on a divider and started dragging it
@property(assign, nonatomic) BOOL								isDragging;

// The divider we clicked on, when isDragging is true
@property(assign, nonatomic) NSInteger							divider;
@end

@implementation AZSplitView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		_dividerStyle 	= AZSplitViewDividerStyleThick;
		_isVertical 	= NO;
		}
	return self;
	}

/*****************************************************************************\
|* Clean up on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
	[nc removeObserver:self];
	}

/*****************************************************************************\
|* Set the delegate and update any notifications, removing them from any old
|* delegate we might previously have had
\*****************************************************************************/
- (void) setDelegate:(NSObject *)delegate
	{
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;

    if ([_delegate respondsToSelector:@selector(splitViewDidResizeSubviews:)])
        [nc removeObserver:_delegate
					  name:AZSplitViewDidResizeSubviewsNotification
					object:self];

    if ([_delegate respondsToSelector:@selector(splitViewWillResizeSubviews:)])
        [nc removeObserver:_delegate
					  name:AZSplitViewWillResizeSubviewsNotification
					object:self];

	_delegate = delegate;

    if ([_delegate respondsToSelector:@selector(splitViewDidResizeSubviews:)])
		[nc addObserver:_delegate
			   selector:@selector(splitViewDidResizeSubviews:)
				   name:AZSplitViewDidResizeSubviewsNotification
				 object:self];

    if ([_delegate respondsToSelector:@selector(splitViewWillResizeSubviews:)])
		[nc addObserver:_delegate
			   selector:@selector(splitViewWillResizeSubviews:)
				   name:AZSplitViewWillResizeSubviewsNotification
				 object:self];
	}


/*****************************************************************************\
|* Set whether this is a vertical or horizontal splitview
\*****************************************************************************/
- (void) setIsVertical:(BOOL)isVertical
	{
	if (isVertical == self.isVertical)
		return; // No work to do

	_isVertical = isVertical;
	[self adjustSubviews];
	}

/*****************************************************************************\
|* Determine whether a subview is collapsed
|*
|*  From Apple's header comments:
|*  Collapsed subviews are hidden but retained by the split view.
|*  Collapsing of a subview will not change its bounds, but may set its frame
|*  to zero pixels high (horizontal) or zero pixels wide (vertical).
\*****************************************************************************/
- (BOOL) isSubviewCollapsed:(AZView *)subview
	{
    return subview.hidden;
	}

/*****************************************************************************\
|* Set the divider style to use to draw
\*****************************************************************************/
- (void) setDividerStyle:(AZSplitViewDividerStyle)style
	{
	_dividerStyle = style;
	[self setNeedsDisplay: YES];
	}

/*****************************************************************************\
|* Apple says this method sets the frames of the split view's subviews so that
|* they, plus the dividers, fill the split view. The default implementation of
|* this method resizes all of the subviews proportionally so that the ratio of
|* heights (in the horizontal split view case) or widths (in the vertical
|* split view case) doesn't change, even though the absolute sizes of the
|* subviews do change. This message should be sent to split views from which
|* subviews have been added or removed, to reestablish the consistency of
|* subview placement.
\*****************************************************************************/
- (void) adjustSubviews
	{
    if (self.subviews.count < 2)
        return;

   [self _postNoteWillResize];

   if ([self isVertical])
        [self _adjustSubviewWidths];
    else
        [self _adjustSubviewHeights];

    [self setNeedsDisplay: YES];
    [self _postNoteDidResize];
	}

/*****************************************************************************\
|* Figure out the divider thickness based on type
\*****************************************************************************/
-(float)dividerThickness
	{
	if (_dividerStyle == AZSplitViewDividerStyleThick)
		return 10;

	return 5;
	}

/*****************************************************************************\
|* Draw the view (well, the dividers, mainly)
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
   	NSInteger count = self.subviews.count;

	for (NSInteger i=0; i<count-1; i++)
		if (self.dividerThickness > 0)
			{
			NSRect rect = [self _dividerRectAtIndex:i];
			[self _drawDividerInRect:rect withPainter:painter];
			}
	}

// MARK: NSView

/*****************************************************************************\
|* Override the addsubvie to also re-layout
\*****************************************************************************/
- (BOOL) addSubview:(AZView *)view
	{
	[super addSubview:view];
	[self adjustSubviews];
	return YES;
	}

/*****************************************************************************\
|* Override the resize to manage our subviews
\*****************************************************************************/
-(void)resizeSubviewsWithOldSize:(NSSize)oldSize
	{
	NSSize  size	= self.bounds.size;

	if (size.width < 1)
		size.width = 1;
	if (size.height < 1)
		size.height = 1;
	if (oldSize.width < 1)
		oldSize.width = 1;
	if (oldSize.height < 1)
		oldSize.height = 1;

	SEL method = @selector(splitView:resizeSubviewsWithOldSize:);
	if ([_delegate respondsToSelector:method])
		[_delegate splitView:self resizeSubviewsWithOldSize:oldSize];
	else
		{
		// Apple docs say just call adjustSubviews
		[self adjustSubviews];
		}
	}

// MARK: Events

/*****************************************************************************\
|* Handle a mouse press
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e;
	{
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];
    _divider			= [self _dividerIndexAtPoint:p];

    if (_divider == NSNotFound)
        {
		self.isDragging = NO;
        return NO;
		}

	[self _postNoteWillResize];
	self.isDragging = YES;
	return YES;
	}

/*****************************************************************************\
|* And if we're dragging on the divider, handle that
\*****************************************************************************/
- (BOOL) mouseDragged:(AZEvent *)e
	{
	BOOL handled = NO;
	if (self.isDragging)
		{
		NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

       if (self.isVertical)
           [self setPosition:p.x ofDividerAtIndex:_divider];
       else
           [self setPosition:p.y ofDividerAtIndex:_divider];

		handled = YES;
		}
	return handled;
	}

/*****************************************************************************\
|* Handle a mouse-release
\*****************************************************************************/
- (BOOL) mouseUp:(AZEvent *)e
	{
	BOOL handled = NO;
	if (_isDragging)
		{
		[self _postNoteDidResize];
		_isDragging = NO;
		handled 	= YES;
		}

	return handled;
	}

/*****************************************************************************\
|* Update a divider position
\*****************************************************************************/
- (void)setPosition:(float)position ofDividerAtIndex:(NSInteger)index
	{
	if ((index < 0) || (index >= self.subviews.count))
		{
		SDL_Log("Divider index for split-view out of range (%d)", (int)index);
		return;
		}

    AZView *subview0 		= [self.subviews objectAtIndex: index];
    AZView *subview1 		= [self.subviews objectAtIndex: index + 1];

    BOOL subview0Expanded 	= [self isSubviewCollapsed: subview0] == NO;
    BOOL subview1Expanded 	= [self isSubviewCollapsed: subview1] == NO;

    float minPosition 		= 0;
    float maxPosition 		= 0;

    NSRect frame0 			= subview0Expanded ? subview0.frame : NSZeroRect;
    NSRect frame1 			= subview1Expanded ? subview1.frame : NSZeroRect;
    
	/*************************************************************************\
	|* Determine the minimum position
	\*************************************************************************/
    if (subview0Expanded)
		minPosition = self.isVertical ? NSMinX(frame0) : NSMinY(frame0);
    else
		{
		if (subview1Expanded == NO)
			{
			SDL_Log("Splitview has collapsed views @ index %d", (int)index);
			return;
			}
		minPosition = self.isVertical ? NSMinX(frame1) : NSMinY(frame1);
		}
    
	/*************************************************************************\
	|* Determine the maximum position
	\*************************************************************************/
    if (subview1Expanded)
		maxPosition = self.isVertical ? NSMaxX(frame1) : NSMaxY(frame1);
    else
		{
		if (subview0Expanded == NO)
			{
			SDL_Log("Splitview has collapsed views @ index %d", (int)index);
			return;
			}
		maxPosition = self.isVertical ? NSMaxX(frame0) : NSMaxY(frame0);
		}

 	/*************************************************************************\
	|* Check in with the delegate and see if it wants to tweak the min and max
	\*************************************************************************/
	SEL minSel 		= @selector(splitView:constrainMinCoordinate:ofSubviewAt:);
	SEL maxSel 		= @selector(splitView:constrainMaxCoordinate:ofSubviewAt:);
	SEL trackSel	= @selector(splitView:constrainSplitPosition:ofSubviewAt:);

    if ([_delegate respondsToSelector:minSel])
		minPosition = [_delegate splitView:self
					constrainMinCoordinate:minPosition
							   ofSubviewAt:index];

    if ([_delegate respondsToSelector:maxSel])
		minPosition = [_delegate splitView:self
					constrainMaxCoordinate:maxPosition
							   ofSubviewAt:index];

 	/*************************************************************************\
	|* And if it wants to constrain the divider position
	\*************************************************************************/
    if ([_delegate respondsToSelector:trackSel])
        position = [_delegate splitView:self
				 constrainSplitPosition:position
							ofSubviewAt:index];


 	/*************************************************************************\
	|* OK we're ready to figure out where the divider can be positioned
	\*************************************************************************/
    NSRect  resize0 = frame0;
    NSRect  resize1 = frame1;

	SEL collapseSel 				= @selector(splitView:canCollapseSubview:);
    BOOL delegateCollapseViewsOk	= [_delegate respondsToSelector:collapseSel];
    BOOL collapsedOrExpanded 		= NO;

 	/*************************************************************************\
	|* Handle the vertical case
	\*************************************************************************/
    if ([self isVertical])
		{
        float lastPosition 	= NSMaxX(resize0);
        float delta 		= floor(position - lastPosition);
        resize0.size.width += delta;
        resize1.size.width -= delta;
        
		/*********************************************************************\
		|* Does the delegate want to weigh in on collapsing subviews ?
		\*********************************************************************/
		if (delegateCollapseViewsOk)
			{
            if (position < minPosition)
				{
                if ([_delegate splitView:self canCollapseSubview:subview0])
					{
                    subview0.hidden		= YES;
                    collapsedOrExpanded = YES;
					}
				}
			else if (position > maxPosition)
				{
                if ([_delegate splitView: self canCollapseSubview: subview1])
					{
                    subview1.hidden 	= YES;
                    collapsedOrExpanded = YES;
					}
				}
			}
        
		/*********************************************************************\
		|* But make sure collapsed views can reappear
		\*********************************************************************/
        if ((position > minPosition) && subview0.hidden)
			{
            subview0.hidden 		= NO;
            collapsedOrExpanded 	= YES;
			}
		else if ((position < maxPosition) && subview1.hidden)
			{
            subview1.hidden 		= NO;
            collapsedOrExpanded 	= YES;
			}

 		/*********************************************************************\
		|* Figure out the adjusted widths
		\*********************************************************************/
        resize0.size.width = _constrainTo(NSWidth(resize0),
										  minPosition,
										  maxPosition);
        resize1.size.width = _constrainTo(NSWidth(resize1),
										  minPosition,
										  maxPosition);
        resize1.origin.x = NSMaxX(frame1) - NSWidth(resize1);
		}

 	/*************************************************************************\
	|* Handle the horizontal case
	\*************************************************************************/
    else
		{
        float lastPosition 		= NSMaxY(resize0);
        float delta 			= floor(position - lastPosition);
        resize0.size.height    += delta;
        resize1.size.height    -= delta;

 		/*********************************************************************\
		|* Does the delegate want to weigh in on collapsing subviews ?
		\*********************************************************************/
		if (delegateCollapseViewsOk)
			{
            if (position < minPosition)
				{
                if ([_delegate splitView:self canCollapseSubview: subview0])
					{
                    subview0.hidden 	= YES;
                    collapsedOrExpanded = YES;
					}
				}
			else if (position > maxPosition)
				{
                if ([_delegate splitView: self canCollapseSubview: subview1])
					{
                    subview1.hidden 	= YES;
                    collapsedOrExpanded = YES;
					}
				}
			}
        
		/*********************************************************************\
		|* But make sure collapsed views can reappear
		\*********************************************************************/
        if ((position > minPosition) && subview0.hidden)
			{
            subview0.hidden 		= NO;
            collapsedOrExpanded 	= YES;
			}
		else if ((position < maxPosition) && subview1.hidden)
			{
            subview1.hidden 		= NO;
            collapsedOrExpanded 	= YES;
			}

 		/*********************************************************************\
		|* Figure out the adjusted heights
		\*********************************************************************/
        resize0.size.height = _constrainTo(NSHeight(resize0),
										   minPosition,
										   maxPosition);
        resize1.size.height = _constrainTo(NSHeight(resize1),
										   minPosition,
										   maxPosition);
        resize1.origin.y = NSMaxY(frame1) - NSHeight(resize1);
		}

 	/*************************************************************************\
	|* It doesn't really matter what happened with the divider because we need
	|* to get the views re-laid out - so fall back to adjustSubviews and bail
	\*************************************************************************/
    if (collapsedOrExpanded)
		{
        [self adjustSubviews];
        return;
		}

 	/*************************************************************************\
	|* Nothing special happened so just resize the subviews as expected
	\*************************************************************************/
    if (subview0.hidden == NO)
		{
        subview0.frame = resize0;

        // Tell the view to redisplay otherwise there are drawing artifacts
        [subview0  setNeedsDisplay: YES];
		}
    
    if (subview1.hidden == NO)
		{
        subview1.frame = resize1;

        // Tell the view to redisplay otherwise there are drawing artifacts
        [subview1  setNeedsDisplay: YES];
		}
    [self adjustSubviews];
    [self setNeedsDisplay:YES];
	}

// MARK: Private methods

/*****************************************************************************\
|* Constrain a value to be between extrema
\*****************************************************************************/
static float _constrainTo(float value, float min, float max)
	{
	if (value < min)
		value = min;
	if (value > max)
		value = max;
	return value;
	}

/*****************************************************************************\
|* Post a will-resize notification
\*****************************************************************************/
- (void) _postNoteWillResize
	{
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    [nc postNotificationName:AZSplitViewWillResizeSubviewsNotification
					  object:self];
	}

/*****************************************************************************\
|* Post a did-resize notification
\*****************************************************************************/
- (void) _postNoteDidResize
	{
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    [nc postNotificationName:AZSplitViewDidResizeSubviewsNotification
					  object:self];
	}

/*****************************************************************************\
|* adjust all the non-collapsed subviews so that they are equally spaced
|* horizontally within the splitview
\*****************************************************************************/
- (void) _adjustSubviewWidths
	{
    // Set all the subview heights to the bounds height of the split view
    float height = NSHeight(self.bounds);

    NSInteger count = self.subviews.count;

	// Width we've used to date
    float totalWidthBefore = 0.f;

    // The available width to the subviews
    float totalWidthAfter = self.bounds.size.width
						  - self.dividerThickness * (count-1);

    for (NSInteger i = 0; i < count; i++)
		{
        AZView *subview = [self.subviews objectAtIndex:i];
        if ([self isSubviewCollapsed: subview] == NO)
            totalWidthBefore += NSWidth(subview.frame);
        }

    float delta = totalWidthAfter / totalWidthBefore;
    
    NSRect  frame = self.bounds;
    for (NSInteger i = 0; i < count; i++)
		{
        AZView *subview = [self.subviews objectAtIndex: i];
        if ([self isSubviewCollapsed: subview] == NO)
			{
            frame.size.width 	= NSWidth(subview.frame) * delta;
            frame.size.width 	= floor(frame.size.width);
            frame.size.height	= height;

            subview.frame 		= frame;

            frame.origin.x		+= NSWidth(frame);
            frame.origin.x		+= self.dividerThickness;
			}
		}
	}

/*****************************************************************************\
|* adjust all the non-collapsed subviews so that they are equally spaced
|* vertically within the splitview
\*****************************************************************************/
- (void)_adjustSubviewHeights
	{
    // Set all the subview widths to the bounds width of the split view
    float width = NSWidth(self.bounds);

    NSInteger count = self.subviews.count;

    // We've got to figure out how much the delta is between the old and new
    // heights and multiply all the heights to the new delta to get them to
    // fit (or something like that...) Apple say they resize proportionally
    float totalHeightBefore	= 0.f;
    float totalHeightAfter	= self.bounds.size.height
							- self.dividerThickness * (count-1);

    for(NSInteger i=0; i<count; i++)
		{
        AZView *subview = [self.subviews objectAtIndex: i];
        if ([self isSubviewCollapsed: subview] == NO)
            totalHeightBefore 	   += NSHeight(subview.frame);
		}

    float delta = totalHeightAfter / totalHeightBefore;
    

    NSRect frame = self.bounds;
    for(NSInteger i=0; i<count; i++)
		{
        AZView *subview = [self.subviews objectAtIndex: i];
        if ([self isSubviewCollapsed: subview] == NO)
			{
            frame.size.height	= NSHeight(subview.frame) * delta;
            frame.size.height	= floor(frame.size.height);
            frame.size.width 	= width;

            subview.frame 		= frame;
            
            frame.origin.y		+= NSHeight(frame);
            frame.origin.y		+= self.dividerThickness;
			}
		}
	}

/*****************************************************************************\
|* Draw the divider
\*****************************************************************************/
- (void) _drawDividerInRect:(NSRect)rect withPainter:(AZPainter *)painter
	{
	if (_dividerStyle != AZSplitViewDividerStylePaneSplitter)
		{
		[painter rectangleWithRect:rect
							filled:YES
							colour:AZColour.controlColour];
		}

	/*
	// We don't have AZImage yet...
	AZImage *image 		= [self dimpleImage];
	NSSize imageSize 	= [image size];
	NSPoint point 		= rect.origin;

	if([self isVertical])
		{
		point.x += floor((NSWidth(rect) - imageSize.width)/2);
		point.y += floor((NSHeight(rect) - imageSize.height)/2);
		}
	else
		{
		point.x += floor((NSWidth(rect) - imageSize.width)/2);
		point.y += floor((NSHeight(rect) - imageSize.height)/2);
		}

	[image drawAtPoint:point
			  fromRect:NSZeroRect
			 operation:AZCompositeSourceOver
			  fraction:1.f];
	*/
	}

/*****************************************************************************\
|* Work out the rect for a given divider
\*****************************************************************************/
- (NSRect) _dividerRectAtIndex:(NSInteger)index
	{
	NSRect rect =[self.subviews objectAtIndex:index].frame;

	if (self.isVertical)
		{
		rect.origin.x 		= NSMaxX(rect);
		rect.size.width		= self.dividerThickness;
		}
	else
		{
		rect.origin.y		= NSMaxY(rect);
		rect.size.height	= self.dividerThickness;
		}

	return rect;
	}

/*****************************************************************************\
|* See if we've clicked on a divider
\*****************************************************************************/
- (NSInteger) _dividerIndexAtPoint:(NSPoint)point
	{
	NSInteger count = self.subviews.count;

	for (NSInteger i=0; i<count-1; i++)
		if (NSPointInRect(point,[self _dividerRectAtIndex:i]))
			return i;

	return NSNotFound;
	}

@end
