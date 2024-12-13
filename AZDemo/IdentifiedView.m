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
		r = rand() % 255;
		g = rand() % 255;
		b = rand() % 255;
		a = 255;
		}
	return self;
	}


/*****************************************************************************\
|* Draw rect
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect
	{
	SDL_Renderer *renderer = SDL_GetRenderer(self.window);

	SDL_SetRenderDrawColor(renderer, r, g, b, a);
	SDL_FRect bounds = SDLFRectFromNSRect(dirtyRect);
	SDL_RenderFillRect(renderer, &bounds);
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

@end
