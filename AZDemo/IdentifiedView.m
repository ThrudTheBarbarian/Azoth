//
//  IdentifiedView.m
//  AZDemo
//
//  Created by Simon Gornall on 12/12/24.
//

#import <Azoth/Azoth.h>
#import <SDL3/SDL.h>
#import <SDL3_image/SDL_image.h>

#import "IdentifiedView.h"

@interface IdentifiedView()
@property (strong, nonatomic) NSString * rsrcDir;
@property (assign, nonatomic) SDL_Surface * surface;
@end

@implementation IdentifiedView

- (instancetype) initWithFrame:(NSRect)frame andName:(NSString *)name
	{
	if (self = [super initWithFrame:frame])
		{
		self.identifier = name;
		_rsrcDir = [[NSBundle bundleForClass:[self class]] resourcePath];

		NSString *path = [_rsrcDir stringByAppendingFormat:@"/texture.png"];
		_surface = IMG_Load([path fileSystemRepresentation]);
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

	[painter pieAtX:300 y:300 radius:100 start:0 end:210
			 filled:YES colour:[AZColour purpleColour]];

	int vx[5] = {50, 100, 200, 100, 100};
	int vy[5] = {350, 350, 500, 500, 450};
	[painter texturedPolygonWith:5 x:vx y:vy texture:_surface textureDx:5 textureDy:5];

	int bx[5] = {300, 350, 400, 450, 500};
	int by[5] = {100, 150, 50, 150, 100};
	[painter bezierWithPoints:5 x:bx y:by steps:10 colour:[AZColour blackColour]];

	[painter drawAtX:250 y:100 format:@"Aiiiiiie! says %@", @"Simon"];
		[painter drawAtX:250 y:130 hAlign:AZFONT_HALIGN_RIGHT
			format:@"The quick brown fox\njumped over the\nlazy dog"];
	}

@end
