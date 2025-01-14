//
//  AZRenderer3d.h
//  Azoth
//
//  Created by Simon Gornall on 1/13/25.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZRenderer.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZRenderer3d : NSObject <AZRenderer>

/*****************************************************************************\
|* Return the 3D renderer
\*****************************************************************************/
+ (AZRenderer3d *) renderer;

@end

NS_ASSUME_NONNULL_END
