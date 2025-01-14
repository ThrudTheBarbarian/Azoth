//
//  AZGlyphData.h
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZGlyphData : NSObject <NSCopying>
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithRect:(NSRect)rect andCacheId:(int)cacheId;
+ (AZGlyphData *) dataWithRect:(NSRect)rect andCacheId:(int)cacheId;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The rectangle to render a glyph within
@property(assign, nonatomic) NSRect			 				rect;

// The id within the cache for this glyph
@property(assign, nonatomic) int							cacheId;
@end

NS_ASSUME_NONNULL_END
