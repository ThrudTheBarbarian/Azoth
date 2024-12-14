//
//  IdentifiedView.m
//  AZDemo
//
//  Created by Simon Gornall on 12/12/24.
//

#import <Azoth/Azoth.h>
#import <SDL3/SDL.h>

#import "IdentifiedView.h"

@implementation IdentifiedView

- (instancetype) initWithFrame:(NSRect)frame andName:(NSString *)name
	{
	if (self = [super initWithFrame:frame])
		{
		self.identifier = name;
		}
	return self;
	}

/*****************************************************************************\
|* Mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDown:(struct SDL_MouseButtonEvent *)e
	{
	NSPoint p = NSMakePoint(e->x, e->y);
	p 		  = [self convertPoint:p fromView:nil];

	NSLog(@"Down in %@ at (%d,%d) (from %d,%d)",
		self.identifier, (int)p.x, (int)p.y, (int)e->x, (int)e->y);
	return YES;
	}


/*****************************************************************************\
|* Mouse-button-up event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseUp:(struct SDL_MouseButtonEvent *)e
	{
	NSPoint p = NSMakePoint(e->x, e->y);
	p 		  = [self convertPoint:p fromView:nil];

	NSLog(@"Up in %@ at (%d,%d) (from %d,%d)",
		self.identifier, (int)p.x, (int)p.y, (int)e->x, (int)e->y);
	[[AZView contentViewForWindow:self.window] setNeedsDisplay:YES];
	return YES;
	}


/*****************************************************************************\
|* Mouse-dragged event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDragged:(struct SDL_MouseMotionEvent *)e
	{
	NSPoint p = NSMakePoint(e->x, e->y);
	p 		  = [self convertPoint:p fromView:nil];

	NSLog(@"Dragged in %@ at (%d,%d) (from %d,%d)",
		self.identifier, (int)p.x, (int)p.y, (int)e->x, (int)e->y);
	return YES;
	}

/*****************************************************************************\
|* What to override in subclasses to get a view to draw. This renders into the
|* local texture, so is at (0,0) wrt to that texture. Pixel positioning ought
|* to be perfectly aligned. By default the view is cleared to its background
|* colour
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	[painter rectangleWithRect:NSInsetRect(dirtyRect, 10, 10)
						radius:20 filled:YES
						colour:[AZColour whiteColour]];

	[painter setUsingAntiAliasing:YES];
//	[painter lineAtX:20 y:20 toX:90 y:70 withR:100 g:200 b:50 a:200];
//	[painter ellipseWithRect:NSMakeRect(200, 200, 300, 100)
//			 filled:YES colour:[AZColour purpleColour]];
//
//	int vx[5] = {50, 100, 200, 100, 100};
//	int vy[5] = {350, 350, 500, 500, 450};
//	[painter polygonWith:5 x:vx y:vy filled:YES withR:240 g:20 b:100 a:255];

	[painter pieAtX:300 y:300 radius:100 start:0 end:180
			 filled:YES colour:[AZColour purpleColour]];

	}

@end
