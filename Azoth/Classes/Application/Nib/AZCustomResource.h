//
//  AZCustomResource.h
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZCustomResource : NSObject


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Name of the class
@property(copy, nonatomic) NSString *							className;

// Name of the resource
@property(copy, nonatomic) NSString *							resourceName;

@end

NS_ASSUME_NONNULL_END
