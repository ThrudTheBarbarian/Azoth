//
//  AZMenuOverlayView.m
//  Azoth
//
//  Created by Simon Gornall on 12/18/24.
//

#import "AZColour.h"
#import "AZMenuOverlayView.h"

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
	
@end
