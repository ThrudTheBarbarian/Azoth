//
//  AZScroller.m
//  Azoth
//
//  Created by Simon Gornall on 12/21/24.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZButton.h"
#import "AZColour.h"
#import "AZEvent.h"
#import "AZFont.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZScroller.h"
#import "AZWindow.h"

#define SCROLLER_WIDTH		10	// Pixels wide/high for the scroller

enum
	{
	STATE_HN	= 0,			// Knob, horizontal
	STATE_HT,					// Track, horizontal
	STATE_HD,					// Knob, disabled
	STATE_HTD,					// Track, horizontal, disabled

	STATE_VN,					// Knob, vertical
	STATE_VT,					// Track, vertical
	STATE_VD,					// Knob, disabled
	STATE_VTD,					// Track, vertical, disabled

	STATE_NUM
	};

static NSRect	_sL[STATE_NUM];
static NSRect	_sC[STATE_NUM];
static NSRect	_sR[STATE_NUM];

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZScroller()
@property(assign, nonatomic) BOOL								horizontal;
@property(assign, nonatomic) BOOL								dragging;
@property(assign, nonatomic) NSPoint							dragP;
@property(assign, nonatomic) float								initialValue;
@property(assign, nonatomic) float								knobLow;
@property(assign, nonatomic) float								knobHigh;
@end


@implementation AZScroller
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	[AZScroller _fetchRects];

	BOOL horizontal = NO;
	if (NSWidth(frame) > NSHeight(frame))
		{
		horizontal = YES;
		frame.size.height = SCROLLER_WIDTH;
		}
	else
		{
		frame.size.width = SCROLLER_WIDTH;
		}

	if (self = [super initWithFrame:frame])
		{
		self.knobProportion		= 0.1;
		self.doubleValue 		= 0.0;
		self.backgroundColour 	= AZColour.clear;
		self.dragging 			= NO;
		self.enabled 			= YES;
		self.continuous 		= YES;
		self.isHidden			= NO;
		self.knobLow			= 0.f;
		self.knobHigh			= 1.f;
		self.horizontal 		= horizontal;
		}
	return self;
	}

/*****************************************************************************\
|* Return the size of a scrollbar
\*****************************************************************************/
+ (float) scrollerWidth
	{
	[AZScroller _fetchRects];
	return _sL[STATE_HT].size.height;
	}

