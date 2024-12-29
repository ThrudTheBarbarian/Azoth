//
//  AZImageCache.m
//  Azoth
//
//  Created by Simon Gornall on 12/28/24.
//

#import "AZImageCache.h"
#import "AZRenderer.h"

@implementation AZImageCache
/*****************************************************************************\
|* Initialisation: Create with a width and height for a given size of image
\*****************************************************************************/
- (instancetype) initWithWidth:(int)width height:(int)height size:(int)size
	{
	if (self = [super init])
		{
		_width 			= width;
		_height 		= height;
		_size 			= size;
		_remainingSlots	= (width / size) * (height / size);
		_nextX			= 0;
		_nextY			= 0;

		AZRenderer *azr	= AZRenderer.renderer;
		NSSize tSize	= NSMakeSize(size, size);
		_textureId		= [azr createTextureOfSize:tSize];

		if (_textureId < 0)
			self = nil;
		}
	return self;
	}

/*****************************************************************************\
|* Initialisation: .. conveniently
\*****************************************************************************/
+ (AZImageCache *) cacheWithWidth:(int)width height:(int)height size:(int)size
	{
	return [[AZImageCache alloc] initWithWidth:width height:height size:size];
	}

/*****************************************************************************\
|* We just added an image, update the state
\*****************************************************************************/
- (void) bumpToNextSlot
	{
	_nextX += _size;
	if (_nextX + _size > _width)
		{
		_nextY += _size;
		_nextX = 0;
		}
	_remainingSlots --;
	}



@end
