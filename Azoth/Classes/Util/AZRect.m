//
//  AZRect.m
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import "AZRect.h"

@implementation AZRect

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithX:(int)x y:(int)y w:(int)w h:(int)h
	{
	if (self = [super init])
		{
		_x = x;
		_y = y;
		_w = w;
		_h = h;
		}
	return self;
	}

+ (AZRect *) rectWithX:(int)x y:(int)y w:(int)w h:(int)h
	{
	return [[AZRect alloc] initWithX:x y:y w:w h:h];
	}

@end
