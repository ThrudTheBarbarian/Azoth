//
//  AZCustomObject.h
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZCustomObject : NSObject

/*****************************************************************************\
|* Create the instance
\*****************************************************************************/
- (id) createCustomInstance;



/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Name of the custom class
@property(copy, nonatomic) NSString *							className;
@end

NS_ASSUME_NONNULL_END
