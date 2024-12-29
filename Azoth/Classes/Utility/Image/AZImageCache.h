//
//  AZImageCache.h
//  Azoth
//
//  Created by Simon Gornall on 12/28/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZImageCache : NSObject
/*****************************************************************************\
|* Initialisation: Create with a width and height for a given size of image
\*****************************************************************************/
- (instancetype) initWithWidth:(int)width height:(int)height size:(int)size;

/*****************************************************************************\
|* Initialisation: .. conveniently
\*****************************************************************************/
+ (AZImageCache *) cacheWithWidth:(int)width height:(int)height size:(int)size;

/*****************************************************************************\
|* We just added an image, update the state
\*****************************************************************************/
- (void) bumpToNextSlot;

// The texture we're using for the cache
@property(assign, nonatomic) NSInteger							textureId;

// The number of 'slots' left in the cache
@property(assign, nonatomic) NSInteger							remainingSlots;

// The width of the cache texture
@property(assign, nonatomic) NSInteger							width;

// The height of the cache texture
@property(assign, nonatomic) NSInteger							height;

// The width/height of the images cached within
@property(assign, nonatomic) NSInteger							size;

// The next x positiom of the image to cache
@property(assign, nonatomic) int								nextX;

// The next y positiom of the image to cache
@property(assign, nonatomic) int								nextY;
@end

NS_ASSUME_NONNULL_END
