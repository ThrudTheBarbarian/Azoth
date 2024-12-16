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
#import "AZPainter.h"
#import "AZView.h"
#import "AZView+Internal.h"

/*****************************************************************************\
|* Store the top-level content-views for each window we know about
\*****************************************************************************/
static NSMutableDictionary<NSNumber *, AZView *> * _contentViews = nil;

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZView()
@end

@implementation AZView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super init])
		{
		_frame 					= frame;
		_bounds					= frame;
		_bounds.origin 			= (NSPoint){0,0};
		_subviews				= [NSMutableArray new];
		_identifier				= @"";
		_superview				= nil;
		_bg 					= NULL;
		_bgColour				= [AZColour blackColour];
		_isOpaque				= NO;
		_autoresizesSubviews	= YES;
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
	if (_bg != NULL)
		SDL_DestroyTexture(_bg);
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
|* this with nil will convert from window co-ordinates. The view must be in
|* the superview-hierarchy otherwise.
\*****************************************************************************/
- (NSPoint) convertPoint:(NSPoint)p fromView:(nullable AZView *)otherView
	{
	AZView *view = self;
	while (view != otherView)
		{
		p.x -= view.frame.origin.x;
		p.y -= view.frame.origin.y;
		view = view.superview;
		if (view == nil)
			break;
		}

	return p;
	}

/*****************************************************************************\
|* Convert a point from our own view's co-ordinate system to another. Calling
|* this with nil will convert to window co-ordinates. The view must be in
|* the superview-hierarchy otherwise.
\*****************************************************************************/
- (NSPoint) convertPoint:(NSPoint)p toView:(nullable AZView *)otherView
	{
	AZView *view = self.superview;
	while (view != otherView)
		{
		if (view == nil)
			break;

		p.x += view.frame.origin.x;
		p.y += view.frame.origin.y;
		view = view.superview;
		}

	return p;
	}



// MARK: Event handling

/*****************************************************************************\
|* Mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDown:(struct SDL_MouseButtonEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-button-up event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseUp:(struct SDL_MouseButtonEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-moved event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseMoved:(struct SDL_MouseMotionEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-dragged event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDragged:(struct SDL_MouseMotionEvent *)e
	{ return NO; }

/*****************************************************************************\
|* Mouse-wheel event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseWheeled:(struct SDL_MouseWheelEvent *)e;
	{ return NO; }



// MARK: View processing

/*****************************************************************************\
|* Return the contentView for any given SDL_Window. If one does not exist it
|* will be created and returned
\*****************************************************************************/
+ (AZView *) contentViewForWindow:(SDL_Window *)window
	{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		_contentViews = [NSMutableDictionary new];
		});

	NSNumber *windowId 		= @(SDL_GetWindowID(window));
	AZView * contentView 	= [_contentViews objectForKey:windowId];
	if (contentView == nil)
		{
		int w, h;
		SDL_GetWindowSize(window, &w, &h);
		NSRect frame			= (NSRect){{0,0}, {w,h}};
		contentView 			= [AZView viewWithFrame:frame];
		contentView.window		= window;
		_contentViews[windowId] = contentView;
		contentView.isOpaque 	= YES;
		[contentView _installBackingTexture];
		}
	return contentView;
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
	return YES;
	}

/*****************************************************************************\
|* Add a subview to the list of views, in front of another view
\*****************************************************************************/
- (BOOL) addSubview:(AZView *)view before:(AZView *)other
	{
	BOOL ok 		= NO;
	NSInteger idx 	= 0;

	for (AZView *view in _subviews)
		if (view == other)
			{
			[_subviews insertObject:view atIndex:idx];
			ok = YES;
			}

	if (!ok)
		[_subviews addObject:view];

	view.superview = self;
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

	view.superview = self;
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


// MARK: Redraw


/*****************************************************************************\
|* What to override in subclasses to get a view to draw. This renders into the
|* local texture, so is at (0,0) wrt to that texture. Pixel positioning ought
|* to be perfectly aligned. By default the view is cleared to its background
|* colour
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{

	SDL_Renderer *renderer = SDL_GetRenderer(self.window);

	SDL_SetRenderDrawColor(renderer, self.bgColour.red,
									 self.bgColour.green,
									 self.bgColour.blue,
									 self.bgColour.alpha);
	SDL_FRect rect =	SDLFRectFromNSRect(dirtyRect);
	SDL_RenderFillRect(renderer, &rect);
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

- (void) setFrame:(NSRect)frame
	{
	NSSize oldSize = self.frame.size;
	_frame = frame;
	_bounds.size = _frame.size;

	if (self.autoresizesSubviews)
		[self resizeSubviewsWithOldSize:oldSize];
	[self setNeedsDisplay:YES];
	}

- (void) resizeSubviewsWithOldSize:(NSSize)size
	{
	for (AZView *subview in self.subviews)
		{
		if ([subview resizeWithOldSuperviewSize:size])
			[subview resizeSubviewsWithOldSize:subview.frame.size];
		}
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

	// Distribute the gains fairly, so see how many <--> areas can change
	int count 	= (left ? 1 : 0) + (center ? 1 : 0)  + (right ? 1 : 0);
	int done  	= 0;
	if (count > 0)
		{
		int ddx = dx/count;
		if (left)
			{
			frame.origin.x -= ddx;
			frame.size.width += ddx;
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
			{
			frame.size.width += delta;
			dx -= delta;
			}
		if (dx != 0)
			NSLog(@"Error in width calcs (dx=%d)", dx);
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
@end
