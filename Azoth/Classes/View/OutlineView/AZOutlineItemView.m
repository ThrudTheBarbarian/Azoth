//
//  AZOutlineItemView.m
//  Azoth
//
//  Created by Simon Gornall on 12/31/24.
//

#import "AZApplication.h"
#import "AZColour.h"
#import "AZEvent.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZOutlineItemView.h"

#define DISCLOSURE_WIDTH		(10)

enum
	{
	STATE_C	= 0,				// Closed
	STATE_O,					// Open
	STATE_S,					// Selected

	STATE_NUM
	};

static NSRect	_img[STATE_NUM];
static NSRect	_rT;
static NSRect	_rM;
static NSRect	_rB;

@interface AZOutlineItemView()

// The indent for this item
@property(assign, nonatomic) float									indent;

// The rectangle where we drew the disclosure triangle
@property(assign, nonatomic) NSRect									disclose;
@end

@implementation AZOutlineItemView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithView:(AZView *)view andFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken,
			^{
			[self _fetchRects];
			});

		self.hostedView			= view;
		[self addSubview:view];
		self.backgroundColour 	= AZColour.clear;
		self.disclose 			= NSZeroRect;
		self.preferredWidth		= frame.size.width - DISCLOSURE_WIDTH;
		}
	return self;
	}

+ (AZOutlineItemView *) itemViewWithView:(AZView *)view andFrame:(NSRect)frame
	{
	return [[AZOutlineItemView alloc] initWithView:view andFrame:frame];
	}


/*****************************************************************************\
|* Reconfigure with an indentation
\*****************************************************************************/
- (void) indentBy:(float)indent
	{
	NSRect frame = self.bounds;

	// square off the disclosure
	frame.origin.x   	  += DISCLOSURE_WIDTH;
	frame.size.width 	  -= DISCLOSURE_WIDTH;

	// Add the indent
	_indent				   = indent;
	frame.origin.x   	  += indent;
	frame.size.width      -= indent;
	[self.subviews[0] setFrame:frame];
	}

/*****************************************************************************\
|* Draw the view
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	AZRenderer *azr 	= AZRenderer.renderer;
	NSInteger ui		= [AZApp textureFor:kUiMap];

	if (_selected)
		{
		AZRenderer *azr = AZRenderer.renderer;
		NSInteger ui	= [AZApp textureFor:kUiMap];

		float bx		= _indent;
		float bw 		= self.bounds.size.width - _indent;
		float bh		= self.bounds.size.height;

		NSRect dT		= {bx, 0, bw, _rT.size.height};

		NSRect dM	= {bx,
					   _rT.size.height,
					   bw,
					   bh - _rT.size.height - _rB.size.height};

		NSRect dB	= {bx,
					   dM.size.height,
					   bw,
					   _rB.size.height};

		[azr tileFrom:ui src:_rT dst:dT];
		[azr tileFrom:ui src:_rM dst:dM];
		[azr tileFrom:ui src:_rB dst:dB];
		}

	if (_isOpen)
		{
		NSRect src 			= _img[STATE_O];
		_disclose 			= src;
		_disclose.origin.x 	= _indent + 4;
		_disclose.origin.y 	= (self.bounds.size.height - src.size.height)/2;
		[azr blitFrom:ui src:src dst:_disclose];
		}
	else if (_hasChildren)
		{
		NSRect src 			= _img[STATE_C];
		_disclose 			= src;
		_disclose.origin.x 	= _indent + 4;
		_disclose.origin.y 	= (self.bounds.size.height - src.size.height)/2 - 3;
		[azr blitFrom:ui src:src dst:_disclose];
		}

	}

/*****************************************************************************\
|* Populate the rectangles from the UI texture atlas
\*****************************************************************************/
- (void) _fetchRects
	{
	_img[STATE_O]   = [AZApp srcRectFor:@"tableview-headerview-descending" in:kUiMap];
	_img[STATE_C]   = [AZApp srcRectFor:@"tableview-headerview-right" in:kUiMap];
	_img[STATE_S]   = [AZApp srcRectFor:@"menu-bar-window-background-selected" in:kUiMap];


	// Split by height so we can tile any row-height
	_rT = _img[STATE_S];
	_rB = _img[STATE_S];
	_rM = _img[STATE_S];

	_rT.size.height = 5;

	_rB.size.height = 5;
	_rB.origin.y += (_rM.size.height - 5);

	_rM.size.height -= 10;
	_rM.origin.y += 5;
	}

/*****************************************************************************\
|* We got a mouse click
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];
	if (NSPointInRect(p, _disclose))
		_reason = AZOutlineViewItemDisclosed;
	else
		_reason = AZOutlineViewItemSelected;

	[self sendAction:self.action to:self.target];
	return YES;
	}

@end
