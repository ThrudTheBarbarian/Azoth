//
//  AZAppDelegate.h
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AZAppDelegate <NSObject>

@optional

- (void) applicationDidFinishLaunching:(NSNotification *)notification;

@end

NS_ASSUME_NONNULL_END
