//
//  AZGeometry.m
//  Azoth
//
//  Created by Simon Gornall on 12/12/24.
//

#import <SDL3/SDL.h>

#include "AZGeometry.h"

/*****************************************************************************\
|* Convert an NSRect to an SDL_FRect
\*****************************************************************************/
SDL_FRect SDLFRectFromNSRect(NSRect r)
	{
	SDL_FRect sdl;

	sdl.x = r.origin.x;
	sdl.y = r.origin.y;
	sdl.w = r.size.width;
	sdl.h = r.size.height;

	return sdl;
	}

/*****************************************************************************\
|* Convert an NSRect to an SDL_Rect
\*****************************************************************************/
SDL_Rect SDLRectFromNSRect(NSRect r)
	{
	SDL_Rect sdl;

	sdl.x = (int) r.origin.x;
	sdl.y = (int) r.origin.y;
	sdl.w = (int) r.size.width;
	sdl.h = (int) r.size.height;

	return sdl;
	}


