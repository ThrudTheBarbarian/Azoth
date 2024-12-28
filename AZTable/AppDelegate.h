//
//  AppDelegate.h
//  AZTable
//
//  Created by Simon Gornall on 12/27/24.
//

#import <Azoth/Azoth.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : NSObject <AZAppDelegate,
								   AZTableViewDelegate,
								   AZTableViewDataSource>

@end

NS_ASSUME_NONNULL_END
