//
//  AZRenderer2d.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/17/24.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZRenderer.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class AZColour;

struct SDL_Surface;
struct SDL_Renderer;
struct SDL_FPoint;

@interface AZRenderer2d : NSObject <AZRenderer>

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init NS_UNAVAILABLE;
+ (AZRenderer2d *) renderer;

@end

NS_ASSUME_NONNULL_END
