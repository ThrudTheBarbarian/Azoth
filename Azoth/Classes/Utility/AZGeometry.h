//
//  AZGeometry.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/12/24.
//

#ifndef AZGeometry_h
#define AZGeometry_h

#import <Foundation/Foundation.h>

#include <stdio.h>

struct SDL_FRect;
struct SDL_Rect;

/*****************************************************************************\
|* Convert an NSRect to an SDL_FRect
\*****************************************************************************/
struct SDL_FRect SDLFRectFromNSRect(NSRect r);
struct SDL_Rect  SDLRectFromNSRect(NSRect r);


/*****************************************************************************\
|* Create an NSRect from 2 points
\*****************************************************************************/
inline static NSRect NSRectFromTwoPoints(NSPoint a, NSPoint b)
	{
	NSRect  r;
	
	r.size.width = ABS( b.x - a.x );
	r.size.height = ABS( b.y - a.y );
	
	r.origin.x = MIN( a.x, b.x );
	r.origin.y = MIN( a.y, b.y );
  
	return r;
	}

#endif /* AZGeometry_h */
