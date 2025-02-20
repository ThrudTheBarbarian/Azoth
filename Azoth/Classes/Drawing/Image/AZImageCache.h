//
//  AZImageCache.h
//  Azoth
//
//  Created by Simon Gornall on 12/28/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AZRenderer;

@interface AZImageCache : NSObject
/*****************************************************************************\
|* Initialisation: Create with a width and height for a given size of image
\*****************************************************************************/
- (instancetype) initWithWidth:(int)width
						height:(int)height
						  size:(int)size
						   for:(id<AZRenderer>)azr;

/*****************************************************************************\
|* Initialisation: .. conveniently
\*****************************************************************************/
+ (AZImageCache *) cacheWithWidth:(int)width
						   height:(int)height
						     size:(int)size
						      for:(id<AZRenderer>)azr;

/*****************************************************************************\
|* Fetch a slot to use from the cache. If none available, returns NSZeroRect
\*****************************************************************************/
- (NSRect) acquire;

/*****************************************************************************\
|* Put a slot back into use
\*****************************************************************************/
- (void) release:(NSRect)rect;

// The texture we're using for the cache
@property(assign, nonatomic) NSInteger							textureId;
@end

NS_ASSUME_NONNULL_END
