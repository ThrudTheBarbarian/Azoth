//
//  AZImageCache.m
//  Azoth
//
//  Created by Simon Gornall on 12/28/24.
//

#import <SDL3/SDL.h>

#import "AZImageCache.h"
#import "AZRenderer.h"

@interface AZImageCache()

// The number of 'slots' left in the cache
@property(strong, nonatomic) NSMutableSet *						slots;

// The width of the cache texture
@property(assign, nonatomic) NSInteger							width;

// The height of the cache texture
@property(assign, nonatomic) NSInteger							height;

// The width/height of the images cached within
@property(assign, nonatomic) NSInteger							size;
@end

@implementation AZImageCache
/*****************************************************************************\
|* Initialisation: Create with a width and height for a given size of image
\*****************************************************************************/
- (instancetype) initWithWidth:(int)width height:(int)height size:(int)size
	{
	if (self = [super init])
		{
		_slots			= [NSMutableSet new];
		_width 			= width;
		_height 		= height;
		_size 			= size;

		for (int i=0; i<height; i+=size)
			for (int j=0; j<width; j+=size)
				{
				NSRect r = NSMakeRect(j, i, size, size);
				[_slots addObject:NSStringFromRect(r)];
				}

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
|* Fetch a slot to use from the cache. If none available, returns NSZeroRect
\*****************************************************************************/
- (NSRect) acquire
	{
	if (_slots.count == 0)
		return NSZeroRect;

	NSString *entry = [_slots anyObject];
	NSRect r = NSRectFromString(entry);
	[_slots removeObject:entry];
	return r;
	}

/*****************************************************************************\
|* Put a slot back into use
\*****************************************************************************/
- (void) release:(NSRect)rect
	{
	NSString *entry = NSStringFromRect(rect);

	if ((rect.size.width != _size) || (rect.size.height != _size))
		SDL_Log("Attempt to return a non %dx%d slot to image-cache %p",
				(int)_size, (int)_size, self);
	else if (((int)(rect.origin.x) % _size) != 0)
		SDL_Log("X-offset of %s is not %d-aligned in image-cache %p",
				entry.UTF8String, (int)_size, self);
	else if (((int)(rect.origin.y) % _size) != 0)
		SDL_Log("Y-offset of %s is not %d-aligned in image-cache %p",
				entry.UTF8String, (int)_size, self);
	else
		[_slots addObject:entry];
	}


@end
