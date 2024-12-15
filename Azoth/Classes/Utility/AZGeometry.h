//
//  AZGeometry.h
//  Azoth
//
//  Created by Simon Gornall on 12/12/24.
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


#endif /* AZGeometry_h */
