//
//  AZGlyphData.m
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//

#import <SDL3/SDL.h>

#import "AZGlyphData.h"

@implementation AZGlyphData

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithRect:(struct SDL_Rect)rect andCacheId:(int)cacheId
	{
	if (self = [super init])
		{
		_rect 		= rect;
		_cacheId 	= cacheId;
		}
	return self;
	}

+ (AZGlyphData *) dataWithRect:(struct SDL_Rect)rect andCacheId:(int)cacheId
	{
	return [[AZGlyphData alloc] initWithRect:rect andCacheId:cacheId];
	}


@end
