//
//  AZGlyphData.h
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct SDL_Rect;


@interface AZGlyphData : NSObject
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithRect:(struct SDL_Rect)rect andCacheId:(int)cacheId;
+ (AZGlyphData *) dataWithRect:(struct SDL_Rect)rect andCacheId:(int)cacheId;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The rectangle to render a glyph within
@property(assign, nonatomic) struct SDL_Rect 				rect;

// The id within the cache for this glyph
@property(assign, nonatomic) int							cacheId;
@end

NS_ASSUME_NONNULL_END