/*****************************************************************************\
|* Draw
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];
	if (_horizontal)
		[self _drawHorizontalScrollerInRect:dirtyRect with:painter];
	else
		[self _drawVerticalScrollerInRect:dirtyRect with:painter];
	}

/*****************************************************************************\
|* Draw a horizontal scrollbar
\*****************************************************************************/
- (void) _drawHorizontalScrollerInRect:(NSRect)dirty with:(AZPainter *)P
	{
	NSRect b 			= self.bounds;
	NSInteger ui		= [AZApp textureFor:kUiMap];
	AZRenderer *azr		= AZRenderer.renderer;

	// Map the track source rectangles
	NSRect srcL = _sL[STATE_HT];
	NSRect srcT = _sC[STATE_HTD];
	NSRect srcC = _sC[STATE_HT];
	NSRect srcR = _sR[STATE_HT];

	int W = NSMaxX(b) - SCROLLER_WIDTH;
	if (self.enabled)
		{
		// Draw the entire bezel
		NSRect dstT = NSMakeRect(0, 0, W, NSHeight(srcT));
		[azr tileFrom:ui src:srcT dst:dstT];
		}

	// Draw the left bezel
	NSRect dstL = NSMakeRect(0, 1, NSWidth(srcL), NSHeight(srcL));
	[azr blitFrom:ui src:srcL dst:dstL];

	// Draw the center bezel
	int stretch = W - NSWidth(srcL) - NSWidth(srcR);
	NSRect dstC = NSMakeRect(NSWidth(srcL), 1, stretch, NSHeight(srcC));
	[azr tileFrom:ui src:srcC dst:dstC];

	// Draw the right bezel
	int xx		= W - NSWidth(srcR);
	NSRect dstR = NSMakeRect(xx, 1, NSWidth(srcR), NSHeight(srcR));
	[azr blitFrom:ui src:srcR dst:dstR];

	// Map the knob source rectangles
	float y = 2;
	if (self.enabled)
		{
		srcL = _sL[STATE_HN];
		srcC = _sC[STATE_HN];
		srcR = _sR[STATE_HN];
		y = 1;
		}
	else
		{
		srcL = _sL[STATE_HD];
		srcC = _sC[STATE_HD];
		srcR = _sR[STATE_HD];
		}

	// Figure out the size of the knob from the proportion
	float width = self.knobProportion * W;

	// If width < 2x end-points, make it = to 2x endpoints
	float minWidth = NSWidth(srcL) + NSWidth(srcR);
	if (width < minWidth)
		width = minWidth;

	// Figure out the starting co-ordinate for the knob
	float x = (W-width) * self.doubleValue;

	// Draw the left bezel
	self.knobLow = x;
	dstL = NSMakeRect(x, y, NSWidth(srcL), NSHeight(srcL));
	[azr blitFrom:ui src:srcL dst:dstL];
	x += NSWidth(srcL);

	// Draw the center bezel
	stretch = width - NSWidth(srcL) - NSWidth(srcR);
	if (stretch > 0)
		{
		NSRect dstC = NSMakeRect(x, y, stretch, NSHeight(srcC));
		[azr tileFrom:ui src:srcC dst:dstC];
		x += stretch;
		}

	// Draw the right bezel
	dstR = NSMakeRect(x, y, NSWidth(srcR), NSHeight(srcR));
	[azr blitFrom:ui src:srcR dst:dstR];
	self.knobHigh = x + NSWidth(srcR);

	// Draw a line to separate the content from the scrollbar
	[azr setBlendMode:SDL_BLENDMODE_BLEND];
	[azr setDrawColourToRed:0x80 g:0x80 b:0x80 a:0x80];
	[P lineAtX:0 y:0 toX:NSMaxX(b) y:0];
	}

/*****************************************************************************\
|* Draw a vertical scrollbar
\*****************************************************************************/
- (void) _drawVerticalScrollerInRect:(NSRect)dirty with:(AZPainter *)P
	{
	NSRect b 			= self.bounds;
	NSInteger ui		= [AZApp textureFor:kUiMap];
	AZRenderer *azr		= AZRenderer.renderer;

	// Map the track source rectangles
	NSRect srcL = _sL[STATE_VT];
	NSRect srcT = _sC[STATE_VTD];
	NSRect srcC = _sC[STATE_VT];
	NSRect srcR = _sR[STATE_VT];

	int H = NSMaxY(b) - SCROLLER_WIDTH;
	int W = NSMaxX(b) - SCROLLER_WIDTH +1;
	if (self.enabled)
		{
		// Draw the entire bezel
		NSRect dstT = NSMakeRect(W, 0, NSWidth(srcT), H);
		[azr tileFrom:ui src:srcT dst:dstT];
		}

	// Draw the top bezel
	NSRect dstL = NSMakeRect(W, 0, NSWidth(srcL), NSHeight(srcL));
	[azr blitFrom:ui src:srcL dst:dstL];


	// Draw the center bezel
	int stretch = H - NSHeight(srcL) - NSHeight(srcR);
	NSRect dstC = NSMakeRect(W, NSHeight(srcL), NSWidth(srcC), stretch);
	[azr tileFrom:ui src:srcC dst:dstC];

	// Draw the bottom bezel
	int yy		= H - NSHeight(srcR);
	NSRect dstR = NSMakeRect(W, yy, NSWidth(srcR), NSHeight(srcR));
	[azr blitFrom:ui src:srcR dst:dstR];

	// Map the knob source rectangles
	float x = W+1;
	if (self.enabled)
		{
		srcL = _sL[STATE_VN];
		srcC = _sC[STATE_VN];
		srcR = _sR[STATE_VN];
		x = W+1;
		}
	else
		{
		srcL = _sL[STATE_VD];
		srcC = _sC[STATE_VD];
		srcR = _sR[STATE_VD];
		}

	// Figure out the size of the knob from the proportion
	float height = self.knobProportion * H;

	// If height < 2x end-points, make it = to 2x endpoints
	float minHeight = NSHeight(srcL) + NSHeight(srcR);
	if (height < minHeight)
		height = minHeight;

	// Figure out the starting co-ordinate for the knob
	float y = (H-height) * self.doubleValue;

	// Draw the top bezel
	self.knobLow = y;
	dstL = NSMakeRect(x, y, NSWidth(srcL), NSHeight(srcL));
	[azr blitFrom:ui src:srcL dst:dstL];
	y += NSHeight(srcL);

	// Draw the center bezel
	stretch = height - NSHeight(srcL) - NSHeight(srcR);
	if (stretch > 0)
		{
		NSRect dstC = NSMakeRect(x, y, NSWidth(srcC), stretch);
		[azr tileFrom:ui src:srcC dst:dstC];
		y += stretch;
		}

	// Draw the bottom bezel
	dstR = NSMakeRect(x, y, NSWidth(srcR), NSHeight(srcR));
	[azr blitFrom:ui src:srcR dst:dstR];
	self.knobHigh = y + NSHeight(srcR);

	// Draw a line to separate the content from the scrollbar
	[azr setBlendMode:SDL_BLENDMODE_BLEND];
	[azr setDrawColourToRed:0x80 g:0x80 b:0x80 a:0x80];
	[P lineAtX:W-1 y:0 toX:W-1 y:NSMaxY(b)];
	}

