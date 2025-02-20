//
//  AZMenuView.m
//  Azoth
//
//  Created by Simon Gornall on 12/18/24.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZColour.h"
#import "AZEvent.h"
#import "AZEventSink.h"
#import "AZFont.h"
#import "AZPainter.h"
#import "AZTextPainter.h"
#import "AZRenderer.h"
#import "AZMenu.h"
#import "AZMenuItem.h"
#import "AZMenuView.h"
#import "AZWindow.h"

static NSRect _barSel;				// The menu bar when mouse is over it
static NSRect _menuTL;				// top-left of the menu, if rendered
static NSRect _menuTM;				// top-middle of the menu, if rendered
static NSRect _menuTR;				// top-right of the menu, if rendered
static NSRect _menuCL;				// center-left of the menu
static NSRect _menuCM;				// center-middle of the menu
static NSRect _menuCR;				// center-right of the menu
static NSRect _menuBL;				// bottom-left of the menu, if rendered
static NSRect _menuBM;				// bottom-middle of the menu, if rendered
static NSRect _menuBR;				// bottom-right of the menu, if rendered

@interface AZMenuView()
@property(assign, nonatomic) AZMenuSize 							measure;
@property(strong, nonatomic) AZEventSink * 							sink;
@end

@implementation AZMenuView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithMenu:(AZMenu *)menu andSize:(AZMenuSize)size
	{
	if (self = [super initWithFrame:size.frame])
		{
		_measure 				= size;
		_menu	 				= menu;
		self.backgroundColour 	= AZColour.clear;
		}
	return self;
	}

/*****************************************************************************\
|* Measure a menu to figure out its frame
\*****************************************************************************/
+ (AZMenuSize) measureMenu:(AZMenu *)menu
	{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		[AZMenuView _fetchRects];
		});

	AZMenuRenderFlag flags = menu.renderFlags;
	
	NSInteger count	= menu.numberOfItems;
	NSInteger top	= (flags & AZMENU_RENDER_TOP) ? NSHeight(_menuTM) : 0;
	NSInteger mid	= count * NSHeight(_barSel);
	NSInteger bot	= (flags & AZMENU_RENDER_BOTTOM) ? NSHeight(_menuBM) : 0;

	AZFont *font 	= AZApp.boldControlFont;
	int width		= 0;
	for (AZMenuItem *item in menu.itemArray)
		{
		int w = [menu widthForString:item.title];
		width = (width > w) ? width +10 : w;
		}

	width = (width < menu.measure.frame.size.width)
		  ? menu.measure.frame.size.width
		  : width;

	AZMenuSize size;
	size.frame			= NSMakeRect(0,0, width, top+mid+bot);
	size.bottomHeight	= bot;
	size.topHeight		= top;
	size.flagsUsed		= flags;
	size.fontHeight		= font.height + 6;

	if (menu.measure.frame.size.width == 0)
		menu.measure = size;

	return size;
	}


// MARK: Event handling

/*****************************************************************************\
|* We got a mouse event
\*****************************************************************************/
- (void) _receivedEvent:(AZEvent *)e
	{
	switch (e.type)
		{
		case AZLeftMouseDown:
			[self _handleMouseDown:e];
			break;

		case AZMouseMoved:
			[self _handleMouseMoved:e];
			break;

		case AZLeftMouseUp:
			break; // only used later
			
		default:
			SDL_Log("Got unknown event type 0x%x", e.type);
			break;
		}
	}

/*****************************************************************************\
|* The mouse button was pressed
\*****************************************************************************/
- (void) _handleMouseDown:(AZEvent *)e
	{
	NSPoint p	= [self convertPoint:e.locationInWindow fromView:nil];
	float H 	= self.bounds.size.height - _menuBM.size.height;
	float W 	= self.bounds.size.width;
	BOOL inside	= NO;

	/*************************************************************************\
	|* Pull out the impending mouse-up event otherwise another widget might
	|* get an 'up' and take an action
	\*************************************************************************/
	SDL_Event up;
	while (true)
		{
		SDL_PumpEvents();
		SDL_PollEvent(&up);
		if (up.type == SDL_EVENT_MOUSE_BUTTON_UP)
			break;
		}

	/*************************************************************************\
	|* Decide whether this was an in-the-menu click or an out-the-menu click
	\*************************************************************************/
	if ((p.x >= 0) && (p.x < W) && (p.y >= 0) && (p.y < H))
		inside = YES;

	/*************************************************************************\
	|* Clean up the event-filtering logic, and return to the caller using the
	|* provided block
	\*************************************************************************/
	[AZApp removeEventSink:_sink];
	_sink = nil;
	_call(inside);
	}

/*****************************************************************************\
|* The mouse moved
\*****************************************************************************/
- (void) _handleMouseMoved:(AZEvent *)e
	{
	NSPoint p	= [self convertPoint:e.locationInWindow fromView:nil];
	float H 	= self.bounds.size.height - _menuBM.size.height;
	float W 	= self.bounds.size.width;

	if ((p.x >= 0) && (p.x < W) && (p.y >= _menuTM.size.height) && (p.y < H))
		{
		p.y     = p.y - _menuTM.size.height + _measure.fontHeight -1;
		int sel	=  p.y / _measure.fontHeight;
		if (sel < 0)
			sel = 0;
		if (sel >= _menu.itemArray.count)
			sel = (int) _menu.itemArray.count - 1;


		if (_menu.itemArray[sel].state == AZControlStateValueOff)
			{
			int idx = 0;
			for (AZMenuItem *item in _menu.itemArray)
				{
				item.state = (idx == sel) ? AZControlStateValueOn
										  : AZControlStateValueOff;
				idx ++;
				}
			[self setNeedsDisplay:YES];
			}
		}
	}

