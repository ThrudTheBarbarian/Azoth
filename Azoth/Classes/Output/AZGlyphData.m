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
- (instancetype) init
	{
	if (self = [super init])
		{
		_rect = NSZeroRect;
		_cacheId = 0;
		}
	return self;
	}

- (instancetype) initWithRect:(NSRect)rect andCacheId:(int)cacheId
	{
	if (self = [super init])
		{
		_rect 		= rect;
		_cacheId 	= cacheId;
		}
	return self;
	}

+ (AZGlyphData *) dataWithRect:(NSRect)rect andCacheId:(int)cacheId
	{
	return [[AZGlyphData alloc] initWithRect:rect andCacheId:cacheId];
	}


- (nonnull id)copyWithZone:(nullable NSZone *)zone
	{
	return [AZGlyphData dataWithRect:_rect andCacheId:_cacheId];
	}

@end
