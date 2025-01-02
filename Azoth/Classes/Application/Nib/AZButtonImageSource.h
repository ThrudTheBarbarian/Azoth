//
//  AZButtonImageSource.h
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZImage;

@interface AZButtonImageSource : NSObject

- (AZImage *) normalImage;
- (AZImage *) alternateImage;

@end

NS_ASSUME_NONNULL_END
