//
//  AZMenuOverlayView.m
//  Azoth
//
//  Created by Simon Gornall on 12/18/24.
//

#import "AZColour.h"
#import "AZMenuItem.h"
#import "AZMenuView.h"
#import "AZMenuOverlayView.h"

@interface AZMenuOverlayView()
@property(strong, nonatomic) AZMenuView *							menuView;
@end

@implementation AZMenuOverlayView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		self.bgColour = [AZColour clearColour];
		}
	return self;
	}

/*****************************************************************************\
|* Drawing
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];
	}

/*****************************************************************************\
|* Are we opaque, by default NO, but just to be sure
\*****************************************************************************/
- (BOOL) isOpaque
	{
	return NO;
	}

// MARK - Event handling

/*****************************************************************************\
|* Grab the mouse, always
\*****************************************************************************/
- (BOOL) mouseDown:(struct SDL_MouseButtonEvent *)e
	{
	return YES;
	}

/*****************************************************************************\
|* Grab the mouse, always
\*****************************************************************************/
- (BOOL) mouseUp:(struct SDL_MouseButtonEvent *)e
	{
	return YES;
	}

/*****************************************************************************\
|* Mouse-moved event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseMoved:(struct SDL_MouseMotionEvent *)e
	{
	return YES;
	}

/*****************************************************************************\
|* Mouse-dragged event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDragged:(struct SDL_MouseMotionEvent *)e
	{
	return YES;
	}

/*****************************************************************************\
|* Mouse-wheel event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseWheeled:(struct SDL_MouseWheelEvent *)e
	{
	return YES;
	}

/*****************************************************************************\
|* Run a popup menu
\*****************************************************************************/
- (BOOL) runMenuFor:(AZMenuItem *)item at:(NSPoint)p
	{
	BOOL ok = NO;

	AZMenu *menu 	= item.menu;
	NSInteger index	= [menu indexOfItem:item];
	NSInteger count = menu.numberOfItems;
	float fraction	= (float)index / (float)count;

	int flags		= AZMENU_RENDER_TOP|AZMENU_RENDER_BOTTOM;
	AZMenuSize size	= [AZMenuView measureMenu:menu withFlags:flags];
	_menuView		= [[AZMenuView alloc] initWithMenu:menu andSize:size];

	NSRect frame	= _menuView.frame;
	frame.origin.y 	= p.y - fraction * frame.size.height;
	frame.origin.x	= p.x;
	_menuView.frame = frame;

	[self addSubview:_menuView];
	return ok;
	}

@end