/*****************************************************************************\
|* Configure the event-sink
\*****************************************************************************/
- (void) setupEventSink
	{
	_sink =	[[AZEventSink alloc] initWithAction:@selector(_receivedEvent:)
									  forTarget:self];
	[_sink addEventMask:AZLeftMouseUpMask];
	[_sink addEventMask:AZLeftMouseDownMask];
	[_sink addEventMask:AZMouseMovedMask];
	[AZApp addEventSink:_sink];
	}

// MARK: Private methods


/*****************************************************************************\
|* Populate the rectangles from the UI texture atlas
\*****************************************************************************/
+ (void) _fetchRects
	{
	_barSel		= [AZApp srcRectFor:@"menu-bar-window-background-selected" in:kUiMap];

	_menuTL		= [AZApp srcRectFor:@"menu-window-rounded-0" in:kUiMap];
	_menuTM		= [AZApp srcRectFor:@"menu-window-1" in:kUiMap];
	_menuTR		= [AZApp srcRectFor:@"menu-window-rounded-2" in:kUiMap];

	_menuCL		= [AZApp srcRectFor:@"menu-window-3" in:kUiMap];
	_menuCM		= [AZApp srcRectFor:@"menu-window-4" in:kUiMap];
	_menuCR		= [AZApp srcRectFor:@"menu-window-5" in:kUiMap];

	_menuBL		= [AZApp srcRectFor:@"menu-window-rounded-6" in:kUiMap];
	_menuBM		= [AZApp srcRectFor:@"menu-window-7" in:kUiMap];
	_menuBR		= [AZApp srcRectFor:@"menu-window-rounded-8" in:kUiMap];
	}


/*****************************************************************************\
|* Draw
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	NSRect bounds	= self.bounds;
	[super drawInRect:dirtyRect withPainter:painter];

	id<AZRenderer> azr	= self.window.renderer;
	[azr setBlendMode:SDL_BLENDMODE_ADD];

	NSInteger ui		= [AZApp textureFor:kUiMap];
	int y 				= 0;
	int H				= _measure.fontHeight;

	/*************************************************************************\
	|* Do we have a top-bar ?
	\*************************************************************************/
	if (_measure.flagsUsed & AZMENU_RENDER_TOP)
		{
		y = NSHeight(_menuTR);
		int stretch = bounds.size.width - NSWidth(_menuTL) - NSWidth(_menuTR);
		NSRect dstL	= NSMakeRect(0, 0, NSWidth(_menuTL), y);
		NSRect dstC = NSMakeRect(NSWidth(_menuTL), 0, stretch, y);
		NSRect dstR	= NSMakeRect(stretch + NSWidth(_menuTL), 0, NSWidth(_menuTR), y);

		[azr blitFrom:ui src:_menuTL dst:dstL];
		[azr tileFrom:ui src:_menuTM dst:dstC];
		[azr blitFrom:ui src:_menuTR dst:dstR];
		}

	/*************************************************************************\
	|* Draw each of the text entries
	\*************************************************************************/
	int index = 0;
	for (AZMenuItem *item in _menu.itemArray)
		{
		if ((index == 0) && ((_measure.flagsUsed & AZMENU_SHOW_TITLE) == 0))
			{
			index ++;
			continue;
			}

		int stretch  = bounds.size.width - NSWidth(_menuCL) - NSWidth(_menuCR);
		NSRect text	 = NSMakeRect(NSWidth(_menuCL), y, stretch, H);
		NSRect inset = NSInsetRect(text, 4, 0);

		AZColour *textColour = nil;

		if (item.state == AZControlStateValueOn)
			{
			NSRect dstC = NSMakeRect(0, y, self.bounds.size.width, H);
			[azr tileFrom:ui src:_barSel dst:dstC];
			textColour = AZColour.white;
			painter.textPainter.font = AZApp.boldControlFont;
			}
		else
			{
			NSRect dstL	= NSMakeRect(0, y, NSWidth(_menuCL), H);
			NSRect dstC	= NSMakeRect(NSWidth(_menuCL), y, stretch, H);
			NSRect dstR	= NSMakeRect(stretch + NSWidth(_menuCL), y,
									 NSWidth(_menuCR), H);

			[azr tileFrom:ui src:_menuCL dst:dstL];
			[azr tileFrom:ui src:_menuCM dst:dstC];
			[azr tileFrom:ui src:_menuCR dst:dstR];
			painter.textPainter.font = AZApp.controlFont;
			textColour = AZColour.black;
			}

		[painter setTextAlignment:AZTextAlignmentLeft];
		[azr setBlendMode:SDL_BLENDMODE_NONE];
		[painter setTextColour:textColour];
		[painter textInBox:inset text:item.title];

		y += H;
		}

	/*************************************************************************\
	|* Do we have a bottom bar ?
	\*************************************************************************/
	if (_measure.flagsUsed & AZMENU_RENDER_BOTTOM)
		{
		int h       = NSHeight(_menuBL);
		int stretch = bounds.size.width - NSWidth(_menuBL) - NSWidth(_menuBR);
		NSRect dstL	= NSMakeRect(0, y, NSWidth(_menuTL), h);
		NSRect dstC = NSMakeRect(NSWidth(_menuBL), y, stretch, h);
		NSRect dstR	= NSMakeRect(stretch + NSWidth(_menuBL), y, NSWidth(_menuBR), h);

		[azr blitFrom:ui src:_menuBL dst:dstL];
		[azr tileFrom:ui src:_menuBM dst:dstC];
		[azr blitFrom:ui src:_menuBR dst:dstR];
		}

	}

@end
