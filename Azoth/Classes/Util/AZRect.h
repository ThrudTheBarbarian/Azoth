//
//  AZRect.h
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZRect : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithX:(int)x y:(int)y w:(int)w h:(int)h;
+ (AZRect *) rectWithX:(int)x y:(int)y w:(int)w h:(int)h;


/*****************************************************************************\
|* The standard x,y,w,h of a rectangle
\*****************************************************************************/
@property(assign, nonatomic) int x;
@property(assign, nonatomic) int y;
@property(assign, nonatomic) int w;
@property(assign, nonatomic) int h;
@end

NS_ASSUME_NONNULL_END