// Events

/*****************************************************************************\
|* Figure out which part of the scroller we clicked on
\*****************************************************************************/
- (void) _calculateHitPart
	{
	float val = (self.horizontal) ? _dragP.x : _dragP.y;

	if (val < _knobLow)
		_hitPart = AZScrollerDecrementPage;
	else if (val < _knobHigh)
		_hitPart = AZScrollerKnob;
	else
		_hitPart = AZScrollerIncrementPage;
	}

/*****************************************************************************\
|* Handle mouse events
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	self.enabled 		= YES;
	self.dragging 		= YES;
 	NSPoint p 			= e.locationInWindow;
	_dragP				= [self convertPoint:p fromView:nil];
	_initialValue		= self.doubleValue;

	[self _calculateHitPart];
	return YES;
	}

- (BOOL) mouseDragged:(AZEvent *)e
	{
	return _horizontal ? [self mouseDraggedHorizontally:e]
					   : [self mouseDraggedVertically:e];
	}

- (BOOL) mouseDraggedHorizontally:(AZEvent *)e
	{
 	NSRect b		= self.bounds;
	int W 			= NSMaxX(b) - SCROLLER_WIDTH;
	NSPoint p		= [self convertPoint:e.locationInWindow fromView:nil];

	// Figure out the size of the knob from the proportion
	float width = self.knobProportion * W;

	// If width < 2x end-points, make it = to 2x endpoints
	float minWidth = NSWidth(_sL[STATE_HN]) + NSWidth(_sR[STATE_HN]);
	if (width < minWidth)
		width = minWidth;

	float totalSize = W - width;
	if (totalSize > 0.f)
		{
		// Bounds-constrain the effective mouse position
		p.x = (p.x < 0.f) ? 0.f : p.x;
		p.x = (p.x > W  ) ? W   : p.x;

		float dx = p.x - _dragP.x;

		// Figure out the current value of the scroller
		self.doubleValue = _initialValue + dx/totalSize;
		self.doubleValue = (self.doubleValue < 0.f) ? 0.f : self.doubleValue;
		self.doubleValue = (self.doubleValue > 1.f) ? 1.f : self.doubleValue;

		// Send events
		if (self.continuous)
			[self sendAction:self.action to:self.target];

		[self setNeedsDisplay:YES];
		}
	else
		self.doubleValue = 0.f;

	return YES;
	}


- (BOOL) mouseDraggedVertically:(AZEvent *)e
	{
 	NSRect b		= self.bounds;
	int H 			= NSMaxY(b) - SCROLLER_WIDTH;
	NSPoint p		= [self convertPoint:e.locationInWindow fromView:nil];

	// Figure out the size of the knob from the proportion
	float height = self.knobProportion * H;

	// If height < 2x end-points, make it = to 2x endpoints
	float minHeight = NSHeight(_sL[STATE_HN]) + NSHeight(_sR[STATE_HN]);
	if (height < minHeight)
		height = minHeight;

	float totalSize = H - height;
	if (totalSize > 0.f)
		{
		// Bounds-constrain the effective mouse position
		p.y = (p.y < 0.f) ? 0.f : p.y;
		p.y = (p.y > H  ) ? H   : p.y;

		float dy = p.y - _dragP.y;

		// Figure out the current value of the scroller
		self.doubleValue = _initialValue + dy/totalSize;
		self.doubleValue = (self.doubleValue < 0.f) ? 0.f : self.doubleValue;
		self.doubleValue = (self.doubleValue > 1.f) ? 1.f : self.doubleValue;

		// Send events
		if (self.continuous)
			[self sendAction:self.action to:self.target];

		[self setNeedsDisplay:YES];
		}
	else
		self.doubleValue = 0;

	return YES;
	}

- (BOOL) mouseUp:(AZEvent *)e
	{
	self.enabled = NO;
	[self sendAction:self.action to:self.target];
	return YES;
	}

// Class private methods

+ (void) _fetchRects
	{
	_sL[STATE_HN]   = [AZApp srcRectFor:@"scroller-horizontal-knob-left" in:kUiMap];
	_sC[STATE_HN]   = [AZApp srcRectFor:@"scroller-horizontal-knob-center" in:kUiMap];
	_sR[STATE_HN]   = [AZApp srcRectFor:@"scroller-horizontal-knob-right" in:kUiMap];

	_sL[STATE_HT]   = [AZApp srcRectFor:@"scroller-horizontal-track-left" in:kUiMap];
	_sC[STATE_HT]   = [AZApp srcRectFor:@"scroller-horizontal-track-center" in:kUiMap];
	_sR[STATE_HT]   = [AZApp srcRectFor:@"scroller-horizontal-track-right" in:kUiMap];

	_sL[STATE_HD]   = [AZApp srcRectFor:@"scroller-horizontal-knob-disabled-left" in:kUiMap];
	_sC[STATE_HD]   = [AZApp srcRectFor:@"scroller-horizontal-knob-disabled-center" in:kUiMap];
	_sR[STATE_HD]   = [AZApp srcRectFor:@"scroller-horizontal-knob-disabled-right" in:kUiMap];

	_sC[STATE_HTD]  = [AZApp srcRectFor:@"scroller-horizontal-track-disabled" in:kUiMap];


	_sL[STATE_VN]   = [AZApp srcRectFor:@"scroller-vertical-knob-top" in:kUiMap];
	_sC[STATE_VN]   = [AZApp srcRectFor:@"scroller-vertical-knob-center" in:kUiMap];
	_sR[STATE_VN]   = [AZApp srcRectFor:@"scroller-vertical-knob-bottom" in:kUiMap];

	_sL[STATE_VT]   = [AZApp srcRectFor:@"scroller-vertical-track-top" in:kUiMap];
	_sC[STATE_VT]   = [AZApp srcRectFor:@"scroller-vertical-track-center" in:kUiMap];
	_sR[STATE_VT]   = [AZApp srcRectFor:@"scroller-vertical-track-bottom" in:kUiMap];

	_sL[STATE_VD]   = [AZApp srcRectFor:@"scroller-vertical-knob-disabled-top" in:kUiMap];
	_sC[STATE_VD]   = [AZApp srcRectFor:@"scroller-vertical-knob-disabled-center" in:kUiMap];
	_sR[STATE_VD]   = [AZApp srcRectFor:@"scroller-vertical-knob-disabled-bottom" in:kUiMap];

	_sC[STATE_VTD]  = [AZApp srcRectFor:@"scroller-vertical-track-disabled" in:kUiMap];
	}

@end
