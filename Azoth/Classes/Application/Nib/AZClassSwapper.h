//
//  AZClassSwapper.h
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZClassSwapper : NSObject

/*****************************************************************************\
|* Change the namespace
\*****************************************************************************/
+ (NSString *) toAZ:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
