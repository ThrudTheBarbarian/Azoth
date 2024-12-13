//
//  AZPainter.m
//  Azoth
//
//  Created by Simon Gornall on 12/12/24.
//

#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZGeometry.h"
#import "AZPainter.h"
#import "AZView.h"

@implementation AZPainter

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithView:(AZView *)view
	{
	if (self = [super init])
		{
		_view = view;
		}
	return self;
	}

+ (AZPainter *) painterForView:(AZView *)view
	{
	return [[AZPainter alloc] initWithView:view];
	}


/*****************************************************************************\
|* Set up the context and draw
\*****************************************************************************/
- (void) execute
	{
	SDL_Renderer *renderer 	= [AZApp sharedInstance].renderer;
	SDL_Rect bounds 		= SDLRectFromNSRect(_view.dirty);

	SDL_SetRenderTarget(renderer, _view.bg);
	SDL_SetRenderClipRect(renderer, &bounds);

	[_view drawInRect:_view.dirty withPainter:self];
	_view.dirty = NSZeroRect;

	SDL_SetRenderClipRect(renderer, NULL);
	SDL_SetRenderTarget(renderer, NULL);
	}
@end
